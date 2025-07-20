//
//  ViewModelTests.swift
//  ai translationTests
//
//  Unit tests for ViewModels with dependency injection
//

import Testing
import Foundation
@testable import ai_translation

// MARK: - Mock Dependencies

class MockAuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    var shouldLoginSucceed = true
    var shouldRegisterSucceed = true
    
    func login(email: String, password: String) async throws {
        if shouldLoginSucceed {
            currentUser = User(
                id: 1,
                username: "testuser",
                email: email,
                displayName: "Test User",
                nativeLanguage: "zh-TW",
                targetLanguage: "en-US",
                learningLevel: "intermediate",
                totalLearningTime: 0,
                knowledgePointsCount: 0,
                createdAt: "2025-07-20T12:00:00Z",
                lastLoginAt: nil
            )
            isAuthenticated = true
        } else {
            throw AuthError.invalidCredentials
        }
    }
    
    func register(email: String, password: String, username: String) async throws {
        if shouldRegisterSucceed {
            currentUser = User(
                id: 2,
                username: username,
                email: email,
                displayName: username,
                nativeLanguage: "zh-TW",
                targetLanguage: "en-US",
                learningLevel: "beginner",
                totalLearningTime: 0,
                knowledgePointsCount: 0,
                createdAt: "2025-07-20T12:00:00Z",
                lastLoginAt: nil
            )
            isAuthenticated = true
        } else {
            throw AuthError.userAlreadyExists
        }
    }
    
    func logout() async {
        currentUser = nil
        isAuthenticated = false
    }
}

class MockDashboardViewModel: ObservableObject {
    @Published var knowledgePoints: [KnowledgePoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var stats = DashboardStats(
        totalPoints: 0,
        masteredPoints: 0,
        inProgressPoints: 0,
        streakDays: 0
    )
    
    var shouldLoadSucceed = true
    var mockKnowledgePoints: [KnowledgePoint] = []
    
    init() {
        setupMockData()
    }
    
    private func setupMockData() {
        mockKnowledgePoints = [
            KnowledgePoint(
                id: 1,
                category: "Grammar",
                subcategory: "Verb Tense",
                correct_phrase: "Test sentence 1",
                explanation: "Test explanation 1",
                user_context_sentence: "測試句子 1",
                incorrect_phrase_in_context: "Test sentence 1 error",
                key_point_summary: "Test notes 1",
                mastery_level: 0.3,
                mistake_count: 3,
                correct_count: 2,
                next_review_date: "2025-07-21T12:00:00Z",
                is_archived: false,
                ai_review_notes: "Test AI notes 1",
                last_ai_review_date: "2025-07-20T12:00:00Z"
            ),
            KnowledgePoint(
                id: 2,
                category: "Vocabulary",
                subcategory: "Word Choice",
                correct_phrase: "Test sentence 2",
                explanation: "Test explanation 2",
                user_context_sentence: "測試句子 2",
                incorrect_phrase_in_context: "Test sentence 2 error",
                key_point_summary: "Test notes 2",
                mastery_level: 0.8,
                mistake_count: 1,
                correct_count: 5,
                next_review_date: "2025-07-22T12:00:00Z",
                is_archived: false,
                ai_review_notes: "Test AI notes 2",
                last_ai_review_date: "2025-07-20T12:00:00Z"
            ),
            KnowledgePoint(
                id: 3,
                category: "Grammar",
                subcategory: "Preposition",
                correct_phrase: "Test sentence 3",
                explanation: "Test explanation 3",
                user_context_sentence: "測試句子 3",
                incorrect_phrase_in_context: "Test sentence 3 error",
                key_point_summary: nil,
                mastery_level: 1.0,
                mistake_count: 0,
                correct_count: 10,
                next_review_date: "2025-07-25T12:00:00Z",
                is_archived: true,
                ai_review_notes: "Test AI notes 3",
                last_ai_review_date: "2025-07-20T12:00:00Z"
            )
        ]
    }
    
    func loadKnowledgePoints() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // 模擬網路延遲
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
        
        await MainActor.run {
            if shouldLoadSucceed {
                knowledgePoints = mockKnowledgePoints.filter { !($0.is_archived ?? false) }
                updateStats()
            } else {
                errorMessage = "載入失敗"
            }
            isLoading = false
        }
    }
    
