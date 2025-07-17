// AnswerView.swift

import SwiftUI

struct AnswerView: View {
    @EnvironmentObject var sessionManager: SessionManager
    let sessionQuestionId: UUID
    
    private var sessionQuestion: SessionQuestion {
        guard let question = sessionManager.sessionQuestions.first(where: { $0.id == sessionQuestionId }) else {
            // 提供一個更安全的預設值
            return SessionQuestion(id: UUID(), question: Question(new_sentence: "錯誤：找不到題目", type: "error", hint_text: nil, knowledge_point_id: nil, mastery_level: nil))
        }
        return question
    }
    
    @State private var userAnswer: String = ""
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
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                if let hint = sessionQuestion.question.hint_text, !hint.isEmpty {
                    HintView(hintText: hint)
                }
                
                TextEditor(text: $userAnswer)
                    .frame(height: 150)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
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
                        .font(.caption)
                }
                
                // 如果有回饋，就顯示回饋區塊
                if let feedback = sessionQuestion.feedback {
                    FeedbackDisplayView(feedback: feedback)
                }
            }
        }
        .padding()
        .navigationTitle("作答與批改")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 從 userAnswer 中讀取，而不是 isCompleted
            if let answer = sessionQuestion.userAnswer, !answer.isEmpty {
                self.userAnswer = answer
            }
        }
    }
    
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
            "user_answer": userAnswer,
            "grading_model": SettingsManager.shared.gradingModel.rawValue
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // 使用新的 FeedbackResponse 結構來解碼
            let feedback = try JSONDecoder().decode(FeedbackResponse.self, from: data)
            
            sessionManager.updateQuestion(id: sessionQuestionId, userAnswer: userAnswer, feedback: feedback)

        } catch {
            self.errorMessage = "提交失敗，請檢查網路或稍後再試。\n(\(error.localizedDescription))"
            print("提交答案時發生錯誤: \(error)")
        }
        
        isLoading = false
    }
}

// --- 【計畫一修改】將批改回饋的 UI 拆分成獨立的子視圖 ---
struct FeedbackDisplayView: View {
    let feedback: FeedbackResponse
    
    var body: some View {
        Divider().padding(.vertical, 10)
        
        VStack(alignment: .leading, spacing: 18) {
            Text("🎓 AI 家教點評")
                .font(.title2).bold()
            
            // 區塊一：整體評分
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: feedback.is_generally_correct ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    Text(feedback.is_generally_correct ? "整體大致正確" : "存在主要錯誤")
                }
                .font(.headline)
                .foregroundColor(feedback.is_generally_correct ? .green : .orange)

                Text("整體建議翻譯：")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(feedback.overall_suggestion)
                    .font(.body)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            
            // 區塊二：錯誤分析列表
            if !feedback.error_analysis.isEmpty {
                Text("詳細錯誤分析")
                    .font(.headline)
                    .padding(.top, 5)
                
                ForEach(feedback.error_analysis) { error in
                    ErrorAnalysisCard(error: error)
                }
            } else {
                Text("🎉 恭喜！AI沒有發現任何錯誤。")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
            }
        }
    }
}

// --- 【計畫一新增】專門用來顯示單一錯誤分析的卡片 ---
struct ErrorAnalysisCard: View {
    let error: ErrorAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 使用我們在 Model 中定義的輔助屬性
            HStack(spacing: 8) {
                Image(systemName: error.categoryIcon)
                Text(error.categoryName)
            }
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(error.categoryColor.opacity(0.15))
            .foregroundColor(error.categoryColor)
            .cornerRadius(20)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(error.key_point_summary)
                    .font(.headline)
                
                Group {
                    HStack(alignment: .top) {
                        Text("原文：").bold()
                        Text("\"\(error.original_phrase)\"")
                            .strikethrough(color: .red)
                            .foregroundColor(.red.opacity(0.8))
                    }
                    HStack(alignment: .top) {
                        Text("修正：").bold()
                        Text("\"\(error.correction)\"")
                            .foregroundColor(.green)
                    }
                }
                .font(.footnote)
                
                Text(error.explanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}


// 提示的子視圖 (不變)
struct HintView: View {
    let hintText: String
    @State private var showHint = false

    var body: some View {
        VStack(alignment: .leading) {
            if showHint {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                        Text("考點提示：")
                        Spacer()
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                    
                    Text(hintText)
                        .font(.body)
                        .padding(.top, 2)
                }
                .padding(12)
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
                .foregroundColor(.accentColor)
            }
        }
    }
}
