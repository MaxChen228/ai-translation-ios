// APIServiceProtocol.swift - API 服務協議定義

import Foundation

// MARK: - 認證 API 服務協議
protocol AuthenticationAPIServiceProtocol {
    static func login(email: String, password: String) async throws -> AuthResponse
    static func register(request: RegisterRequest) async throws -> AuthResponse
    static func refreshToken(refreshToken: String) async throws -> AuthResponse
    static func logout() async throws
    static func getCurrentUser() async throws -> User
}

// MARK: - 知識點核心 API 服務協議
protocol KnowledgePointCoreAPIServiceProtocol {
    static func fetchKnowledgePoint(id: Int) async throws -> KnowledgePoint
    static func updateKnowledgePoint(id: Int, updates: [String: Any]) async throws
    static func deleteKnowledgePoint(id: Int) async throws
    static func archiveKnowledgePoint(id: Int) async throws
    static func unarchiveKnowledgePoint(id: Int) async throws
    static func fetchArchivedKnowledgePoints() async throws -> [KnowledgePoint]
    static func batchArchiveKnowledgePoints(ids: [Int]) async throws
    static func aiReviewKnowledgePoint(id: Int, modelName: String?) async throws -> AIReviewResult
    static func mergeErrors(error1: ErrorAnalysis, error2: ErrorAnalysis) async throws -> ErrorAnalysis
    static func finalizeKnowledgePoints(errors: [ErrorAnalysis], questionData: [String: Any?], userAnswer: String) async throws -> Int
}

// MARK: - 訪客模式 API 服務協議
protocol GuestModeAPIServiceProtocol {
    static func getSampleQuestions(count: Int) async throws -> QuestionsResponse
    static func submitAnswer(question: [String: Any], answer: String) async throws -> FeedbackResponse
    static func getSampleKnowledgePoints() async throws -> [KnowledgePoint]
}

// MARK: - 儀表板 API 服務協議
protocol DashboardAPIServiceProtocol {
    static func getDashboard() async throws -> DashboardResponse
    static func getCalendarHeatmap(year: Int, month: Int) async throws -> HeatmapResponse
}

// MARK: - 統一 API 服務協議
protocol KnowledgePointAPIServiceProtocol {
    // 認證相關
    static func login(email: String, password: String) async throws -> AuthResponse
    static func register(request: RegisterRequest) async throws -> AuthResponse
    static func refreshToken(refreshToken: String) async throws -> AuthResponse
    static func logout() async throws
    static func getCurrentUser() async throws -> User
    
    // 知識點相關
    static func fetchKnowledgePoint(id: Int) async throws -> KnowledgePoint
    static func updateKnowledgePoint(id: Int, updates: [String: Any]) async throws
    static func deleteKnowledgePoint(id: Int) async throws
    static func archiveKnowledgePoint(id: Int) async throws
    static func unarchiveKnowledgePoint(id: Int) async throws
    static func fetchArchivedKnowledgePoints() async throws -> [KnowledgePoint]
    static func batchArchiveKnowledgePoints(ids: [Int]) async throws
    static func aiReviewKnowledgePoint(id: Int, modelName: String?) async throws -> AIReviewResult
    static func mergeErrors(error1: ErrorAnalysis, error2: ErrorAnalysis) async throws -> ErrorAnalysis
    static func finalizeKnowledgePoints(errors: [ErrorAnalysis], questionData: [String: Any?], userAnswer: String) async throws -> Int
    
    // 訪客模式相關
    static func getGuestSampleQuestions(count: Int) async throws -> QuestionsResponse
    static func submitGuestAnswer(question: [String: Any], answer: String) async throws -> FeedbackResponse
    static func getGuestSampleKnowledgePoints() async throws -> [KnowledgePoint]
    
    // 儀表板相關
    static func getDashboard() async throws -> DashboardResponse
    static func getCalendarHeatmap(year: Int, month: Int) async throws -> HeatmapResponse
}

// MARK: - 協議擴展 - 讓現有實現符合協議
extension AuthenticationAPIService: AuthenticationAPIServiceProtocol {}
extension KnowledgePointCoreAPIService: KnowledgePointCoreAPIServiceProtocol {}
extension GuestModeAPIService: GuestModeAPIServiceProtocol {}
extension DashboardAPIService: DashboardAPIServiceProtocol {}
extension KnowledgePointAPIService: KnowledgePointAPIServiceProtocol {}