    func refreshData() async {
        await loadKnowledgePoints()
    }
    
    private func updateStats() {
        let activePoints = knowledgePoints
        stats = DashboardStats(
            totalPoints: activePoints.count,
            masteredPoints: activePoints.filter { $0.mastery_level >= 0.8 }.count,
            inProgressPoints: activePoints.filter { $0.mastery_level < 0.8 }.count,
            streakDays: 7 // 模擬數據
        )
    }
    
    func archiveKnowledgePoint(_ knowledgePoint: KnowledgePoint) async {
        await MainActor.run {
            if let index = knowledgePoints.firstIndex(where: { $0.id == knowledgePoint.id }) {
                knowledgePoints.remove(at: index)
                updateStats()
            }
        }
    }
    
    func deleteKnowledgePoint(_ knowledgePoint: KnowledgePoint) async {
        await MainActor.run {
            if let index = knowledgePoints.firstIndex(where: { $0.id == knowledgePoint.id }) {
                knowledgePoints.remove(at: index)
                updateStats()
            }
        }
    }
    
    func updateMasteryLevel(for knowledgePoint: KnowledgePoint, newLevel: Double) async {
        await MainActor.run {
            if let index = knowledgePoints.firstIndex(where: { $0.id == knowledgePoint.id }) {
                // 創建更新後的知識點（由於 KnowledgePoint 可能是 struct）
                var updatedPoint = knowledgePoints[index]
                // 注意：這裡需要確認 KnowledgePoint 的實際實現
                // 如果 mastery_level 是可變的，則直接賦值
                // 否則需要創建新的實例
                knowledgePoints[index] = updatedPoint
                updateStats()
            }
        }
    }
}

class MockAITutorViewModel: ObservableObject {
    @Published var currentQuestion: Question?
    @Published var userAnswer = ""
    @Published var feedback: FeedbackResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sessionStats = SessionStats(
        questionsAnswered: 0,
        correctAnswers: 0,
        totalScore: 0
    )
    
    var shouldGenerateQuestionSucceed = true
    var shouldSubmitAnswerSucceed = true
    
    func generateNewQuestion() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // 模擬網路延遲
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 秒
        
        await MainActor.run {
            if shouldGenerateQuestionSucceed {
                currentQuestion = Question(
                    id: "test_question_\(Int.random(in: 1...1000))",
                    type: .translation,
                    sentence: "This is a test sentence for translation.",
                    hint: "Focus on verb tense",
                    difficulty: .intermediate,
                    expectedAnswer: "這是一個用於翻譯的測試句子。"
                )
            } else {
                errorMessage = "無法生成新題目"
            }
            isLoading = false
        }
    }
    
    func submitAnswer() async {
        guard let question = currentQuestion else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        // 模擬網路延遲
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 秒
        
        await MainActor.run {
            if shouldSubmitAnswerSucceed {
                // 簡單的答案評分邏輯
                let isCorrect = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() == question.expectedAnswer?.lowercased()
                
                feedback = FeedbackResponse(
                    is_generally_correct: isCorrect,
                    overall_suggestion: isCorrect ? "答案正確！" : "答案需要改進",
                    error_analysis: isCorrect ? [] : [
                        ErrorAnalysis(
                            error_type_code: "B",
                            key_point_summary: "動詞時態錯誤",
                            original_phrase: "test phrase",
                            correction: "corrected phrase",
                            explanation: "注意動詞時態",
                            severity: "medium"
                        )
                    ],
                    did_master_review_concept: nil
                )
                
                // 更新會話統計
                sessionStats.questionsAnswered += 1
                if isCorrect {
                    sessionStats.correctAnswers += 1
                }
                let score = isCorrect ? 100 : 60
                sessionStats.totalScore += score
                
                // 清除用戶答案準備下一題
                userAnswer = ""
            } else {
                errorMessage = "提交答案失敗"
            }
            isLoading = false
        }
    }
    
    func resetSession() {
        Task { @MainActor in
            currentQuestion = nil
            userAnswer = ""
            feedback = nil
            errorMessage = nil
            sessionStats = SessionStats(
                questionsAnswered: 0,
                correctAnswers: 0,
                totalScore: 0
            )
        }
    }
}

