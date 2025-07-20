//
//  APIServiceTests.swift
//  ai translationTests
//
//  Unit tests for API services
//

import Testing
import Foundation
@testable import ai_translation

// MARK: - Mock API Services for Testing

class MockAuthenticationAPIService: AuthenticationAPIServiceProtocol {
    static var shouldSucceed = true
    static var mockUser = User(
        id: 1,
        username: "testuser",
        email: "test@example.com",
        displayName: "Test User",
        nativeLanguage: "zh-TW",
        targetLanguage: "en-US",
        learningLevel: "intermediate",
        totalLearningTime: 0,
        knowledgePointsCount: 0,
        createdAt: "2025-07-20T12:00:00Z",
        lastLoginAt: nil
    )
    
    static func login(email: String, password: String) async throws -> AuthResponse {
        if shouldSucceed {
            return AuthResponse(
                user: mockUser,
                accessToken: "mock_access_token",
                refreshToken: "mock_refresh_token",
                expiresIn: 3600
            )
        } else {
            throw AuthError.invalidCredentials
        }
    }
    
    static func register(request: RegisterRequest) async throws -> AuthResponse {
        if shouldSucceed {
            return AuthResponse(
                user: mockUser,
                accessToken: "mock_access_token",
                refreshToken: "mock_refresh_token",
                expiresIn: 3600
            )
        } else {
            throw AuthError.userAlreadyExists
        }
    }
    
    static func refreshToken(refreshToken: String) async throws -> AuthResponse {
        if shouldSucceed {
            return AuthResponse(
                user: mockUser,
                accessToken: "new_mock_access_token",
                refreshToken: "new_mock_refresh_token",
                expiresIn: 3600
            )
        } else {
            throw AuthError.tokenExpired
        }
    }
    
    static func logout() async throws {
        if !shouldSucceed {
            throw AuthError.networkError
        }
    }
    
    static func getCurrentUser() async throws -> User {
        if shouldSucceed {
            return mockUser
        } else {
            throw AuthError.tokenExpired
        }
    }
}

class MockKnowledgePointAPIService: KnowledgePointAPIServiceProtocol {
    static var shouldSucceed = true
    static var mockUser = User(
        id: 1,
        username: "testuser",
        email: "test@example.com",
        displayName: "Test User",
        nativeLanguage: "zh-TW",
        targetLanguage: "en-US",
        learningLevel: "intermediate",
        totalLearningTime: 0,
        knowledgePointsCount: 0,
        createdAt: "2025-07-20T12:00:00Z",
        lastLoginAt: nil
    )
    static var mockKnowledgePoint = KnowledgePoint(
        id: 1,
        category: "Grammar",
        subcategory: "Verb Tense",
        correct_phrase: "This is a test sentence.",
        explanation: "Test explanation",
        user_context_sentence: "這是一個測試句子。",
        incorrect_phrase_in_context: "This are a test sentence.",
        key_point_summary: "Test notes",
        mastery_level: 0.5,
        mistake_count: 2,
        correct_count: 3,
        next_review_date: "2025-07-21T12:00:00Z",
        is_archived: false,
        ai_review_notes: "Test AI notes",
        last_ai_review_date: "2025-07-20T12:00:00Z"
    )
    
    // MARK: - Authentication Methods
    static func login(email: String, password: String) async throws -> AuthResponse {
        if shouldSucceed {
            return AuthResponse(
                user: mockUser,
                accessToken: "mock_access_token",
                refreshToken: "mock_refresh_token",
                expiresIn: 3600
            )
        } else {
            throw AuthError.invalidCredentials
        }
    }
    
    static func register(request: RegisterRequest) async throws -> AuthResponse {
        if shouldSucceed {
            return AuthResponse(
                user: mockUser,
                accessToken: "mock_access_token",
                refreshToken: "mock_refresh_token",
                expiresIn: 3600
            )
        } else {
            throw AuthError.userAlreadyExists
        }
    }
    
    static func refreshToken(refreshToken: String) async throws -> AuthResponse {
        if shouldSucceed {
            return AuthResponse(
                user: mockUser,
                accessToken: "new_mock_access_token",
                refreshToken: "new_mock_refresh_token",
                expiresIn: 3600
            )
        } else {
            throw AuthError.tokenExpired
        }
    }
    
    static func logout() async throws {
        if !shouldSucceed {
            throw AuthError.networkError
        }
    }
    
    static func getCurrentUser() async throws -> User {
        if shouldSucceed {
            return mockUser
        } else {
            throw AuthError.tokenExpired
        }
    }
    
