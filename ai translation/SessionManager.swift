// SessionManager.swift

import Foundation

// 我們需要一個新的結構來儲存單一題目的完整狀態
struct SessionQuestion: Identifiable {
    let id: UUID
    let question: Question // 原始題目資料
    var userAnswer: String? // 使用者的答案
    var feedback: FeedbackResponse? // AI 的批改回饋
    
    var isCompleted: Bool {
        return feedback != nil
    }
}

// 這個 Class 會在整個 App 中共享，負責管理學習狀態
@MainActor // 確保所有對它的修改都在主執行緒上，是安全的
class SessionManager: ObservableObject {
    @Published var sessionQuestions: [SessionQuestion] = []
    
    // 當從網路獲取到新題目時，呼叫此函式
    func startNewSession(questions: [Question]) {
        self.sessionQuestions = questions.map {
            SessionQuestion(id: $0.id, question: $0)
        }
    }
    
    // 當使用者提交答案並獲得回饋後，呼叫此函式來更新狀態
    func updateQuestion(id: UUID, userAnswer: String, feedback: FeedbackResponse) {
        // 找到對應的題目並更新它的狀態
        if let index = sessionQuestions.firstIndex(where: { $0.id == id }) {
            sessionQuestions[index].userAnswer = userAnswer
            sessionQuestions[index].feedback = feedback
        }
    }
}
