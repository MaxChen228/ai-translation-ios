// AITutorViewModel.swift - AI 家教業務邏輯管理

import Foundation
import SwiftUI

@MainActor
class AITutorViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentQuestions: [Question] = []
    @Published var currentQuestionIndex = 0
    @Published var userAnswer = ""
    @Published var feedback: FeedbackResponse?
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var showingResults = false
    @Published var errorMessage: String?
    @Published var tutorState: TutorState = .initial
    
    // MARK: - 同步狀態
    @Published var syncStatus: SyncStatus = .idle
    @Published var syncedKnowledgePointsCount: Int = 0
    
    enum SyncStatus {
        case idle
        case syncing
        case completed
        case failed(Error)
    }
    
    // MARK: - Session Management
    @Published var sessionProgress: SessionProgress = SessionProgress()
    @Published var sessionStats: SessionStats = SessionStats()
    
    // MARK: - Computed Properties
    var currentQuestion: Question? {
        guard currentQuestionIndex < currentQuestions.count else { return nil }
        return currentQuestions[currentQuestionIndex]
    }
    
    var hasNextQuestion: Bool {
        currentQuestionIndex < currentQuestions.count - 1
    }
    
    var hasPreviousQuestion: Bool {
        currentQuestionIndex > 0
    }
    
    var progressPercentage: Double {
        guard !currentQuestions.isEmpty else { return 0.0 }
        return Double(currentQuestionIndex + 1) / Double(currentQuestions.count) * 100
    }
    
    // MARK: - Dependencies
    private let apiService: UnifiedAPIServiceProtocol
    private var sessionManager: SessionManager?
    
    // MARK: - Initialization
    init(apiService: UnifiedAPIServiceProtocol = UnifiedAPIService.shared) {
        self.apiService = apiService
    }
    
    // MARK: - SessionManager Setup
    func setupSessionManager(_ sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }
    
    // MARK: - Public Methods
    
    /// 開始新的學習會話
    func startNewSession() async {
        isLoading = true
        errorMessage = nil
        tutorState = .loading
        
        do {
            let questionsResponse = try await apiService.getSampleQuestions(count: 3)
            let questions = questionsResponse.questions
            currentQuestions = questions
            sessionManager?.startNewSession(questions: questions)
            resetSession()
            tutorState = .active
            
        } catch {
            errorMessage = "載入題目失敗：\(error.localizedDescription)"
            tutorState = .error
            print("AI Tutor 載入錯誤: \(error)")
        }
        
        isLoading = false
    }
    
    /// 提交用戶答案
    func submitAnswer() async {
        guard let question = currentQuestion else { return }
        guard !userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "請輸入答案"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            let questionDict: [String: Any] = [
                "id": question.id.uuidString,
                "new_sentence": question.newSentence,
                "type": question.type
            ]
            let feedbackResponse = try await apiService.submitGuestAnswer(
                question: questionDict,
                answer: userAnswer
            )
            
            feedback = feedbackResponse
            
            // 更新會話管理器
            sessionManager?.updateQuestion(
                id: question.id,
                userAnswer: userAnswer,
                feedback: feedbackResponse
            )
            
            // 更新統計
            updateSessionStats(with: feedbackResponse)
            
            tutorState = .reviewingAnswer
            
        } catch {
            errorMessage = "提交答案失敗：\(error.localizedDescription)"
            print("提交答案錯誤: \(error)")
        }
        
        isSubmitting = false
    }
    
    /// 進入下一題
    func nextQuestion() {
        if hasNextQuestion {
            currentQuestionIndex += 1
            resetCurrentQuestion()
            tutorState = .active
        } else {
            Task {
                await completeSession()
            }
        }
    }
    
    /// 返回上一題
    func previousQuestion() {
        if hasPreviousQuestion {
            currentQuestionIndex -= 1
            resetCurrentQuestion()
            tutorState = .active
        }
    }
    
    /// 完成學習會話
    func completeSession() async {
        sessionProgress.isCompleted = true
        sessionProgress.completedAt = Date()
        tutorState = .completed
        
        // 自動同步知識點到伺服器
        await syncKnowledgePointsToServer()
        
        showingResults = true
    }
    
    /// 重新開始會話
    func restartSession() {
        resetSession()
        tutorState = .active
        showingResults = false
    }
    
    /// 清除錯誤訊息
    func clearError() {
        errorMessage = nil
    }
    
    /// 跳過當前題目
    func skipQuestion() {
        // 記錄跳過的題目
        sessionStats.skippedQuestions += 1
        nextQuestion()
    }
    
    // MARK: - Private Methods
    
    private func resetSession() {
        currentQuestionIndex = 0
        sessionProgress = SessionProgress()
        sessionStats = SessionStats()
        resetCurrentQuestion()
    }
    
    private func resetCurrentQuestion() {
        userAnswer = ""
        feedback = nil
        errorMessage = nil
    }
    
    private func updateSessionStats(with feedback: FeedbackResponse) {
        sessionStats.totalAnswered += 1
        
        // 根據回饋評分更新統計
        let score = calculateScore(from: feedback)
        sessionStats.totalScore += score
        
        if score >= 0.8 {
            sessionStats.correctAnswers += 1
        }
        
        sessionStats.averageScore = sessionStats.totalScore / Double(sessionStats.totalAnswered)
        
        // 更新進度
        sessionProgress.answeredQuestions += 1
        sessionProgress.lastUpdated = Date()
    }
    
    private func calculateScore(from feedback: FeedbackResponse) -> Double {
        // 根據錯誤數量和嚴重程度計算分數
        let totalErrors = feedback.errorAnalysis.count
        
        if totalErrors == 0 {
            return 1.0 // 完美分數
        }
        
        let severityWeights: [String: Double] = [
            "low": 0.1,
            "medium": 0.2,
            "high": 0.3,
            "critical": 0.5
        ]
        
        let totalDeduction = feedback.errorAnalysis.reduce(0.0) { total, error in
            total + (severityWeights[error.severity] ?? 0.2)
        }
        
        return max(0.0, 1.0 - totalDeduction)
    }
}