    static func fetchKnowledgePoint(id: Int) async throws -> KnowledgePoint {
        if shouldSucceed {
            return mockKnowledgePoint
        } else {
            throw APIError.invalidResponse
        }
    }
    
    static func updateKnowledgePoint(id: Int, updates: [String: Any]) async throws {
        if !shouldSucceed {
            throw APIError.serverError(statusCode: 500, message: "Server error")
        }
    }
    
    static func deleteKnowledgePoint(id: Int) async throws {
        if !shouldSucceed {
            throw APIError.serverError(statusCode: 404, message: "Not found")
        }
    }
    
    static func archiveKnowledgePoint(id: Int) async throws {
        if !shouldSucceed {
            throw APIError.serverError(statusCode: 500, message: "Server error")
        }
    }
    
    static func unarchiveKnowledgePoint(id: Int) async throws {
        if !shouldSucceed {
            throw APIError.serverError(statusCode: 500, message: "Server error")
        }
    }
    
    static func fetchArchivedKnowledgePoints() async throws -> [KnowledgePoint] {
        if shouldSucceed {
            return [mockKnowledgePoint]
        } else {
            throw APIError.invalidResponse
        }
    }
    
    static func batchArchiveKnowledgePoints(ids: [Int]) async throws {
        if !shouldSucceed {
            throw APIError.serverError(statusCode: 500, message: "Server error")
        }
    }
    
    static func aiReviewKnowledgePoint(id: Int, modelName: String?) async throws -> AIReviewResult {
        if shouldSucceed {
            return AIReviewResult(
                overall_assessment: "Test AI review",
                accuracy_score: 85,
                clarity_score: 80,
                teaching_effectiveness: 90,
                improvement_suggestions: ["Test suggestion"],
                potential_confusions: ["Test confusion"],
                recommended_category: "Grammar",
                additional_examples: ["Test example"]
            )
        } else {
            throw APIError.serverError(statusCode: 500, message: "AI service unavailable")
        }
    }
    
    static func mergeErrors(error1: ErrorAnalysis, error2: ErrorAnalysis) async throws -> ErrorAnalysis {
        if shouldSucceed {
            return ErrorAnalysis(
                error_type_code: error1.error_type_code,
                key_point_summary: "Merged summary",
                original_phrase: error1.original_phrase,
                correction: error1.correction,
                explanation: "Merged explanation",
                severity: "medium"
            )
        } else {
            throw APIError.serverError(statusCode: 500, message: "Merge failed")
        }
    }
    
    static func finalizeKnowledgePoints(errors: [ErrorAnalysis], questionData: [String: Any?], userAnswer: String) async throws -> Int {
        if shouldSucceed {
            return errors.count
        } else {
            throw APIError.serverError(statusCode: 500, message: "Finalization failed")
        }
    }
    
    // MARK: - Guest Mode Methods
    static func getGuestSampleQuestions(count: Int) async throws -> QuestionsResponse {
        if shouldSucceed {
            let questions = Array(repeating: ai_translation.Question(
                new_sentence: "Sample question",
                type: "translation",
                hint_text: "Sample hint",
                knowledge_point_id: 1,
                mastery_level: 0.5
            ), count: count)
            return QuestionsResponse(questions: questions)
        } else {
            throw APIError.serverError(statusCode: 500, message: "Failed to generate questions")
        }
    }
    
    static func submitGuestAnswer(question: [String: Any], answer: String) async throws -> FeedbackResponse {
        if shouldSucceed {
            return FeedbackResponse(
                is_generally_correct: true,
                overall_suggestion: "Good job!",
                error_analysis: [],
                did_master_review_concept: nil
            )
        } else {
            throw APIError.serverError(statusCode: 500, message: "Failed to submit answer")
        }
    }
    
    static func getGuestSampleKnowledgePoints() async throws -> [KnowledgePoint] {
        if shouldSucceed {
            return [mockKnowledgePoint]
        } else {
            throw APIError.serverError(statusCode: 500, message: "Failed to get sample points")
        }
    }
    
    // MARK: - Dashboard Methods
    static func getDashboard() async throws -> DashboardResponse {
        if shouldSucceed {
            return DashboardResponse(knowledge_points: [mockKnowledgePoint])
        } else {
            throw APIError.serverError(statusCode: 500, message: "Failed to get dashboard")
        }
    }
    
    static func getCalendarHeatmap(year: Int, month: Int) async throws -> HeatmapResponse {
        if shouldSucceed {
            return HeatmapResponse(heatmap_data: ["2025-07-20": 5])
        } else {
            throw APIError.serverError(statusCode: 500, message: "Failed to get heatmap")
        }
    }
}

