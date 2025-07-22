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
                
                print("✅ 成功從伺服器獲取 \(serverKnowledgePoints.count) 個知識點")
            } catch {
                print("⚠️ 無法從伺服器獲取知識點: \(error.localizedDescription)")
                // 不設置 errorMessage，讓程式繼續載入本地資料
            }
        }
        
        // 2. 始終嘗試載入本地儲存的知識點
        localKnowledgePoints = loadLocalKnowledgePoints()
        print("💾 本地儲存知識點: \(localKnowledgePoints.count) 個")
        
        // 3. 合併伺服器和本地知識點 - 不為未認證用戶提供示例數據
        let allKnowledgePoints = serverKnowledgePoints + localKnowledgePoints
        
        withAnimation(MicroInteractions.stateChange()) {
            knowledgePoints = allKnowledgePoints
        }
        
        // 4. 如果完全沒有數據，顯示對應的狀態
        if allKnowledgePoints.isEmpty {
            if !authManager.isAuthenticated {
                print("📋 未認證用戶，引導註冊以獲得完整功能")
                // 不顯示錯誤訊息，讓 EmptyStateView 引導用戶註冊
            } else {
                errorMessage = "無法載入任何知識點數據，請檢查網路連線"
            }
        }
        
        isLoading = false
    }
    
    /// 從本地儲存載入知識點
    private func loadLocalKnowledgePoints() -> [KnowledgePoint] {
        let guestDataManager = GuestDataManager.shared
        let localPointsData = guestDataManager.getGuestKnowledgePoints()
        
        var localPoints: [KnowledgePoint] = []
        
        for pointData in localPointsData {
            // 轉換本地儲存的字典資料為 KnowledgePoint 模型
            // 支援新的負數 ID 格式和舊的字串 ID 格式
            var pointId: Int = 0
            
            if let id = pointData["id"] as? Int {
                // 新格式：直接使用負數 ID
                pointId = id
            } else if let _ = pointData["id"] as? String {
                // 舊格式：字串 ID，本地知識點應該有負數 ID
                // 如果還是字串，說明是舊資料，跳過
                continue
            }
            
            if let category = pointData["category"] as? String,
               let subcategory = pointData["subcategory"] as? String,
               let correctPhrase = pointData["correct_phrase"] as? String,
               let explanation = pointData["explanation"] as? String,
               let userContextSentence = pointData["user_context_sentence"] as? String,
               let incorrectPhrase = pointData["incorrect_phrase_in_context"] as? String,
               let masteryLevel = pointData["mastery_level"] as? Double,
               let mistakeCount = pointData["mistake_count"] as? Int,
               let correctCount = pointData["correct_count"] as? Int,
               let isArchived = pointData["is_archived"] as? Bool {
                
                // key_point_summary 是可選的，如果沒有就使用 subcategory 或 correct_phrase
                let keyPointSummary = pointData["key_point_summary"] as? String
                
                let knowledgePoint = KnowledgePoint(
                    id: pointId,
                    category: category,
                    subcategory: subcategory,
                    correctPhrase: correctPhrase,
                    explanation: explanation,
                    userContextSentence: userContextSentence,
                    incorrectPhraseInContext: incorrectPhrase,
                    keyPointSummary: keyPointSummary,
                    masteryLevel: masteryLevel,
                    mistakeCount: mistakeCount,
                    correctCount: correctCount,
                    nextReviewDate: nil,
                    isArchived: isArchived,
                    aiReviewNotes: "本地儲存",
                    lastAiReviewDate: nil
                )
                
                localPoints.append(knowledgePoint)
            }
        }
        
        return localPoints
    }
    
    
    /// 刷新數據
    func refresh() async {
        isRefreshing = true
        await loadDashboard()
        isRefreshing = false
    }
    
    /// 刪除知識點
    func deleteKnowledgePoint(_ point: KnowledgePoint) async {
        do {
            try await repository.deleteKnowledgePoint(point.id)
            knowledgePoints.removeAll { $0.id == point.id }
        } catch {
            errorMessage = "刪除失敗：\(error.localizedDescription)"
        }
    }
    
    /// 歸檔知識點
    func archiveKnowledgePoint(_ point: KnowledgePoint) async {
        do {
            try await repository.archiveKnowledgePoint(point.id)
            knowledgePoints.removeAll { $0.id == point.id }
            archivedPoints.append(point)
        } catch {
            errorMessage = "歸檔失敗：\(error.localizedDescription)"
        }
    }
    
    /// 恢復已歸檔的知識點
    func restoreKnowledgePoint(_ point: KnowledgePoint) async {
        do {
            try await repository.restoreKnowledgePoint(point.id)
            archivedPoints.removeAll { $0.id == point.id }
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