// KnowledgePointRepository.swift - 知識點數據存儲層

import Foundation

/// 知識點數據存儲協議
protocol KnowledgePointRepositoryProtocol {
    func fetchKnowledgePoints() async throws -> [KnowledgePoint]
    func fetchArchivedKnowledgePoints() async throws -> [KnowledgePoint]
    func deleteKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws
    func archiveKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws
    func restoreKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws
    func updateMasteryLevel(compositeId: CompositeKnowledgePointID?, legacyId: Int?, level: Double) async throws
    
    // 向後兼容的便利方法
    func deleteKnowledgePoint(_ id: Int) async throws
    func archiveKnowledgePoint(_ id: Int) async throws
    func restoreKnowledgePoint(_ id: Int) async throws
    func updateMasteryLevel(pointId: Int, level: Double) async throws
}

/// 知識點數據存儲實現類
@MainActor
class KnowledgePointRepository: KnowledgePointRepositoryProtocol, ObservableObject {
    
    static let shared = KnowledgePointRepository()
    
    // MARK: - Cache Properties - 已移除記憶體快取
    // 注意：已完全移除記憶體快取機制，直接從 API 或本地儲存讀取
    
    // MARK: - Dependencies (支援依賴注入)
    private let apiService: UnifiedAPIServiceProtocol
    private let cacheManager: CacheManagerProtocol
    
    // MARK: - Initialization
    private init(
        apiService: UnifiedAPIServiceProtocol? = nil,
        cacheManager: CacheManagerProtocol? = nil
    ) {
        self.apiService = apiService ?? UnifiedAPIService.shared
        self.cacheManager = cacheManager ?? CacheManager.shared
    }
    
    /// 創建具有自訂依賴的實例（用於測試）
    static func create(
        apiService: UnifiedAPIServiceProtocol,
        cacheManager: CacheManagerProtocol
    ) -> KnowledgePointRepository {
        return KnowledgePointRepository(apiService: apiService, cacheManager: cacheManager)
    }
    
    // MARK: - Public Methods
    
    func fetchKnowledgePoints() async throws -> [KnowledgePoint] {
        // 直接從 API 獲取數據，不使用記憶體快取
        do {
            let response = try await apiService.getDashboard()
            let points = response.knowledgePoints
            
            // 同時保存到本地存儲（作為離線備份）
            await cacheManager.saveKnowledgePoints(points)
            
            return points
            
        } catch {
            // API 失敗時嘗試從本地存儲讀取
            if let localPoints = await cacheManager.loadKnowledgePoints() {
                return localPoints
            }
            
            throw error
        }
    }
    
    func fetchArchivedKnowledgePoints() async throws -> [KnowledgePoint] {
        // 直接從 API 獲取數據，不使用記憶體快取
        do {
            let points = try await apiService.fetchArchivedKnowledgePoints()
            
            // 同時保存到本地存儲（作為離線備份）
            await cacheManager.saveArchivedKnowledgePoints(points)
            
            return points
            
        } catch {
            // API 失敗時嘗試從本地存儲讀取
            if let localPoints = await cacheManager.loadArchivedKnowledgePoints() {
                return localPoints
            }
            
            throw error
        }
    }
    
    func deleteKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws {
        // 先從本地移除（樂觀更新）
        if var localPoints = await cacheManager.loadKnowledgePoints() {
            if let composite = compositeId {
                localPoints.removeAll { 
                    $0.compositeId?.userId == composite.userId && 
                    $0.compositeId?.sequenceId == composite.sequenceId 
                }
            } else if let legacy = legacyId {
                localPoints.removeAll { $0.numericId == legacy }
            }
            await cacheManager.saveKnowledgePoints(localPoints)
        }
        
        do {
            try await apiService.deleteKnowledgePoint(compositeId: compositeId, legacyId: legacyId)
            
            // API成功後重新獲取最新數據確保同步
            do {
                let response = try await apiService.getDashboard()
                await cacheManager.saveKnowledgePoints(response.knowledgePoints)
            } catch {
                Logger.warning("刪除後重新整理數據失敗: \(error)", category: .database)
                // 不拋出錯誤，因為主要操作（刪除）已經成功
            }
            
        } catch {
            // API失敗時恢復本地數據
            do {
                let response = try await apiService.getDashboard()
                await cacheManager.saveKnowledgePoints(response.knowledgePoints)
            } catch {
                Logger.error("刪除失敗且無法恢復本地數據: \(error)", category: .database)
            }
            throw error
        }
    }
    
