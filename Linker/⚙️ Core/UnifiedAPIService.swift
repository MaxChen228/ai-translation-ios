// UnifiedAPIService.swift - 統一的API服務
// 這個類替代了原來分散的 4 個API服務類的功能

import Foundation

/// 統一的API服務協議
/// 使用協議以便於測試和依賴注入
protocol UnifiedAPIServiceProtocol {
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T
    func requestWithoutResponse(_ endpoint: APIEndpoint) async throws
    
    // 認證相關
    func login(email: String, password: String) async throws -> AuthResponse
    func register(request: RegisterRequest) async throws -> AuthResponse
    func refreshToken(_ refreshToken: String) async throws -> AuthResponse
    func logout() async throws
    func getCurrentUser() async throws -> User
    func loginWithGoogle(idToken: String) async throws -> AuthResponse
    func loginWithApple(identityToken: String) async throws -> AuthResponse
    
    // 知識點管理
    func fetchKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws -> KnowledgePoint
    func updateKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?, updates: KnowledgePointUpdateRequest) async throws
    func deleteKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws
    func archiveKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws
    func unarchiveKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws
    func fetchArchivedKnowledgePoints() async throws -> [KnowledgePoint]
    func batchArchiveKnowledgePoints(compositeIds: [CompositeKnowledgePointID]?, legacyIds: [Int]?) async throws
    func mergeErrors(error1: ErrorAnalysis, error2: ErrorAnalysis) async throws -> ErrorAnalysis
    func finalizeKnowledgePoints(request: KnowledgePointFinalizationRequest) async throws -> Int
    
    // 為了向後兼容的便利方法
    func fetchKnowledgePoint(id: Int) async throws -> KnowledgePoint
    func updateKnowledgePoint(id: Int, updates: KnowledgePointUpdateRequest) async throws
    func deleteKnowledgePoint(id: Int) async throws
    func archiveKnowledgePoint(id: Int) async throws
    func unarchiveKnowledgePoint(id: Int) async throws
    func batchArchiveKnowledgePoints(ids: [Int]) async throws
    
    // 儀表板相關
    func getDashboard() async throws -> DashboardResponse
    func getCalendarHeatmap(year: Int, month: Int) async throws -> HeatmapResponse
    
    // 訪客模式
    func getSampleQuestions(count: Int) async throws -> QuestionsResponse
    func submitGuestAnswer(request: GuestAnswerSubmissionRequest) async throws -> FeedbackResponse
    func getSampleKnowledgePoints() async throws -> [KnowledgePoint]
}

/// 統一的API服務實現
/// 替代原來的：
/// - KnowledgePointAPIService (轉發器)
/// - AuthenticationAPIService
/// - KnowledgePointCoreAPIService  
/// - DashboardAPIService
class UnifiedAPIService: UnifiedAPIServiceProtocol {
    
    static let shared = UnifiedAPIService()
    
    private let networkManager: NetworkManager
    private let keychain: KeychainManager
    private let baseURL: String
    
    init(networkManager: NetworkManager = NetworkManager.shared,
         keychain: KeychainManager = KeychainManager()) {
        self.networkManager = networkManager
        self.keychain = keychain
        self.baseURL = APIConfig.apiBaseURL
    }
    
    // MARK: - 主要API方法
    
    /// 統一的API請求方法 - 有返回值
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        let request = try buildRequest(for: endpoint)
        
        let (data, response) = try await networkManager.performRequest(request)
        try networkManager.validateHTTPResponse(response, data: data)
        
        return try networkManager.safeDecodeJSON(data, as: responseType)
    }
    
    /// 統一的API請求方法 - 無返回值
    func requestWithoutResponse(_ endpoint: APIEndpoint) async throws {
        let request = try buildRequest(for: endpoint)
        
        let (data, response) = try await networkManager.performRequest(request)
        try networkManager.validateHTTPResponse(response, data: data)
    }
    
    // MARK: - 請求構建
    
    private func buildRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        guard let url = endpoint.buildURL(baseURL: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeoutInterval
        
        // 設置標準標頭
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 完全禁用快取
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache, no-store, must-revalidate", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.setValue("0", forHTTPHeaderField: "Expires")
        
        // POST/PUT請求需要Content-Type
        if endpoint.method == .POST || endpoint.method == .PUT {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // 添加認證標頭
        addAuthHeader(to: &request, endpoint: endpoint)
        
        // 設置請求體
        if let requestBody = try endpoint.buildRequestBody() {
            request.httpBody = requestBody
        }
        
        return request
    }
    
    private func addAuthHeader(to request: inout URLRequest, endpoint: APIEndpoint) {
        if endpoint.requiresAuth {
            if let token = keychain.retrieve(.accessToken) {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                Logger.debug("[UnifiedAPIService] 已添加認證token到請求: \(endpoint)", category: .api)
            } else {
                Logger.warning("[UnifiedAPIService] 未找到認證token，無法添加到請求: \(endpoint)", category: .api)
            }
        } else if endpoint.isGuestEndpoint {
            // 訪客模式端點使用特殊標識
            request.setValue("Guest", forHTTPHeaderField: "X-User-Type")
            Logger.info("[UnifiedAPIService] 使用訪客模式請求: \(endpoint)", category: .api)
        }
    }
}

