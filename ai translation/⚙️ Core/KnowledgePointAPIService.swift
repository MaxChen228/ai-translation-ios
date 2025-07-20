// KnowledgePointAPIService.swift - 重構後的統一 API 服務入口

import Foundation

// MARK: - 重構後的 API 錯誤處理
enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    case unknownError
}

// MARK: - 統一的 API 服務入口
struct KnowledgePointAPIService {
    
    // MARK: - 認證相關 API (委派給專門服務)
    
    /// 使用者登入
    static func login(email: String, password: String) async throws -> AuthResponse {
        return try await AuthenticationAPIService.login(email: email, password: password)
    }
    
    /// 使用者註冊
    static func register(request: RegisterRequest) async throws -> AuthResponse {
        return try await AuthenticationAPIService.register(request: request)
    }
    
    /// 刷新 Access Token
    static func refreshToken(refreshToken: String) async throws -> AuthResponse {
        return try await AuthenticationAPIService.refreshToken(refreshToken: refreshToken)
    }
    
    /// 登出
    static func logout() async throws {
        try await AuthenticationAPIService.logout()
    }
    
    /// 取得目前使用者資訊
    static func getCurrentUser() async throws -> User {
        return try await AuthenticationAPIService.getCurrentUser()
    }
    
    // MARK: - 知識點相關 API (委派給專門服務)

    /// 獲取單一知識點的詳細資料
    static func fetchKnowledgePoint(id: Int) async throws -> KnowledgePoint {
        return try await KnowledgePointCoreAPIService.fetchKnowledgePoint(id: id)
    }

    /// 更新知識點資料
    static func updateKnowledgePoint(id: Int, updates: [String: Any]) async throws {
        try await KnowledgePointCoreAPIService.updateKnowledgePoint(id: id, updates: updates)
    }

    /// AI 重新審閱知識點
    static func aiReviewKnowledgePoint(id: Int, modelName: String? = nil) async throws -> AIReviewResult {
        return try await KnowledgePointCoreAPIService.aiReviewKnowledgePoint(id: id, modelName: modelName)
    }

    /// 歸檔知識點 (統一使用此方法，移除重複的 archivePoint)
    static func archiveKnowledgePoint(id: Int) async throws {
        try await KnowledgePointCoreAPIService.archiveKnowledgePoint(id: id)
    }
    
    /// 取消歸檔知識點 (統一使用此方法，移除重複的 unarchivePoint)
    static func unarchiveKnowledgePoint(id: Int) async throws {
        try await KnowledgePointCoreAPIService.unarchiveKnowledgePoint(id: id)
    }
    
    /// 刪除知識點 (統一使用此方法，移除重複的 deletePoint)
    static func deleteKnowledgePoint(id: Int) async throws {
        try await KnowledgePointCoreAPIService.deleteKnowledgePoint(id: id)
    }
    
    /// 獲取所有已歸檔的知識點 (統一使用此方法，移除重複的 fetchArchivedPoints)
    static func fetchArchivedKnowledgePoints() async throws -> [KnowledgePoint] {
        return try await KnowledgePointCoreAPIService.fetchArchivedKnowledgePoints()
    }
    
    /// 批次歸檔知識點
    static func batchArchiveKnowledgePoints(ids: [Int]) async throws {
        try await KnowledgePointCoreAPIService.batchArchiveKnowledgePoints(ids: ids)
    }
    
    /// 合併錯誤分析
    static func mergeErrors(error1: ErrorAnalysis, error2: ErrorAnalysis) async throws -> ErrorAnalysis {
        return try await KnowledgePointCoreAPIService.mergeErrors(error1: error1, error2: error2)
    }

    /// 將最終確認的錯誤列表儲存為知識點
    static func finalizeKnowledgePoints(errors: [ErrorAnalysis], questionData: [String: Any?], userAnswer: String) async throws -> Int {
        return try await KnowledgePointCoreAPIService.finalizeKnowledgePoints(errors: errors, questionData: questionData, userAnswer: userAnswer)
    }

    // MARK: - 訪客模式 API (委派給專門服務)
    
    /// 訪客模式獲取範例題目
    static func getGuestSampleQuestions(count: Int = 3) async throws -> QuestionsResponse {
        return try await GuestModeAPIService.getSampleQuestions(count: count)
    }
    
    /// 訪客模式提交答案（僅返回基本分析）
    static func submitGuestAnswer(question: [String: Any], answer: String) async throws -> FeedbackResponse {
        return try await GuestModeAPIService.submitAnswer(question: question, answer: answer)
    }
    
    /// 訪客模式獲取範例知識點
    static func getGuestSampleKnowledgePoints() async throws -> [KnowledgePoint] {
        return try await GuestModeAPIService.getSampleKnowledgePoints()
    }
    
    // MARK: - 儀表板相關 API (委派給專門服務)
    
    /// 統一的儀表板數據獲取 (支援認證和訪客模式)
    static func getDashboard() async throws -> DashboardResponse {
        return try await DashboardAPIService.getDashboard()
    }
    
    /// 獲取學習日曆熱力圖數據 (支援認證和訪客模式)
    static func getCalendarHeatmap(year: Int, month: Int) async throws -> HeatmapResponse {
        return try await DashboardAPIService.getCalendarHeatmap(year: year, month: month)
    }
}
