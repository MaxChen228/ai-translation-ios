// AnswerView.swift

import SwiftUI

struct AnswerView: View {
    // 從環境中讀取共享的 sessionManager
    @EnvironmentObject var sessionManager: SessionManager
    
    // 這個視圖只關心它需要顯示哪一題的 ID
    let sessionQuestionId: UUID
    
    // 從 sessionManager 中安全地找到我們正在作答的這題
    private var sessionQuestion: SessionQuestion {
        guard let question = sessionManager.sessionQuestions.first(where: { $0.id == sessionQuestionId }) else {
            return SessionQuestion(id: UUID(), question: Question(new_sentence: "錯誤：找不到題目", type: "error", hint_text: nil, knowledge_point_id: nil, mastery_level: nil))
        }
        return question
    }
    
    // 用於綁定 TextEditor 的狀態變數
    @State private var userAnswer: String = ""
    
    // 管理此頁面的載入和錯誤狀態
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("請翻譯以下句子：")
                    .font(.headline)
                Text(sessionQuestion.question.new_sentence)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                // 【新增】顯示提示的區塊
                if let hint = sessionQuestion.question.hint_text, !hint.isEmpty {
                    HintView(hintText: hint)
                }
                
                TextEditor(text: $userAnswer)
                    .frame(height: 150)
                    .border(Color.gray.opacity(0.3), width: 1)
                    .cornerRadius(8)
                    .padding(.bottom)

                Button(action: {
                    Task {
                        await submitAnswer()
                    }
                }) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("提交批改")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(userAnswer.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading || userAnswer.isEmpty)

                if let errorMessage = errorMessage {
                    Text("錯誤: \(errorMessage)")
                        .foregroundColor(.red)
                }
                
                if let feedback = sessionQuestion.feedback {
                    displayFeedback(feedback: feedback)
                }
            }
        }
        .padding()
        .navigationTitle("作答與批改")
        .onAppear {
            self.userAnswer = sessionQuestion.userAnswer ?? ""
        }
    }
    
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

        guard let url = URL(string: "https://ai-tutor-ikjn.onrender.com/api/submit_answer") else {
            errorMessage = "無效的網址"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // 動態建立 question_data，確保包含所有需要的資訊
        var questionDataDict: [String: Any?] = [
            "new_sentence": sessionQuestion.question.new_sentence,
            "type": sessionQuestion.question.type,
            "hint_text": sessionQuestion.question.hint_text
        ]
        
        if sessionQuestion.question.type == "review" {
            questionDataDict["knowledge_point_id"] = sessionQuestion.question.knowledge_point_id
            questionDataDict["mastery_level"] = sessionQuestion.question.mastery_level
        }
        
        let body: [String: Any] = [
            "question_data": questionDataDict,
            "user_answer": userAnswer
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let feedback = try JSONDecoder().decode(FeedbackResponse.self, from: data)
            
            sessionManager.updateQuestion(id: sessionQuestionId, userAnswer: userAnswer, feedback: feedback)

        } catch {
            self.errorMessage = "提交失敗，請檢查網路或稍後再試。\n(\(error.localizedDescription))"
            print("提交答案時發生錯誤: \(error)")
        }
        
        isLoading = false
    }
}

// 一個專門用來顯示提示的子視圖
struct HintView: View {
    let hintText: String
    @State private var showHint = false

    var body: some View {
        VStack(alignment: .leading) {
            if showHint {
                HStack {
                    Image(systemName: "lightbulb.fill")
                    Text("考點提示：")
                    Spacer()
                }
                .font(.headline)
                .foregroundColor(.orange)
                
                Text(hintText)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)

            } else {
                Button(action: {
                    withAnimation {
                        showHint = true
                    }
                }) {
                    HStack {
                        Image(systemName: "lightbulb")
                        Text("需要一點提示嗎？")
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