// MARK: - 高級API方法（業務邏輯層）
extension UnifiedAPIService {
    
    // MARK: - 認證相關
    
    func login(email: String, password: String) async throws -> AuthResponse {
        return try await request(.login(email: email, password: password), responseType: AuthResponse.self)
    }
    
    func register(request: RegisterRequest) async throws -> AuthResponse {
        return try await self.request(.register(request), responseType: AuthResponse.self)
    }
    
    func refreshToken(_ refreshToken: String) async throws -> AuthResponse {
        return try await request(.refreshToken(refreshToken), responseType: AuthResponse.self)
    }
    
    func logout() async throws {
        try await requestWithoutResponse(.logout)
    }
    
    func getCurrentUser() async throws -> User {
        return try await request(.getCurrentUser, responseType: User.self)
    }
    
    func loginWithGoogle(idToken: String) async throws -> AuthResponse {
        return try await request(.googleAuth(idToken: idToken), responseType: AuthResponse.self)
    }
    
    func loginWithApple(identityToken: String) async throws -> AuthResponse {
        return try await request(.appleAuth(identityToken: identityToken), responseType: AuthResponse.self)
    }
    
    // MARK: - 知識點管理
    
    // 主要的複合ID方法
    func fetchKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws -> KnowledgePoint {
        return try await request(.fetchKnowledgePoint(compositeId: compositeId, legacyId: legacyId), responseType: KnowledgePoint.self)
    }
    
