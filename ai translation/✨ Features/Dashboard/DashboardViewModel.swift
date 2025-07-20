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
    init(repository: KnowledgePointRepository = KnowledgePointRepository.shared,
         authManager: AuthenticationManager) {
        self.repository = repository
        self.authManager = authManager
    }
    
    // MARK: - Public Methods
    
    /// 載入儀表板數據
    func loadDashboard() async {
        guard authManager.isAuthenticated else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            async let activePoints = repository.fetchKnowledgePoints()
            async let archived = repository.fetchArchivedKnowledgePoints()
            
            knowledgePoints = try await activePoints
            archivedPoints = try await archived
            
        } catch {
            errorMessage = "載入數據失敗：\(error.localizedDescription)"
            print("Dashboard 載入錯誤: \(error)")
        }
        
        isLoading = false
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