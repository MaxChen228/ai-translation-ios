// KnowledgePointRepository.swift - 知識點數據存儲層

import Foundation

/// 知識點數據存儲協議
protocol KnowledgePointRepositoryProtocol {
    func fetchKnowledgePoints() async throws -> [KnowledgePoint]
    func fetchArchivedKnowledgePoints() async throws -> [KnowledgePoint]
    func deleteKnowledgePoint(_ id: Int) async throws
    func archiveKnowledgePoint(_ id: Int) async throws
    func restoreKnowledgePoint(_ id: Int) async throws
    func updateMasteryLevel(pointId: Int, level: Double) async throws
}

/// 知識點數據存儲實現類
@MainActor
class KnowledgePointRepository: KnowledgePointRepositoryProtocol, ObservableObject {
    
    static let shared = KnowledgePointRepository()
    
    // MARK: - Cache Properties
    private var cachedKnowledgePoints: [KnowledgePoint] = []
    private var cachedArchivedPoints: [KnowledgePoint] = []
    private var lastCacheUpdate: Date?
    private let cacheExpirationInterval: TimeInterval = 300 // 5分鐘
    
    // MARK: - Dependencies (支援依賴注入)
    private let apiService: UnifiedAPIServiceProtocol
    private let cacheManager: CacheManagerProtocol
    
    // MARK: - Initialization
    private init(
        apiService: UnifiedAPIServiceProtocol = UnifiedAPIService.shared,
        cacheManager: CacheManagerProtocol = CacheManager.shared
    ) {
        self.apiService = apiService
        self.cacheManager = cacheManager
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
        // 檢查快取是否有效
        if let cachedData = getCachedKnowledgePoints() {
            return cachedData
        }
        
        // 從 API 獲取數據
        do {
            let response = try await apiService.getDashboard()
            let points = response.knowledgePoints
            
            // 更新快取
            updateCache(knowledgePoints: points)
            
            // 同時保存到本地存儲
            await cacheManager.saveKnowledgePoints(points)
            
            return points
            
        } catch {
            // API 失敗時嘗試從本地存儲讀取
            if let localPoints = await cacheManager.loadKnowledgePoints() {
                updateCache(knowledgePoints: localPoints)
                return localPoints
            }
            
            throw error
        }
    }
    
    func fetchArchivedKnowledgePoints() async throws -> [KnowledgePoint] {
        // 檢查快取是否有效
        if let cachedData = getCachedArchivedPoints() {
            return cachedData
        }
        
        // 從 API 獲取數據
        do {
            let points = try await apiService.fetchArchivedKnowledgePoints()
            
            // 更新快取
            updateCache(archivedPoints: points)
            
            // 同時保存到本地存儲
            await cacheManager.saveArchivedKnowledgePoints(points)
            
            return points
            
        } catch {
            // API 失敗時嘗試從本地存儲讀取
            if let localPoints = await cacheManager.loadArchivedKnowledgePoints() {
                updateCache(archivedPoints: localPoints)
                return localPoints
            }
            
            throw error
        }
    }
    
    func deleteKnowledgePoint(_ id: Int) async throws {
        try await apiService.deleteKnowledgePoint(id: id)
        
        // 更新快取
        cachedKnowledgePoints.removeAll { $0.id == id }
        
        // 更新本地存儲
        await cacheManager.saveKnowledgePoints(cachedKnowledgePoints)
    }
    
    func archiveKnowledgePoint(_ id: Int) async throws {
        try await apiService.archiveKnowledgePoint(id: id)
        
        // 更新快取：從活躍列表移動到歸檔列表
        if let index = cachedKnowledgePoints.firstIndex(where: { $0.id == id }) {
            let point = cachedKnowledgePoints.remove(at: index)
            cachedArchivedPoints.append(point)
            
            // 更新本地存儲
            await cacheManager.saveKnowledgePoints(cachedKnowledgePoints)
            await cacheManager.saveArchivedKnowledgePoints(cachedArchivedPoints)
        }
    }
    
    func restoreKnowledgePoint(_ id: Int) async throws {
        try await apiService.unarchiveKnowledgePoint(id: id)
        
        // 更新快取：從歸檔列表移動到活躍列表
        if let index = cachedArchivedPoints.firstIndex(where: { $0.id == id }) {
            let point = cachedArchivedPoints.remove(at: index)
            cachedKnowledgePoints.append(point)
            
            // 更新本地存儲
            await cacheManager.saveKnowledgePoints(cachedKnowledgePoints)
            await cacheManager.saveArchivedKnowledgePoints(cachedArchivedPoints)
        }
    }
    