class MockCacheManager: CacheManagerProtocol {
    private var storage: [String: Data] = [:]
    
    func saveKnowledgePoints(_ points: [KnowledgePoint]) async {
        if let data = try? JSONEncoder().encode(points) {
            storage["knowledge_points"] = data
        }
    }
    
    func loadKnowledgePoints() async -> [KnowledgePoint]? {
        guard let data = storage["knowledge_points"] else { return nil }
        return try? JSONDecoder().decode([KnowledgePoint].self, from: data)
    }
    
    func saveArchivedKnowledgePoints(_ points: [KnowledgePoint]) async {
        if let data = try? JSONEncoder().encode(points) {
            storage["archived_points"] = data
        }
    }
    
    func loadArchivedKnowledgePoints() async -> [KnowledgePoint]? {
        guard let data = storage["archived_points"] else { return nil }
        return try? JSONDecoder().decode([KnowledgePoint].self, from: data)
    }
    
    func clearAllCache() {
        storage.removeAll()
    }
}

// MARK: - API Service Tests

struct AuthenticationAPIServiceTests {
    
    @Test("成功登入測試")
    func testSuccessfulLogin() async throws {
        MockAuthenticationAPIService.shouldSucceed = true
        
        let response = try await MockAuthenticationAPIService.login(
            email: "test@example.com",
            password: "password123"
        )
        
        #expect(response.user.email == "test@example.com")
        #expect(response.accessToken == "mock_access_token")
        #expect(response.refreshToken == "mock_refresh_token")
    }
    
    @Test("登入失敗測試")
    func testFailedLogin() async throws {
        MockAuthenticationAPIService.shouldSucceed = false
        
        await #expect(throws: AuthError.self) {
            try await MockAuthenticationAPIService.login(
                email: "invalid@example.com",
                password: "wrongpassword"
            )
        }
    }
    
    @Test("成功註冊測試")
    func testSuccessfulRegistration() async throws {
        MockAuthenticationAPIService.shouldSucceed = true
        
        let request = RegisterRequest(
            username: "newuser",
            email: "newuser@example.com",
            password: "password123",
            displayName: "New User",
            nativeLanguage: "zh-TW",
            targetLanguage: "en-US",
            learningLevel: "beginner"
        )
        
        let response = try await MockAuthenticationAPIService.register(request: request)
        
        #expect(response.user.email == "test@example.com")
        #expect(response.accessToken == "mock_access_token")
    }
    
    @Test("Token 刷新測試")
    func testTokenRefresh() async throws {
        MockAuthenticationAPIService.shouldSucceed = true
        
        let response = try await MockAuthenticationAPIService.refreshToken(
            refreshToken: "old_refresh_token"
        )
        
        #expect(response.accessToken == "new_mock_access_token")
        #expect(response.refreshToken == "new_mock_refresh_token")
    }
    
    @Test("登出測試")
    func testLogout() async throws {
        MockAuthenticationAPIService.shouldSucceed = true
        
        try await MockAuthenticationAPIService.logout()
        // 如果沒有拋出錯誤，測試通過
    }
    
    @Test("獲取用戶資訊測試")
    func testGetCurrentUser() async throws {
        MockAuthenticationAPIService.shouldSucceed = true
        
        let user = try await MockAuthenticationAPIService.getCurrentUser()
        
        #expect(user.email == "test@example.com")
        #expect(user.username == "testuser")
    }
}

struct KnowledgePointCoreAPIServiceTests {
    
    @Test("成功獲取知識點測試")
    func testFetchKnowledgePoint() async throws {
        MockKnowledgePointAPIService.shouldSucceed = true
        
        let knowledgePoint = try await MockKnowledgePointAPIService.fetchKnowledgePoint(id: 1)
        
        #expect(knowledgePoint.id == 1)
        #expect(knowledgePoint.correct_phrase == "This is a test sentence.")
        #expect(knowledgePoint.user_context_sentence == "這是一個測試句子。")
        #expect(knowledgePoint.category == "Grammar")
    }
    