    // 向後兼容的便利方法
    func deleteKnowledgePoint(_ id: Int) async throws {
        try await deleteKnowledgePoint(compositeId: nil, legacyId: id)
    }
    
    func archiveKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws {
        // 先在本地進行歸檔操作（樂觀更新）
        var wasMovedLocally = false
        if var localPoints = await cacheManager.loadKnowledgePoints(),
           var archivedPoints = await cacheManager.loadArchivedKnowledgePoints() {
            
            let index: Int?
            if let composite = compositeId {
                index = localPoints.firstIndex(where: { 
                    $0.compositeId?.userId == composite.userId && 
                    $0.compositeId?.sequenceId == composite.sequenceId 
                })
            } else if let legacy = legacyId {
                index = localPoints.firstIndex(where: { $0.numericId == legacy })
            } else {
                index = nil
            }
            
            if let index = index {
                let point = localPoints.remove(at: index)
                archivedPoints.append(point)
                await cacheManager.saveKnowledgePoints(localPoints)
                await cacheManager.saveArchivedKnowledgePoints(archivedPoints)
                wasMovedLocally = true
            }
        }
        
        do {
            try await apiService.archiveKnowledgePoint(compositeId: compositeId, legacyId: legacyId)
            
            // API成功後重新獲取最新數據確保同步
            do {
                let response = try await apiService.getDashboard()
                await cacheManager.saveKnowledgePoints(response.knowledgePoints)
                
                let archivedPoints = try await apiService.fetchArchivedKnowledgePoints()
                await cacheManager.saveArchivedKnowledgePoints(archivedPoints)
            } catch {
                Logger.warning("歸檔後重新整理數據失敗: \(error)", category: .database)
                // 不拋出錯誤，因為主要操作（歸檔）已經成功
            }
            
        } catch {
            // API失敗時恢復本地數據
            if wasMovedLocally {
                do {
                    let response = try await apiService.getDashboard()
                    await cacheManager.saveKnowledgePoints(response.knowledgePoints)
                    
                    let archivedPoints = try await apiService.fetchArchivedKnowledgePoints()
                    await cacheManager.saveArchivedKnowledgePoints(archivedPoints)
                } catch {
                    Logger.error("歸檔失敗且無法恢復本地數據: \(error)", category: .database)
                }
            }
            throw error
        }
    }
    
    // 向後兼容的便利方法
    func archiveKnowledgePoint(_ id: Int) async throws {
        try await archiveKnowledgePoint(compositeId: nil, legacyId: id)
    }
    
    func restoreKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws {
        // 先在本地進行還原操作（樂觀更新）
        var wasMovedLocally = false
        if var localPoints = await cacheManager.loadKnowledgePoints(),
           var archivedPoints = await cacheManager.loadArchivedKnowledgePoints() {
            
            let index: Int?
            if let composite = compositeId {
                index = archivedPoints.firstIndex(where: { 
                    $0.compositeId?.userId == composite.userId && 
                    $0.compositeId?.sequenceId == composite.sequenceId 
                })
            } else if let legacy = legacyId {
                index = archivedPoints.firstIndex(where: { $0.numericId == legacy })
            } else {
                index = nil
            }
            
            if let index = index {
                let point = archivedPoints.remove(at: index)
                localPoints.append(point)
                await cacheManager.saveKnowledgePoints(localPoints)
                await cacheManager.saveArchivedKnowledgePoints(archivedPoints)
                wasMovedLocally = true
            }
        }
        
        do {
            try await apiService.unarchiveKnowledgePoint(compositeId: compositeId, legacyId: legacyId)
            
            // API成功後重新獲取最新數據確保同步
            do {
                let response = try await apiService.getDashboard()
                await cacheManager.saveKnowledgePoints(response.knowledgePoints)
                
                let archivedPoints = try await apiService.fetchArchivedKnowledgePoints()
                await cacheManager.saveArchivedKnowledgePoints(archivedPoints)
            } catch {
                Logger.warning("還原後重新整理數據失敗: \(error)", category: .database)
                // 不拋出錯誤，因為主要操作（還原）已經成功
            }
            
        } catch {
            // API失敗時恢復本地數據
            if wasMovedLocally {
                do {
                    let response = try await apiService.getDashboard()
                    await cacheManager.saveKnowledgePoints(response.knowledgePoints)
                    
                    let archivedPoints = try await apiService.fetchArchivedKnowledgePoints()
                    await cacheManager.saveArchivedKnowledgePoints(archivedPoints)
                } catch {
                    Logger.error("還原失敗且無法恢復本地數據: \(error)", category: .database)
                }
            }
            throw error
        }
    }
    