// MARK: - ViewModel Tests

struct DashboardViewModelTests {
    
    @Test("DashboardViewModel 載入測試")
    func testDashboardViewModelLoading() async throws {
        let viewModel = MockDashboardViewModel()
        viewModel.shouldLoadSucceed = true
        
        // 測試初始狀態
        #expect(viewModel.knowledgePoints.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
        
        // 測試載入知識點
        await viewModel.loadKnowledgePoints()
        
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.knowledgePoints.count == 2) // 只有非歸檔的
        #expect(viewModel.stats.totalPoints == 2)
        #expect(viewModel.stats.masteredPoints == 1) // mastery_level >= 0.8
        #expect(viewModel.stats.inProgressPoints == 1) // mastery_level < 0.8
    }
    
    @Test("DashboardViewModel 載入失敗測試")
    func testDashboardViewModelLoadingFailure() async throws {
        let viewModel = MockDashboardViewModel()
        viewModel.shouldLoadSucceed = false
        
        await viewModel.loadKnowledgePoints()
        
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == "載入失敗")
        #expect(viewModel.knowledgePoints.isEmpty)
    }
    
    @Test("DashboardViewModel 歸檔知識點測試")
    func testDashboardViewModelArchive() async throws {
        let viewModel = MockDashboardViewModel()
        viewModel.shouldLoadSucceed = true
        
        // 先載入數據
        await viewModel.loadKnowledgePoints()
        let initialCount = viewModel.knowledgePoints.count
        
        // 歸檔第一個知識點
        let firstPoint = viewModel.knowledgePoints.first!
        await viewModel.archiveKnowledgePoint(firstPoint)
        
        #expect(viewModel.knowledgePoints.count == initialCount - 1)
        #expect(viewModel.stats.totalPoints == initialCount - 1)
    }
    
    @Test("DashboardViewModel 刪除知識點測試")
    func testDashboardViewModelDelete() async throws {
        let viewModel = MockDashboardViewModel()
        viewModel.shouldLoadSucceed = true
        
        // 先載入數據
        await viewModel.loadKnowledgePoints()
        let initialCount = viewModel.knowledgePoints.count
        
        // 刪除第一個知識點
        let firstPoint = viewModel.knowledgePoints.first!
        await viewModel.deleteKnowledgePoint(firstPoint)
        
        #expect(viewModel.knowledgePoints.count == initialCount - 1)
        #expect(viewModel.stats.totalPoints == initialCount - 1)
    }
    
    @Test("DashboardViewModel 統計計算測試")
    func testDashboardViewModelStatsCalculation() async throws {
        let viewModel = MockDashboardViewModel()
        viewModel.shouldLoadSucceed = true
        
        await viewModel.loadKnowledgePoints()
        
        // 驗證統計數據計算正確
        let masteredCount = viewModel.knowledgePoints.filter { $0.mastery_level >= 0.8 }.count
        let inProgressCount = viewModel.knowledgePoints.filter { $0.mastery_level < 0.8 }.count
        
        #expect(viewModel.stats.masteredPoints == masteredCount)
        #expect(viewModel.stats.inProgressPoints == inProgressCount)
        #expect(viewModel.stats.totalPoints == masteredCount + inProgressCount)
    }
}

struct AITutorViewModelTests {
    