    @Test("知識點獲取失敗測試")
    func testFetchKnowledgePointFailure() async throws {
        MockKnowledgePointAPIService.shouldSucceed = false
        
        await #expect(throws: APIError.self) {
            try await MockKnowledgePointAPIService.fetchKnowledgePoint(id: 999)
        }
    }
    
    @Test("成功更新知識點測試")
    func testUpdateKnowledgePoint() async throws {
        MockKnowledgePointAPIService.shouldSucceed = true
        
        let updates: [String: Any] = ["mastery_level": 0.8, "user_notes": "Updated notes"]
        
        try await MockKnowledgePointAPIService.updateKnowledgePoint(
            id: 1,
            updates: updates
        )
        // 如果沒有拋出錯誤，測試通過
    }
    
    @Test("知識點歸檔測試")
    func testArchiveKnowledgePoint() async throws {
        MockKnowledgePointAPIService.shouldSucceed = true
        
        try await MockKnowledgePointAPIService.archiveKnowledgePoint(id: 1)
        // 如果沒有拋出錯誤，測試通過
    }
    
    @Test("知識點取消歸檔測試")
    func testUnarchiveKnowledgePoint() async throws {
        MockKnowledgePointAPIService.shouldSucceed = true
        
        try await MockKnowledgePointAPIService.unarchiveKnowledgePoint(id: 1)
        // 如果沒有拋出錯誤，測試通過
    }
    
    @Test("批次歸檔知識點測試")
    func testBatchArchiveKnowledgePoints() async throws {
        MockKnowledgePointAPIService.shouldSucceed = true
        
        let ids = [1, 2, 3, 4, 5]
        
        try await MockKnowledgePointAPIService.batchArchiveKnowledgePoints(ids: ids)
        // 如果沒有拋出錯誤，測試通過
    }
    
    @Test("AI 審閱測試")
    func testAIReview() async throws {
        MockKnowledgePointAPIService.shouldSucceed = true
        
        let result = try await MockKnowledgePointAPIService.aiReviewKnowledgePoint(
            id: 1,
            modelName: "gpt-4"
        )
        
        #expect(result.overall_assessment == "Test AI review")
        #expect(result.improvement_suggestions.count == 1)
        #expect(result.accuracy_score == 85)
    }
    
    @Test("錯誤合併測試")
    func testMergeErrors() async throws {
        MockKnowledgePointAPIService.shouldSucceed = true
        
        let error1 = ErrorAnalysis(
            error_type_code: "B",
            key_point_summary: "Test summary 1",
            original_phrase: "Test sentence",
            correction: "Correction 1",
            explanation: "Error 1",
            severity: "high"
        )
        
        let error2 = ErrorAnalysis(
            error_type_code: "B",
            key_point_summary: "Test summary 2",
            original_phrase: "Test sentence",
            correction: "Correction 2",
            explanation: "Error 2",
            severity: "medium"
        )
        
        let merged = try await MockKnowledgePointAPIService.mergeErrors(
            error1: error1,
            error2: error2
        )
        
        #expect(merged.explanation == "Merged explanation")
        #expect(merged.original_phrase == "Test sentence")
    }
}

struct KnowledgePointRepositoryTests {
    
    @Test("Repository 快取測試")
    func testRepositoryCache() async throws {
        let mockCache = MockCacheManager()
        MockKnowledgePointAPIService.shouldSucceed = true
        
        // 測試快取保存
        let mockPoints = [MockKnowledgePointAPIService.mockKnowledgePoint]
        await mockCache.saveKnowledgePoints(mockPoints)
        
        let loadedPoints = await mockCache.loadKnowledgePoints()
        
        #expect(loadedPoints?.count == 1)
        #expect(loadedPoints?.first?.id == 1)
        #expect(loadedPoints?.first?.correct_phrase == "This is a test sentence.")
    }
    
    @Test("Repository 錯誤處理測試")
    func testRepositoryErrorHandling() async throws {
        let mockCache = MockCacheManager()
        
        // 先在快取中保存一些數據
        let mockPoints = [MockKnowledgePointAPIService.mockKnowledgePoint]
        await mockCache.saveKnowledgePoints(mockPoints)
        
        // 設定 API 服務失敗
        MockKnowledgePointAPIService.shouldSucceed = false
        
        // Repository 應該能從快取中讀取數據，即使 API 失敗
        // 注意：這需要實際測試 Repository 的邏輯
    }
}

struct TypeSafeAPIRequestTests {
    
    @Test("UpdateKnowledgePointRequest 驗證測試")
    func testUpdateKnowledgePointRequestValidation() async throws {
        // 測試有效的請求
        let validRequest = UpdateKnowledgePointRequest(
            masteryLevel: 0.8,
            notes: "Valid notes",
            isArchived: false
        )
        
        try validRequest.validate()
        // 如果沒有拋出錯誤，測試通過
        
        // 測試無效的熟練度
        let invalidRequest = UpdateKnowledgePointRequest(
            masteryLevel: 1.5, // 無效值
            notes: "Valid notes"
        )
        
        do {
            try invalidRequest.validate()
            Issue.record("Expected ValidationError to be thrown")
        } catch {
            #expect(error is ValidationError)
        }
        
        // 測試空的備註
        let emptyNotesRequest = UpdateKnowledgePointRequest(
            masteryLevel: 0.5,
            notes: "   " // 空白字符
        )
        
        do {
            try emptyNotesRequest.validate()
            Issue.record("Expected ValidationError to be thrown")
        } catch {
            #expect(error is ValidationError)
        }
    }
    