    // 向後兼容的便利方法
    func restoreKnowledgePoint(_ id: Int) async throws {
        try await restoreKnowledgePoint(compositeId: nil, legacyId: id)
    }
    
    func updateMasteryLevel(compositeId: CompositeKnowledgePointID?, legacyId: Int?, level: Double) async throws {
        let updateRequest = KnowledgePointUpdateRequest.masteryLevelUpdate(level)
        try await apiService.updateKnowledgePoint(compositeId: compositeId, legacyId: legacyId, updates: updateRequest)
        
        // 重新獲取最新數據以更新本地存儲
        do {
            let response = try await apiService.getDashboard()
            await cacheManager.saveKnowledgePoints(response.knowledgePoints)
        } catch {
            Logger.error("重新整理知識點失敗: \(error)", category: .database)
        }
    }
    
    // 向後兼容的便利方法
    func updateMasteryLevel(pointId: Int, level: Double) async throws {
        try await updateMasteryLevel(compositeId: nil, legacyId: pointId, level: level)
    }
    
    // MARK: - Cache Management
    
    /// 清除本地存儲
    func clearCache() {
        // 直接呼叫 CacheManager 的清除方法
        cacheManager.clearAllCache()
    }
    
    /// 強制刷新（直接從 API 獲取最新數據）
    func forceRefresh() async throws -> [KnowledgePoint] {
        return try await fetchKnowledgePoints()
    }
}

// MARK: - 快取管理協議
@MainActor
protocol CacheManagerProtocol {
    func saveKnowledgePoints(_ points: [KnowledgePoint]) async
    func loadKnowledgePoints() async -> [KnowledgePoint]?
    func saveArchivedKnowledgePoints(_ points: [KnowledgePoint]) async
    func loadArchivedKnowledgePoints() async -> [KnowledgePoint]?
    func clearAllCache()
}

// MARK: - 本地存儲管理器
@MainActor
class CacheManager: CacheManagerProtocol {
    static let shared = CacheManager()
    
    private let userDefaults = UserDefaults.standard
    private let authManager = AuthenticationManager.shared
    
    // 生成包含用戶 ID 的快取 key
    private var knowledgePointsKey: String {
        if let userId = authManager.currentUser?.id {
            return "cached_knowledge_points_user_\(userId)"
        }
        return "cached_knowledge_points_guest"
    }
    
    private var archivedPointsKey: String {
        if let userId = authManager.currentUser?.id {
            return "cached_archived_points_user_\(userId)"
        }
        return "cached_archived_points_guest"
    }
    
    private init() {}
    
    func saveKnowledgePoints(_ points: [KnowledgePoint]) async {
        do {
            let data = try JSONEncoder().encode(points)
            userDefaults.set(data, forKey: knowledgePointsKey)
        } catch {
            Logger.error("保存知識點到本地失敗: \(error)", category: .database)
        }
    }
    
    func loadKnowledgePoints() async -> [KnowledgePoint]? {
        guard let data = userDefaults.data(forKey: knowledgePointsKey) else { return nil }
        
        do {
            return try JSONDecoder().decode([KnowledgePoint].self, from: data)
        } catch {
            Logger.error("從本地載入知識點失敗: \(error)", category: .database)
            return nil
        }
    }
    
    func saveArchivedKnowledgePoints(_ points: [KnowledgePoint]) async {
        do {
            let data = try JSONEncoder().encode(points)
            userDefaults.set(data, forKey: archivedPointsKey)
        } catch {
            Logger.error("保存歸檔知識點到本地失敗: \(error)", category: .database)
        }
    }
    
    func loadArchivedKnowledgePoints() async -> [KnowledgePoint]? {
        guard let data = userDefaults.data(forKey: archivedPointsKey) else { return nil }
        
        do {
            return try JSONDecoder().decode([KnowledgePoint].self, from: data)
        } catch {
            Logger.error("從本地載入歸檔知識點失敗: \(error)", category: .database)
            return nil
        }
    }
    
    func clearAllCache() {
        // 清除當前用戶的快取
        userDefaults.removeObject(forKey: knowledgePointsKey)
        userDefaults.removeObject(forKey: archivedPointsKey)
        
        // 清除所有用戶的快取（選擇性）
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix("cached_knowledge_points_") || key.hasPrefix("cached_archived_points_") {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
}