    @Test("AITutorViewModel 生成題目測試")
    func testAITutorViewModelQuestionGeneration() async throws {
        let viewModel = MockAITutorViewModel()
        viewModel.shouldGenerateQuestionSucceed = true
        
        // 測試初始狀態
        #expect(viewModel.currentQuestion == nil)
        #expect(!viewModel.isLoading)
        
        // 生成新題目
        await viewModel.generateNewQuestion()
        
        #expect(!viewModel.isLoading)
        #expect(viewModel.currentQuestion != nil)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.currentQuestion?.sentence == "This is a test sentence for translation.")
    }
    
    @Test("AITutorViewModel 生成題目失敗測試")
    func testAITutorViewModelQuestionGenerationFailure() async throws {
        let viewModel = MockAITutorViewModel()
        viewModel.shouldGenerateQuestionSucceed = false
        
        await viewModel.generateNewQuestion()
        
        #expect(!viewModel.isLoading)
        #expect(viewModel.currentQuestion == nil)
        #expect(viewModel.errorMessage == "無法生成新題目")
    }
    
    @Test("AITutorViewModel 提交正確答案測試")
    func testAITutorViewModelCorrectAnswer() async throws {
        let viewModel = MockAITutorViewModel()
        viewModel.shouldGenerateQuestionSucceed = true
        viewModel.shouldSubmitAnswerSucceed = true
        
        // 先生成題目
        await viewModel.generateNewQuestion()
        
        // 設定正確答案
        await MainActor.run {
            viewModel.userAnswer = viewModel.currentQuestion?.expectedAnswer ?? ""
        }
        
        // 提交答案
        await viewModel.submitAnswer()
        
        #expect(!viewModel.isLoading)
        #expect(viewModel.feedback?.is_generally_correct == true)
        #expect(viewModel.feedback?.error_analysis.isEmpty == true)
        #expect(viewModel.sessionStats.questionsAnswered == 1)
        #expect(viewModel.sessionStats.correctAnswers == 1)
        #expect(viewModel.userAnswer.isEmpty) // 應該被清空
    }
    
    @Test("AITutorViewModel 提交錯誤答案測試")
    func testAITutorViewModelIncorrectAnswer() async throws {
        let viewModel = MockAITutorViewModel()
        viewModel.shouldGenerateQuestionSucceed = true
        viewModel.shouldSubmitAnswerSucceed = true
        
        // 先生成題目
        await viewModel.generateNewQuestion()
        
        // 設定錯誤答案
        await MainActor.run {
            viewModel.userAnswer = "Wrong answer"
        }
        
        // 提交答案
        await viewModel.submitAnswer()
        
        #expect(!viewModel.isLoading)
        #expect(viewModel.feedback?.is_generally_correct == false)
        #expect(!viewModel.feedback!.error_analysis.isEmpty)
        #expect(viewModel.sessionStats.questionsAnswered == 1)
        #expect(viewModel.sessionStats.correctAnswers == 0)
        #expect(!viewModel.feedback!.error_analysis.isEmpty)
    }
    
    @Test("AITutorViewModel 會話重置測試")
    func testAITutorViewModelSessionReset() async throws {
        let viewModel = MockAITutorViewModel()
        
        // 先設定一些狀態
        await viewModel.generateNewQuestion()
        await MainActor.run {
            viewModel.userAnswer = "Some answer"
        }
        await viewModel.submitAnswer()
        
        // 重置會話
        viewModel.resetSession()
        
        // 等待主執行緒更新
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 秒
        
        await MainActor.run {
            #expect(viewModel.currentQuestion == nil)
            #expect(viewModel.userAnswer.isEmpty)
            #expect(viewModel.feedback == nil)
            #expect(viewModel.errorMessage == nil)
            #expect(viewModel.sessionStats.questionsAnswered == 0)
            #expect(viewModel.sessionStats.correctAnswers == 0)
            #expect(viewModel.sessionStats.totalScore == 0)
        }
    }
    