// MARK: - Supporting Types

extension AITutorViewModel {
    enum TutorState {
        case initial
        case loading
        case active
        case reviewingAnswer
        case completed
        case error
        
        var description: String {
            switch self {
            case .initial: return "準備開始"
            case .loading: return "載入中"
            case .active: return "答題中"
            case .reviewingAnswer: return "查看結果"
            case .completed: return "已完成"
            case .error: return "發生錯誤"
            }
        }
    }
    
    struct SessionProgress {
        var startedAt = Date()
        var lastUpdated = Date()
        var completedAt: Date?
        var answeredQuestions = 0
        var isCompleted = false
        
        var duration: TimeInterval {
            let endTime = completedAt ?? Date()
            return endTime.timeIntervalSince(startedAt)
        }
        
        var formattedDuration: String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    struct SessionStats {
        var totalAnswered = 0
        var correctAnswers = 0
        var skippedQuestions = 0
        var totalScore: Double = 0.0
        var averageScore: Double = 0.0
        
        var accuracy: Double {
            guard totalAnswered > 0 else { return 0.0 }
            return Double(correctAnswers) / Double(totalAnswered) * 100
        }
        
        var completionRate: Double {
            let totalQuestions = totalAnswered + skippedQuestions
            guard totalQuestions > 0 else { return 0.0 }
            return Double(totalAnswered) / Double(totalQuestions) * 100
        }
    }
}

// MARK: - Session Management Integration
extension AITutorViewModel {
    /// 從會話管理器恢復狀態
    func restoreFromSessionManager() {
        let sessionQuestions = sessionManager?.sessionQuestions ?? []
        
        if !sessionQuestions.isEmpty {
            currentQuestions = sessionQuestions.map { $0.question }
            
            // 找到最後一個已完成的題目
            if let lastCompletedIndex = sessionQuestions.lastIndex(where: { $0.isCompleted }) {
                currentQuestionIndex = min(lastCompletedIndex + 1, sessionQuestions.count - 1)
            }
            
            // 如果當前題目已有答案，載入它
            if currentQuestionIndex < sessionQuestions.count {
                let currentSessionQuestion = sessionQuestions[currentQuestionIndex]
                userAnswer = currentSessionQuestion.userAnswer ?? ""
                feedback = currentSessionQuestion.feedback
                
                if feedback != nil {
                    tutorState = .reviewingAnswer
                } else {
                    tutorState = .active
                }
            }
            
            // 更新統計數據
            updateStatsFromSessionManager(sessionQuestions)
        }
    }
    
    private func updateStatsFromSessionManager(_ sessionQuestions: [SessionQuestion]) {
        sessionStats.totalAnswered = sessionQuestions.filter { $0.isCompleted }.count
        sessionStats.correctAnswers = sessionQuestions.filter { question in
            guard let feedback = question.feedback else { return false }
            return calculateScore(from: feedback) >= 0.8
        }.count
        
        let scores = sessionQuestions.compactMap { question -> Double? in
            guard let feedback = question.feedback else { return nil }
            return calculateScore(from: feedback)
        }
        
        if !scores.isEmpty {
            sessionStats.totalScore = scores.reduce(0, +)
            sessionStats.averageScore = sessionStats.totalScore / Double(scores.count)
        }
        
        sessionProgress.answeredQuestions = sessionStats.totalAnswered
    }
    
    // MARK: - 知識點同步功能
    
    /// 同步知識點到伺服器
    private func syncKnowledgePointsToServer() async {
        let knowledgePointsData = sessionManager?.extractKnowledgePointsForSync() ?? []
        
        guard !knowledgePointsData.isEmpty else {
            print("📝 沒有需要同步的知識點")
            syncStatus = .idle
            return
        }
        
        syncStatus = .syncing
        var totalSaved = 0
        
        for (errors, questionData, userAnswer) in knowledgePointsData {
            do {
                let savedCount = try await apiService.finalizeKnowledgePoints(
                    errors: errors,
                    questionData: questionData,
                    userAnswer: userAnswer
                )
                totalSaved += abs(savedCount) // 處理本地儲存的負數回傳
                
                if savedCount < 0 {
                    print("💾 使用本地儲存模式")
                } else {
                    print("🎉 成功同步到伺服器")
                }
            } catch {
                print("❌ 同步失敗: \(error.localizedDescription)")
                syncStatus = .failed(error)
                return
            }
        }
        
        syncedKnowledgePointsCount = totalSaved
        syncStatus = .completed
        
        if totalSaved > 0 {
            // 更新知識點快取
            do {
                _ = try await KnowledgePointRepository.shared.forceRefresh()
            } catch {
                print("更新知識點快取失敗: \(error.localizedDescription)")
            }
        }
    }
    
    /// 手動同步知識點
    func manualSyncKnowledgePoints() async -> Bool {
        await syncKnowledgePointsToServer()
        return sessionManager?.hasUnsyncedKnowledgePoints() == false
    }
    
    /// 檢查是否有未同步的知識點
    func hasUnsyncedKnowledgePoints() -> Bool {
        return sessionManager?.hasUnsyncedKnowledgePoints() ?? false
    }
    
    /// 取得未同步知識點數量
    func getUnsyncedKnowledgePointsCount() -> Int {
        return sessionManager?.getUnsyncedKnowledgePointsCount() ?? 0
    }
    
}