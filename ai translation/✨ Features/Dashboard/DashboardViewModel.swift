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
    var masteredPoints: Int { knowledgePoints.filter { $0.mastery_level >= 0.8 }.count }
    var averageMastery: Double {
        guard !knowledgePoints.isEmpty else { return 0.0 }
        return knowledgePoints.reduce(0) { $0 + $1.mastery_level } / Double(knowledgePoints.count)
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
        
        // 3. 如果用戶未認證且沒有本地數據，嘗試載入示例知識點
        var sampleKnowledgePoints: [KnowledgePoint] = []
        if !authManager.isAuthenticated && localKnowledgePoints.isEmpty {
            do {
                sampleKnowledgePoints = try await UnifiedAPIService.shared.getSampleKnowledgePoints()
                print("📚 成功載入 \(sampleKnowledgePoints.count) 個示例知識點")
            } catch {
                print("⚠️ 無法從伺服器載入示例知識點: \(error.localizedDescription)")
                // 使用本地預設示例知識點作為備援
                sampleKnowledgePoints = createLocalSampleKnowledgePoints()
                print("📋 使用本地示例知識點: \(sampleKnowledgePoints.count) 個")
            }
        }
        
        // 4. 合併所有知識點數據
        let allKnowledgePoints = serverKnowledgePoints + localKnowledgePoints + sampleKnowledgePoints
        
        withAnimation(.easeInOut(duration: 0.3)) {
            knowledgePoints = allKnowledgePoints
        }
        
        // 5. 如果完全沒有數據，才顯示錯誤或空狀態
        if allKnowledgePoints.isEmpty {
            if !authManager.isAuthenticated {
                print("📋 未認證用戶，無任何數據")
                // 不顯示錯誤，讓 EmptyStateView 處理
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
                    correct_phrase: correctPhrase,
                    explanation: explanation,
                    user_context_sentence: userContextSentence,
                    incorrect_phrase_in_context: incorrectPhrase,
                    key_point_summary: keyPointSummary,
                    mastery_level: masteryLevel,
                    mistake_count: mistakeCount,
                    correct_count: correctCount,
                    next_review_date: nil,
                    is_archived: isArchived,
                    ai_review_notes: "本地儲存",
                    last_ai_review_date: nil
                )
                
                localPoints.append(knowledgePoint)
            }
        }
        
        return localPoints
    }
    
    /// 創建本地示例知識點
    private func createLocalSampleKnowledgePoints() -> [KnowledgePoint] {
        let samplePoints = [
            KnowledgePoint(
                id: -1001,
                category: "語法錯誤",
                subcategory: "主語動詞一致性",
                correct_phrase: "The team is working on the project",
                explanation: "當主語是單數集合名詞時，動詞使用單數形式",
                user_context_sentence: "The team are working on the project",
                incorrect_phrase_in_context: "are",
                key_point_summary: "集合名詞的主謂一致",
                mastery_level: 2.3,
                mistake_count: 1,
                correct_count: 0,
                next_review_date: nil,
                is_archived: false,
                ai_review_notes: "示例知識點",
                last_ai_review_date: nil
            ),
            KnowledgePoint(
                id: -1002,
                category: "詞彙選擇",
                subcategory: "介詞使用",
                correct_phrase: "depend on",
                explanation: "depend 後面通常接介詞 on，表示「依靠、取決於」",
                user_context_sentence: "It depends of the weather",
                incorrect_phrase_in_context: "depends of",
                key_point_summary: "depend 的介詞搭配",
                mastery_level: 1.8,
                mistake_count: 2,
                correct_count: 0,
                next_review_date: nil,
                is_archived: false,
                ai_review_notes: "示例知識點",
                last_ai_review_date: nil
            ),
            KnowledgePoint(
                id: -1003,
                category: "時態使用",
                subcategory: "現在完成時",
                correct_phrase: "I have lived here for five years",
                explanation: "現在完成時用於表示過去開始並持續到現在的動作或狀態",
                user_context_sentence: "I live here for five years",
                incorrect_phrase_in_context: "live",
                key_point_summary: "現在完成時的使用情境",
                mastery_level: 3.1,
                mistake_count: 0,
                correct_count: 2,
                next_review_date: nil,
                is_archived: false,
                ai_review_notes: "示例知識點",
                last_ai_review_date: nil
            ),
            KnowledgePoint(
                id: -1004,
                category: "語法錯誤",
                subcategory: "冠詞使用",
                correct_phrase: "a university",
                explanation: "university 雖然以母音字母 u 開頭，但發音是子音 /j/，所以用 a",
                user_context_sentence: "He studies at an university",
                incorrect_phrase_in_context: "an university",
                key_point_summary: "冠詞 a/an 的發音規則",
                mastery_level: 2.7,
                mistake_count: 1,
                correct_count: 1,
                next_review_date: nil,
                is_archived: false,
                ai_review_notes: "示例知識點",
                last_ai_review_date: nil
            ),
            KnowledgePoint(
                id: -1005,
                category: "詞彙選擇",
                subcategory: "動詞辨析",
                correct_phrase: "make a decision",
                explanation: "make a decision 是固定搭配，表示「做決定」",
                user_context_sentence: "I need to take a decision",
                incorrect_phrase_in_context: "take a decision",
                key_point_summary: "make vs take 的搭配差異",
                mastery_level: 1.5,
                mistake_count: 3,
                correct_count: 0,
                next_review_date: nil,
                is_archived: false,
                ai_review_notes: "示例知識點",
                last_ai_review_date: nil
            )
        ]
        
        return samplePoints
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