    @Test("AITutorViewModel 提交答案失敗測試")
    func testAITutorViewModelSubmitAnswerFailure() async throws {
        let viewModel = MockAITutorViewModel()
        viewModel.shouldGenerateQuestionSucceed = true
        viewModel.shouldSubmitAnswerSucceed = false
        
        // 先生成題目
        await viewModel.generateNewQuestion()
        
        // 設定答案
        await MainActor.run {
            viewModel.userAnswer = "Test answer"
        }
        
        // 提交答案
        await viewModel.submitAnswer()
        
        #expect(!viewModel.isLoading)
        #expect(viewModel.feedback == nil)
        #expect(viewModel.errorMessage == "提交答案失敗")
    }
}

struct AuthenticationManagerTests {
    
    @Test("AuthenticationManager 成功登入測試")
    func testAuthenticationManagerLogin() async throws {
        let authManager = MockAuthenticationManager()
        authManager.shouldLoginSucceed = true
        
        // 測試初始狀態
        #expect(authManager.currentUser == nil)
        #expect(!authManager.isAuthenticated)
        
        // 執行登入
        try await authManager.login(email: "test@example.com", password: "password123")
        
        #expect(authManager.currentUser != nil)
        #expect(authManager.isAuthenticated)
        #expect(authManager.currentUser?.email == "test@example.com")
    }
    
    @Test("AuthenticationManager 登入失敗測試")
    func testAuthenticationManagerLoginFailure() async throws {
        let authManager = MockAuthenticationManager()
        authManager.shouldLoginSucceed = false
        
        await #expect(throws: AuthError.self) {
            try await authManager.login(email: "test@example.com", password: "wrongpassword")
        }
        
        #expect(authManager.currentUser == nil)
        #expect(!authManager.isAuthenticated)
    }
    
    @Test("AuthenticationManager 成功註冊測試")
    func testAuthenticationManagerRegister() async throws {
        let authManager = MockAuthenticationManager()
        authManager.shouldRegisterSucceed = true
        
        try await authManager.register(
            email: "newuser@example.com",
            password: "password123",
            username: "newuser"
        )
        
        #expect(authManager.currentUser != nil)
        #expect(authManager.isAuthenticated)
        #expect(authManager.currentUser?.email == "newuser@example.com")
        #expect(authManager.currentUser?.username == "newuser")
    }
    
    @Test("AuthenticationManager 註冊失敗測試")
    func testAuthenticationManagerRegisterFailure() async throws {
        let authManager = MockAuthenticationManager()
        authManager.shouldRegisterSucceed = false
        
        await #expect(throws: AuthError.self) {
            try await authManager.register(
                email: "existing@example.com",
                password: "password123",
                username: "existinguser"
            )
        }
        
        #expect(authManager.currentUser == nil)
        #expect(!authManager.isAuthenticated)
    }
    
    @Test("AuthenticationManager 登出測試")
    func testAuthenticationManagerLogout() async throws {
        let authManager = MockAuthenticationManager()
        authManager.shouldLoginSucceed = true
        
        // 先登入
        try await authManager.login(email: "test@example.com", password: "password123")
        #expect(authManager.isAuthenticated)
        
        // 然後登出
        await authManager.logout()
        
        #expect(authManager.currentUser == nil)
        #expect(!authManager.isAuthenticated)
    }
}

// MARK: - 支援型別定義

struct DashboardStats {
    let totalPoints: Int
    let masteredPoints: Int
    let inProgressPoints: Int
    let streakDays: Int
}

struct Question {
    let id: String
    let type: QuestionType
    let sentence: String
    let hint: String?
    let difficulty: Difficulty
    let expectedAnswer: String?
    
    enum QuestionType {
        case translation
        case correction
        case completion
    }
    
    enum Difficulty {
        case beginner
        case intermediate
        case advanced
    }
}

struct SessionStats {
    var questionsAnswered: Int
    var correctAnswers: Int
    var totalScore: Int
}