    func updateKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?, updates: KnowledgePointUpdateRequest) async throws {
        try await requestWithoutResponse(.updateKnowledgePoint(compositeId: compositeId, legacyId: legacyId, updates: updates))
    }
    
    func deleteKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws {
        try await requestWithoutResponse(.deleteKnowledgePoint(compositeId: compositeId, legacyId: legacyId))
    }
    
    func archiveKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws {
        try await requestWithoutResponse(.archiveKnowledgePoint(compositeId: compositeId, legacyId: legacyId))
    }
    
    func unarchiveKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws {
        try await requestWithoutResponse(.unarchiveKnowledgePoint(compositeId: compositeId, legacyId: legacyId))
    }
    
    // 向後兼容的便利方法
    func fetchKnowledgePoint(id: Int) async throws -> KnowledgePoint {
        return try await fetchKnowledgePoint(compositeId: nil, legacyId: id)
    }
    
    func updateKnowledgePoint(id: Int, updates: KnowledgePointUpdateRequest) async throws {
        try await updateKnowledgePoint(compositeId: nil, legacyId: id, updates: updates)
    }
    
    func deleteKnowledgePoint(id: Int) async throws {
        try await deleteKnowledgePoint(compositeId: nil, legacyId: id)
    }
    
    func archiveKnowledgePoint(id: Int) async throws {
        try await archiveKnowledgePoint(compositeId: nil, legacyId: id)
    }
    
    func unarchiveKnowledgePoint(id: Int) async throws {
        try await unarchiveKnowledgePoint(compositeId: nil, legacyId: id)
    }
    
    func fetchArchivedKnowledgePoints() async throws -> [KnowledgePoint] {
        let response = try await request(.fetchArchivedKnowledgePoints, responseType: DashboardResponse.self)
        return response.knowledgePoints
    }
    
    func batchArchiveKnowledgePoints(compositeIds: [CompositeKnowledgePointID]?, legacyIds: [Int]?) async throws {
        try await requestWithoutResponse(.batchOperationKnowledgePoints(action: "archive", compositeIds: compositeIds, legacyIds: legacyIds))
    }
    
    // 向後兼容的便利方法
    func batchArchiveKnowledgePoints(ids: [Int]) async throws {
        try await batchArchiveKnowledgePoints(compositeIds: nil, legacyIds: ids)
    }
    
    func aiReviewKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?, modelName: String? = nil) async throws -> AIReviewResult {
        struct AIReviewResponse: Codable {
            let review_result: AIReviewResult
        }
        
        let response = try await request(.aiReviewKnowledgePoint(compositeId: compositeId, legacyId: legacyId, modelName: modelName), 
                                       responseType: AIReviewResponse.self)
        return response.review_result
    }
    
    // 向後兼容的便利方法
    func aiReviewKnowledgePoint(id: Int, modelName: String? = nil) async throws -> AIReviewResult {
        return try await aiReviewKnowledgePoint(compositeId: nil, legacyId: id, modelName: modelName)
    }
    
    func mergeErrors(error1: ErrorAnalysis, error2: ErrorAnalysis) async throws -> ErrorAnalysis {
        struct MergeResponse: Codable {
            let merged_error: ErrorAnalysis
        }
        
        let response = try await request(.mergeErrors(error1, error2), responseType: MergeResponse.self)
        return response.merged_error
    }
    
    func finalizeKnowledgePoints(request: KnowledgePointFinalizationRequest) async throws -> Int {
        struct FinalizeResponse: Codable {
            let saved_count: Int
            let message: String?
        }
        
        Logger.info("[UnifiedAPIService] 開始儲存知識點，錯誤數量: \(request.errorAnalyses.count)", category: .api)
        
        do {
            let response = try await self.request(.finalizeKnowledgePoints(request), 
                                           responseType: FinalizeResponse.self)
            Logger.success("[UnifiedAPIService] 成功儲存知識點到雲端，數量: \(response.saved_count)", category: .api)
            return response.saved_count
        } catch {
            // API不可用時的降級策略
            Logger.warning("[UnifiedAPIService] Finalize API不可用，使用本地備用策略，錯誤: \(error)", category: .api)
            return try await handleFinalizeOffline(errors: request.errorAnalyses, questionData: request.questionData, userAnswer: request.userAnswer)
        }
    }
    
    // MARK: - 儀表板相關
    
    func getDashboard() async throws -> DashboardResponse {
        return try await request(.getDashboard, responseType: DashboardResponse.self)
    }
    
    func getCalendarHeatmap(year: Int, month: Int) async throws -> HeatmapResponse {
        return try await request(.getCalendarHeatmap(year: year, month: month), responseType: HeatmapResponse.self)
    }
    
    func getDailyDetails(date: String) async throws -> DailyDetailsResponse {
        return try await request(.getDailyDetails(date: date), responseType: DailyDetailsResponse.self)
    }
    
    func generateDailySummary(date: String) async throws -> DailySummaryResponse {
        return try await request(.generateDailySummary(date: date), responseType: DailySummaryResponse.self)
    }
    
    // MARK: - 訪客模式
    
    func getSampleQuestions(count: Int = 3) async throws -> QuestionsResponse {
        return try await request(.getSampleQuestions(count: count), responseType: QuestionsResponse.self)
    }
    
    func submitGuestAnswer(request: GuestAnswerSubmissionRequest) async throws -> FeedbackResponse {
        return try await self.request(.submitGuestAnswer(request), responseType: FeedbackResponse.self)
    }
    
    func getSampleKnowledgePoints() async throws -> [KnowledgePoint] {
        let response = try await request(.getSampleKnowledgePoints, responseType: DashboardResponse.self)
        return response.knowledgePoints
    }
    
    // MARK: - Helix語義系統
    
    func getRelatedKnowledgePoints(compositeId: CompositeKnowledgePointID?, legacyId: Int?, includeDetails: Bool = true) async throws -> [KnowledgePoint] {
        let response = try await request(.getRelatedKnowledgePoints(compositeId: compositeId, legacyId: legacyId, includeDetails: includeDetails), 
                                       responseType: HelixConnectionResponse.self)
        
        // 將Helix回應轉換為KnowledgePoint陣列
        var relatedPoints: [KnowledgePoint] = []
        var seenIds: Set<Int> = []
        
        for connection in response.data.connections.prefix(5) {
            if let details = connection.connectedPointDetails,
               !seenIds.contains(connection.connectedPointId) {
                seenIds.insert(connection.connectedPointId)
                
                let knowledgePoint = KnowledgePoint(
                    compositeId: nil,
                    legacyId: connection.connectedPointId,
                    oldId: nil,
                    category: details.category,
                    subcategory: details.subcategory,
                    correctPhrase: details.correctPhrase,
                    explanation: nil,
                    userContextSentence: nil,
                    incorrectPhraseInContext: nil,
                    keyPointSummary: details.keyPointSummary,
                    masteryLevel: details.masteryLevel,
                    mistakeCount: 0,
                    correctCount: 0,
                    nextReviewDate: nil,
                    isArchived: false,
                    aiReviewNotes: nil,
                    lastAiReviewDate: nil
                )
                
                relatedPoints.append(knowledgePoint)
            }
        }
        
        return relatedPoints
    }
    
    // 向後兼容的便利方法
    func getRelatedKnowledgePoints(id: Int, includeDetails: Bool = true) async throws -> [KnowledgePoint] {
        return try await getRelatedKnowledgePoints(compositeId: nil, legacyId: id, includeDetails: includeDetails)
    }
    
    // MARK: - 單字記憶庫 (暫時禁用，待後續實現)
    
    // 注意：單字記憶庫相關方法暫時移除，避免編譯錯誤
    // 這些方法將在後續階段重新實現
}