    func updateMasteryLevel(pointId: Int, level: Double) async throws {
        try await apiService.updateKnowledgePoint(id: pointId, updates: ["mastery_level": level])
        
        // 需要重新獲取知識點來更新快取，因為 KnowledgePoint 的屬性是不可變的
        do {
            _ = try await forceRefresh()
        } catch {
            print("重新整理知識點失敗: \(error)")
        }
    }
    
    // MARK: - Cache Management
    
    private func getCachedKnowledgePoints() -> [KnowledgePoint]? {
        guard isCacheValid() else { return nil }
        return cachedKnowledgePoints.isEmpty ? nil : cachedKnowledgePoints
    }
    
    private func getCachedArchivedPoints() -> [KnowledgePoint]? {
        guard isCacheValid() else { return nil }
        return cachedArchivedPoints.isEmpty ? nil : cachedArchivedPoints
    }
    
    private func isCacheValid() -> Bool {
        guard let lastUpdate = lastCacheUpdate else { return false }
        return Date().timeIntervalSince(lastUpdate) < cacheExpirationInterval
    }
    
    private func updateCache(knowledgePoints: [KnowledgePoint]? = nil, 
                           archivedPoints: [KnowledgePoint]? = nil) {
        if let points = knowledgePoints {
            cachedKnowledgePoints = points
        }
        
        if let archived = archivedPoints {
            cachedArchivedPoints = archived
        }
        
        lastCacheUpdate = Date()
    }
    
    /// 清除快取
    func clearCache() {
        cachedKnowledgePoints.removeAll()
        cachedArchivedPoints.removeAll()
        lastCacheUpdate = nil
    }
    
    /// 強制刷新快取
    func forceRefresh() async throws -> [KnowledgePoint] {
        clearCache()
        return try await fetchKnowledgePoints()
    }
}

// MARK: - 快取管理協議
protocol CacheManagerProtocol {
    func saveKnowledgePoints(_ points: [KnowledgePoint]) async
    func loadKnowledgePoints() async -> [KnowledgePoint]?
    func saveArchivedKnowledgePoints(_ points: [KnowledgePoint]) async
    func loadArchivedKnowledgePoints() async -> [KnowledgePoint]?
    func clearAllCache()
}

// MARK: - 本地存儲管理器
class CacheManager: CacheManagerProtocol {
    static let shared = CacheManager()
    
    private let userDefaults = UserDefaults.standard
    private let knowledgePointsKey = "cached_knowledge_points"
    private let archivedPointsKey = "cached_archived_points"
    
    private init() {}
    
    func saveKnowledgePoints(_ points: [KnowledgePoint]) async {
        do {
            let data = try JSONEncoder().encode(points)
            userDefaults.set(data, forKey: knowledgePointsKey)
        } catch {
            print("保存知識點到本地失敗: \(error)")
        }
    }
    
    func loadKnowledgePoints() async -> [KnowledgePoint]? {
        guard let data = userDefaults.data(forKey: knowledgePointsKey) else { return nil }
        
        do {
            return try JSONDecoder().decode([KnowledgePoint].self, from: data)
        } catch {
            print("從本地載入知識點失敗: \(error)")
            return nil
        }
    }
    
    func saveArchivedKnowledgePoints(_ points: [KnowledgePoint]) async {
        do {
            let data = try JSONEncoder().encode(points)
            userDefaults.set(data, forKey: archivedPointsKey)
        } catch {
            print("保存歸檔知識點到本地失敗: \(error)")
        }
    }
    
    func loadArchivedKnowledgePoints() async -> [KnowledgePoint]? {
        guard let data = userDefaults.data(forKey: archivedPointsKey) else { return nil }
        
        do {
            return try JSONDecoder().decode([KnowledgePoint].self, from: data)
        } catch {
            print("從本地載入歸檔知識點失敗: \(error)")
            return nil
        }
    }
    
    func clearAllCache() {
        userDefaults.removeObject(forKey: knowledgePointsKey)
        userDefaults.removeObject(forKey: archivedPointsKey)
    }
}