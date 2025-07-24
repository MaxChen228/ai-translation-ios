// DashboardViewModel.swift - Dashboard 業務邏輯管理

import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var knowledgePoints: [KnowledgePoint] = []
    @Published var archivedPoints: [KnowledgePoint] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var selectedKnowledgePoint: KnowledgePoint?
    @Published var showingEditView = false
    @Published var showingArchivedView = false
    
    // MARK: - Computed Properties
    var totalPoints: Int { knowledgePoints.count }
    var masteredPoints: Int { knowledgePoints.filter { $0.masteryLevel >= 0.8 }.count }
    var averageMastery: Double {
        guard !knowledgePoints.isEmpty else { return 0.0 }
        return knowledgePoints.reduce(0) { $0 + $1.masteryLevel } / Double(knowledgePoints.count)
    }
    
    var masteredPercentage: Double {
        guard totalPoints > 0 else { return 0.0 }
        return Double(masteredPoints) / Double(totalPoints) * 100
    }
    
    // MARK: - Dependencies
    private let repository: KnowledgePointRepository
    private let authManager: AuthenticationManager
    
    // MARK: - Initialization
    init(repository: KnowledgePointRepository? = nil,
         authManager: AuthenticationManager) {
        self.repository = repository ?? KnowledgePointRepository.shared
        self.authManager = authManager
    }
    
    // MARK: - Public Methods
    
    /// 載入儀表板數據
    func loadDashboard() async {
        isLoading = true
        errorMessage = nil
        
        var serverKnowledgePoints: [KnowledgePoint] = []
        var localKnowledgePoints: [KnowledgePoint] = []
        
        // 1. 如果用戶已認證，嘗試從伺服器獲取知識點
        if authManager.isAuthenticated {
            do {
                async let activePoints = repository.fetchKnowledgePoints()
                async let archived = repository.fetchArchivedKnowledgePoints()
                
                serverKnowledgePoints = try await activePoints
                archivedPoints = try await archived
                
                Logger.success("成功從伺服器獲取 \(serverKnowledgePoints.count) 個知識點", category: .api)
            } catch {
                // 檢查是否為認證錯誤
                if let apiError = error as? APIError,
                   case .serverError(let statusCode, _) = apiError,
                   statusCode == 401 {
                    // 401認證失敗：觸發重新登入，但不視為錯誤（這是正常的認證流程）
                    Logger.info("認證失效，觸發重新登入", category: .authentication)
                    Task {
                        await authManager.refreshTokenIfNeeded()
                    }
                } else {
                    // 其他真正的錯誤：記錄並繼續載入本地資料
                    Logger.warning("網路錯誤，無法從伺服器獲取知識點: \(error.localizedDescription)", category: .network)
                    Logger.info("繼續使用本地資料，不中斷用戶體驗", category: .general)
                }
            }
        }
        
        // 2. 始終嘗試載入本地儲存的知識點
        localKnowledgePoints = loadLocalKnowledgePoints()
        Logger.info("本地儲存知識點: \(localKnowledgePoints.count) 個", category: .database)
        
        // 3. 合併伺服器和本地知識點 - 不為未認證用戶提供示例數據
        let allKnowledgePoints = serverKnowledgePoints + localKnowledgePoints
        
        withAnimation(MicroInteractions.stateChange()) {
            knowledgePoints = allKnowledgePoints
        }
        
        // 4. 如果完全沒有數據，顯示對應的狀態
        if allKnowledgePoints.isEmpty {
            if !authManager.isAuthenticated {
                Logger.info("未認證用戶，引導註冊以獲得完整功能", category: .authentication)
                // 不顯示錯誤訊息，讓 EmptyStateView 引導用戶註冊
            } else {
                // 已認證用戶但沒有知識點 - 這是正常的新用戶狀態
                Logger.info("已認證用戶暫無知識點，這是正常的新用戶狀態", category: .general)
                // 不設置錯誤訊息，讓用戶正常開始學習
            }
        }
        
        isLoading = false
    }
    
    /// 從本地儲存載入知識點（已移除訪客功能）
    private func loadLocalKnowledgePoints() -> [KnowledgePoint] {
        // 訪客功能已移除，直接返回空陣列
        return []
    }
    
    
    /// 刷新數據
    func refresh() async {
        isRefreshing = true
        await loadDashboard()
        isRefreshing = false
    }
    
    /// 刪除知識點
    func deleteKnowledgePoint(_ point: KnowledgePoint) async {
        guard let pointId = point.numericId else { 
            errorMessage = "無法取得知識點ID"
            return 
        }
        do {
            try await repository.deleteKnowledgePoint(pointId)
            knowledgePoints.removeAll { $0.numericId == pointId }
        } catch {
            errorMessage = "刪除失敗：\(error.localizedDescription)"
        }
    }
    
    /// 歸檔知識點
    func archiveKnowledgePoint(_ point: KnowledgePoint) async {
        guard let pointId = point.numericId else { 
            errorMessage = "無法取得知識點ID"
            return 
        }
        do {
            try await repository.archiveKnowledgePoint(pointId)
            knowledgePoints.removeAll { $0.numericId == pointId }
            archivedPoints.append(point)
        } catch {
            errorMessage = "歸檔失敗：\(error.localizedDescription)"
        }
    }
    
    /// 恢復已歸檔的知識點
    func restoreKnowledgePoint(_ point: KnowledgePoint) async {
        guard let pointId = point.numericId else { 
            errorMessage = "無法取得知識點ID"
            return 
        }
        do {
            try await repository.restoreKnowledgePoint(pointId)
            archivedPoints.removeAll { $0.numericId == pointId }
            knowledgePoints.append(point)
        } catch {
            errorMessage = "恢復失敗：\(error.localizedDescription)"
        }
    }
    
    /// 更新知識點熟練度
    func updateMasteryLevel(for pointId: Int, newLevel: Double) async {
        do {
            try await repository.updateMasteryLevel(pointId: pointId, level: newLevel)
            
            // 重新載入數據，因為 KnowledgePoint 屬性是不可變的
            await loadDashboard()
        } catch {
            errorMessage = "更新失敗：\(error.localizedDescription)"
        }
    }
    
    /// 選擇知識點進行編輯
    func selectKnowledgePoint(_ point: KnowledgePoint) {
        selectedKnowledgePoint = point
        showingEditView = true
    }
    
    /// 清除錯誤訊息
    func clearError() {
        errorMessage = nil
    }
    
    /// 顯示歸檔視圖
    func showArchivedPoints() {
        showingArchivedView = true
    }
}

// MARK: - 統計數據結構
extension DashboardViewModel {
    struct DashboardStats {
        let totalPoints: Int
        let masteredPoints: Int
        let averageMastery: Double
        let masteredPercentage: Double
        let learningStreak: Int
        let todayProgress: Double
    }
    
    var dashboardStats: DashboardStats {
        DashboardStats(
            totalPoints: totalPoints,
            masteredPoints: masteredPoints,
            averageMastery: averageMastery,
            masteredPercentage: masteredPercentage,
            learningStreak: 0, // TODO: 實現學習連續天數統計
            todayProgress: 0.0 // TODO: 實現今日進度統計
        )
    }
}