// MARK: - 私有輔助方法
private extension UnifiedAPIService {
    
    /// 處理finalize API不可用時的本地備用策略
    func handleFinalizeOffline(errors: [ErrorAnalysis], 
                              questionData: QuestionData, 
                              userAnswer: String) async throws -> Int {
        // 訪客功能已移除，直接拋出錯誤
        throw APIError.serverError(statusCode: 503, message: "請登入以儲存學習進度")
    }
}

// MARK: - 測試用的Mock實現
class MockUnifiedAPIService: UnifiedAPIServiceProtocol {
    
    static let shared = MockUnifiedAPIService()
    
    var shouldSucceed = true
    var mockDelay: TimeInterval = 0.1
    
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        if mockDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        }
        
        if !shouldSucceed {
            throw APIError.serverError(statusCode: 500, message: "Mock API Error")
        }
        
        return try createMockResponse(for: endpoint, responseType: responseType)
    }
    
    func requestWithoutResponse(_ endpoint: APIEndpoint) async throws {
        if mockDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        }
        
        if !shouldSucceed {
            throw APIError.serverError(statusCode: 500, message: "Mock API Error")
        }
    }
    
    // MARK: - 認證相關Mock實現
    
    func login(email: String, password: String) async throws -> AuthResponse {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 401, message: "Mock Login Failed") }
        return createMockAuthResponse()
    }
    
    func register(request: RegisterRequest) async throws -> AuthResponse {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 409, message: "Mock Registration Failed") }
        return createMockAuthResponse()
    }
    
    func refreshToken(_ refreshToken: String) async throws -> AuthResponse {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 401, message: "Mock Token Refresh Failed") }
        return createMockAuthResponse()
    }
    
    func logout() async throws {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 500, message: "Mock Logout Failed") }
    }
    
    func getCurrentUser() async throws -> User {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 401, message: "Mock Get User Failed") }
        return createMockUser()
    }
    
    func loginWithGoogle(idToken: String) async throws -> AuthResponse {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 401, message: "Mock Google Login Failed") }
        return createMockAuthResponse()
    }
    
    func loginWithApple(identityToken: String) async throws -> AuthResponse {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 401, message: "Mock Apple Login Failed") }
        return createMockAuthResponse()
    }
    
    // MARK: - 知識點管理Mock實現
    
    // 主要的複合ID方法
    func fetchKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws -> KnowledgePoint {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 404, message: "Mock Knowledge Point Not Found") }
        return createMockKnowledgePoint()
    }
    
    func updateKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?, updates: KnowledgePointUpdateRequest) async throws {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 500, message: "Mock Update Failed") }
    }
    
    func deleteKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 404, message: "Mock Delete Failed") }
    }
    
    func archiveKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 500, message: "Mock Archive Failed") }
    }
    
    func unarchiveKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?) async throws {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 500, message: "Mock Unarchive Failed") }
    }
    
    func batchArchiveKnowledgePoints(compositeIds: [CompositeKnowledgePointID]?, legacyIds: [Int]?) async throws {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 500, message: "Mock Batch Archive Failed") }
    }
    
    // 向後兼容的便利方法
    func fetchKnowledgePoint(id: Int) async throws -> KnowledgePoint {
        return try await fetchKnowledgePoint(compositeId: nil, legacyId: id)
    }
    
    func updateKnowledgePoint(id: Int, updates: KnowledgePointUpdateRequest) async throws {
        try await updateKnowledgePoint(compositeId: nil, legacyId: id, updates: updates)
    }
    
    func deleteKnowledgePoint(id: Int) async throws {
        try await deleteKnowledgePoint(compositeId: nil, legacyId: id)
    }
    
    func archiveKnowledgePoint(id: Int) async throws {
        try await archiveKnowledgePoint(compositeId: nil, legacyId: id)
    }
    
    func unarchiveKnowledgePoint(id: Int) async throws {
        try await unarchiveKnowledgePoint(compositeId: nil, legacyId: id)
    }
    
    func fetchArchivedKnowledgePoints() async throws -> [KnowledgePoint] {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 500, message: "Mock Fetch Archived Failed") }
        return [createMockKnowledgePoint()]
    }
    
    func batchArchiveKnowledgePoints(ids: [Int]) async throws {
        try await batchArchiveKnowledgePoints(compositeIds: nil, legacyIds: ids)
    }
    
    func mergeErrors(error1: ErrorAnalysis, error2: ErrorAnalysis) async throws -> ErrorAnalysis {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 500, message: "Mock Merge Errors Failed") }
        
        // 創建合併後的錯誤分析
        return ErrorAnalysis(
            errorTypeCode: error1.errorTypeCode,
            keyPointSummary: "Merged summary",
            originalPhrase: error1.originalPhrase,
            correction: "\(error1.correction) + \(error2.correction)",
            explanation: "Merged explanation: \(error1.explanation) | \(error2.explanation)",
            severity: error1.severity
        )
    }
    
    func finalizeKnowledgePoints(request: KnowledgePointFinalizationRequest) async throws -> Int {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 500, message: "Mock Finalize Knowledge Points Failed") }
        
        // 模擬保存成功，返回錯誤數量
        return request.errorAnalyses.count
    }
    
    // MARK: - 儀表板相關Mock實現
    
    func getDashboard() async throws -> DashboardResponse {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 500, message: "Mock Dashboard Failed") }
        return DashboardResponse(knowledgePoints: [createMockKnowledgePoint()])
    }
    
    func getCalendarHeatmap(year: Int, month: Int) async throws -> HeatmapResponse {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 500, message: "Mock Heatmap Failed") }
        return HeatmapResponse(heatmap_data: ["2025-07-20": 5])
    }
    
    // MARK: - 訪客模式Mock實現
    
    func getSampleQuestions(count: Int) async throws -> QuestionsResponse {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 500, message: "Mock Sample Questions Failed") }
        
        let questions = Array(repeating: Linker.Question(
            newSentence: "Sample question",
            type: "translation",
            hintText: "Sample hint",
            knowledgePointCompositeId: nil,
            knowledgePointId: 1,
            masteryLevel: 0.5
        ), count: count)
        return QuestionsResponse(questions: questions)
    }
    
    func submitGuestAnswer(request: GuestAnswerSubmissionRequest) async throws -> FeedbackResponse {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 500, message: "Mock Submit Answer Failed") }
        
        return FeedbackResponse(
            isGenerallyCorrect: true,
            overallSuggestion: "Good job!",
            errorAnalysis: [],
            didMasterReviewConcept: nil
        )
    }
    
    func getSampleKnowledgePoints() async throws -> [KnowledgePoint] {
        if mockDelay > 0 { try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000)) }
        if !shouldSucceed { throw APIError.serverError(statusCode: 500, message: "Mock Sample Knowledge Points Failed") }
        return [createMockKnowledgePoint()]
    }
    
    // MARK: - Mock數據創建輔助方法
    
    private func createMockAuthResponse() -> AuthResponse {
        return AuthResponse(
            user: createMockUser(),
            accessToken: "mock_access_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            expiresIn: 3600
        )
    }
    
    private func createMockUser() -> User {
        return User(
            id: 999,
            username: "mock_user",
            email: "mock@test.com",
            displayName: "Mock User",
            nativeLanguage: "中文",
            targetLanguage: "英文",
            learningLevel: "初級",
            totalLearningTime: 0,
            knowledgePointsCount: 0,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            lastLoginAt: nil
        )
    }
    
    private func createMockKnowledgePoint() -> KnowledgePoint {
        return KnowledgePoint(
            compositeId: nil,
            legacyId: 999,
            oldId: nil,
            category: "Mock Grammar",
            subcategory: "Mock Verb Tense",
            correctPhrase: "This is a mock sentence.",
            explanation: "Mock explanation",
            userContextSentence: "這是一個模擬句子。",
            incorrectPhraseInContext: "This are a mock sentence.",
            keyPointSummary: "Mock notes",
            masteryLevel: 0.5,
            mistakeCount: 1,
            correctCount: 2,
            nextReviewDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400)),
            isArchived: false,
            aiReviewNotes: "Mock AI notes",
            lastAiReviewDate: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    private func createMockResponse<T: Codable>(for endpoint: APIEndpoint, responseType: T.Type) throws -> T {
        // 這個方法可以擴展以支援更多特定的Mock回應
        throw APIError.unknownError
    }
}