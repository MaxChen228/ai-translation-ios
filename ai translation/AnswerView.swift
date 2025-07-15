// AnswerView.swift

import SwiftUI

struct AnswerView: View {
    // 從環境中讀取共享的 sessionManager
    @EnvironmentObject var sessionManager: SessionManager
    
    // 這個視圖只關心它需要顯示哪一題的 ID
    let sessionQuestionId: UUID
    
    // 從 sessionManager 中安全地找到我們正在作答的這題
    private var sessionQuestion: SessionQuestion {
        // 使用 guard 來安全地解包，如果找不到就回傳一個預設值避免閃退
        guard let question = sessionManager.sessionQuestions.first(where: { $0.id == sessionQuestionId }) else {
            // 這種情況理論上不應該發生，但作為一個保護措施
            return SessionQuestion(id: UUID(), question: Question(new_sentence: "錯誤：找不到題目", type: "error"))
        }
        return question
    }
    
    // 用於綁定 TextEditor 的狀態變數
    @State private var userAnswer: String = ""
    
    // 管理此頁面的載入和錯誤狀態
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        // 使用 ScrollView 包住所有內容，讓整個頁面都可以捲動
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 顯示題目區塊
                Text("請翻譯以下句子：")
                    .font(.headline)
                Text(sessionQuestion.question.new_sentence)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                // 輸入框
                TextEditor(text: $userAnswer)
                    .frame(height: 150)
                    .border(Color.gray.opacity(0.3), width: 1)
                    .cornerRadius(8)
                    .padding(.bottom)

                // 提交按鈕
                Button(action: {
                    Task {
                        await submitAnswer()
                    }
                }) {
                    if isLoading {
                        ProgressView().tint(.white) // 讓進度條是白色以搭配按鈕背景
                    } else {
                        Text("提交批改")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(userAnswer.isEmpty ? Color.gray : Color.blue) // 如果沒作答，按鈕為灰色
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading || userAnswer.isEmpty) // 如果正在載入或未作答，則禁用按鈕

                // 如果有錯誤訊息，顯示它
                if let errorMessage = errorMessage {
                    Text("錯誤: \(errorMessage)")
                        .foregroundColor(.red)
                }
                
                // 如果有批改回饋，顯示點評區塊
                if let feedback = sessionQuestion.feedback {
                    displayFeedback(feedback: feedback)
                }
            }
        }
        .padding()
        .navigationTitle("作答與批改")
        // 當這個視圖出現時，執行以下動作
        .onAppear {
            // 從 sessionManager 中讀取已儲存的答案來設定輸入框的初始內容
            self.userAnswer = sessionQuestion.userAnswer ?? ""
        }
    }
    
    // 顯示 AI 點評結果的子視圖
    @ViewBuilder
    private func displayFeedback(feedback: FeedbackResponse) -> some View {
        Divider().padding(.vertical, 10)
        
        VStack(alignment: .leading, spacing: 15) {
            Text("🎓 AI 家教點評")
                .font(.title2).bold()
            
            Text(feedback.is_generally_correct ? "✅ 整體大致正確" : "⚠️ 存在主要錯誤")
                .font(.headline)
                .foregroundColor(feedback.is_generally_correct ? .green : .orange)

            Text("整體建議翻譯：")
                .font(.headline)
            Text(feedback.overall_suggestion)
            
            if !feedback.error_analysis.isEmpty {
                Text("詳細錯誤分析：")
                    .font(.headline)
                    .padding(.top)
                
                ForEach(feedback.error_analysis) { error in
                    VStack(alignment: .leading, spacing: 5) {
                        Text("● \(error.error_type) - \(error.error_subtype)")
                            .bold()
                        Text("原文片段: \"\(error.original_phrase)\"").opacity(0.8)
                        Text("建議修正: \"\(error.correction)\"").opacity(0.8)
                        Text("教學說明: \(error.explanation)")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                Text("🎉 恭喜！AI沒有發現任何錯誤。")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    // 呼叫後端 API 的網路請求函式
    func submitAnswer() async {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "https://ai-tutor-ikjn.onrender.com/submit_answer") else {
            errorMessage = "無效的網址"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "question_data": [
                "new_sentence": sessionQuestion.question.new_sentence,
                "type": sessionQuestion.question.type
            ],
            "user_answer": userAnswer
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let feedback = try JSONDecoder().decode(FeedbackResponse.self, from: data)
            
            // 將使用者剛輸入的答案和 AI 的批改結果，一起更新回共享的 sessionManager
            sessionManager.updateQuestion(id: sessionQuestionId, userAnswer: userAnswer, feedback: feedback)

        } catch {
            self.errorMessage = "提交失敗，請檢查網路或稍後再試。\n(\(error.localizedDescription))"
            print("提交答案時發生錯誤: \(error)")
        }
        
        isLoading = false
    }
}