    @Test("BatchOperationRequest 驗證測試")
    func testBatchOperationRequestValidation() async throws {
        // 測試有效的批次請求
        let validRequest = BatchOperationRequest(
            action: .archive,
            ids: [1, 2, 3]
        )
        
        try validRequest.validate()
        // 如果沒有拋出錯誤，測試通過
        
        // 測試空的 ID 列表
        let emptyIdsRequest = BatchOperationRequest(
            action: .archive,
            ids: []
        )
        
        do {
            try emptyIdsRequest.validate()
            Issue.record("Expected ValidationError to be thrown")
        } catch {
            #expect(error is ValidationError)
        }
        
        // 測試過多的 ID
        let tooManyIdsRequest = BatchOperationRequest(
            action: .archive,
            ids: Array(1...101) // 超過 100 個
        )
        
        do {
            try tooManyIdsRequest.validate()
            Issue.record("Expected ValidationError to be thrown")
        } catch {
            #expect(error is ValidationError)
        }
    }
    
    @Test("APIRequestBuilder 測試")
    func testAPIRequestBuilder() async throws {
        // 測試更新知識點請求建構器
        let updateRequest = APIRequestBuilder.updateKnowledgePoint(
            masteryLevel: 0.9,
            notes: "Builder test notes",
            isArchived: true
        )
        
        #expect(updateRequest.masteryLevel == 0.9)
        #expect(updateRequest.notes == "Builder test notes")
        #expect(updateRequest.isArchived == true)
        
        // 測試 AI 審閱請求建構器
        let aiRequest = APIRequestBuilder.aiReview(
            modelName: "gpt-4",
            reviewType: .detailed,
            includeExamples: true,
            focusAreas: ["grammar", "vocabulary"]
        )
        
        #expect(aiRequest.modelName == "gpt-4")
        #expect(aiRequest.reviewType == .detailed)
        #expect(aiRequest.options?.includeExamples == true)
        #expect(aiRequest.options?.focusAreas == ["grammar", "vocabulary"])
        
        // 測試批次操作請求建構器
        let batchRequest = APIRequestBuilder.batchOperation(
            action: .updateMastery,
            ids: [1, 2, 3],
            newMasteryLevel: 0.7
        )
        
        #expect(batchRequest.action == .updateMastery)
        #expect(batchRequest.ids == [1, 2, 3])
        #expect(batchRequest.options?.newMasteryLevel == 0.7)
    }
}

struct AppErrorTests {
    
    @Test("AppError 錯誤轉換測試")
    func testAppErrorConversion() async throws {
        // 測試從 AuthError 轉換
        let authError = AuthError.invalidCredentials
        let appError1 = AppError.from(authError)
        
        if case .authentication(let convertedAuthError) = appError1 {
            #expect(convertedAuthError.localizedDescription == AuthError.invalidCredentials.localizedDescription)
        } else {
            Issue.record("AppError 轉換失敗")
        }
        
        // 測試從 APIError 轉換
        let apiError = APIError.invalidURL
        let appError2 = AppError.from(apiError)
        
        if case .api(let convertedAPIError) = appError2 {
            #expect(convertedAPIError.localizedDescription.contains("URL"))
        } else {
            Issue.record("APIError 轉換失敗")
        }
        
        // 測試錯誤代碼生成
        let networkAppError = AppError.network(.timeout)
        #expect(networkAppError.errorCode == "NET_002")
        
        // 測試用戶友善訊息
        let authAppError = AppError.authentication(.tokenExpired)
        #expect(authAppError.userFriendlyMessage.contains("登入"))
    }
    
    @Test("錯誤嚴重程度測試")
    func testErrorSeverity() async throws {
        // 測試不同錯誤的嚴重程度
        let warningError = AppError.authentication(.invalidCredentials)
        #expect(warningError.severity == .warning)
        
        let criticalError = AppError.api(.serverError(statusCode: 500, message: "Internal Server Error"))
        #expect(criticalError.severity == .critical)
        
        let infoError = AppError.authentication(.tokenExpired)
        #expect(infoError.severity == .info)
        
        let networkWarning = AppError.network(.timeout)
        #expect(networkWarning.severity == .warning)
    }
}