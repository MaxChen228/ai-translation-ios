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
                    FeedbackDisplayView(
                        feedback: feedback,
                        questionData: sessionQuestion.question,
                        userAnswer: userAnswer
                    )
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

        guard let url = URL(string: "\(APIConfig.apiBaseURL)/api/submit_answer") else {
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

// --- 【大幅修改】支援編輯、刪除、合併的批改回饋視圖 ---
struct FeedbackDisplayView: View {
    let feedback: FeedbackResponse
    let questionData: Question
    let userAnswer: String
    
    // 【新增】使用 @State 來追蹤可編輯的錯誤列表
    @State private var editableErrors: [ErrorAnalysis] = []
    @State private var isEditMode: Bool = false
    
    // 【新增】用於追蹤正在合併的項目
    @State private var selectedForMerge: Set<UUID> = []
    @State private var isMerging: Bool = false
    @State private var mergeError: String?
    
    // 【新增】用於追蹤儲存狀態
    @State private var isSaving: Bool = false
    @State private var saveMessage: String?
    @State private var showSaveAlert: Bool = false
    
    var body: some View {
        Divider().padding(.vertical, 10)
        
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("🎓 AI 家教點評")
                    .font(.title2).bold()
                
                Spacer()
                
                // 【新增】編輯模式切換按鈕
                if !editableErrors.isEmpty {
                    Button(action: {
                        withAnimation {
                            isEditMode.toggle()
                            if !isEditMode {
                                // 退出編輯模式時清空選擇
                                selectedForMerge.removeAll()
                            }
                        }
                    }) {
                        Text(isEditMode ? "完成" : "編輯")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
            }
            
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
            if !editableErrors.isEmpty {
                HStack {
                    Text("詳細錯誤分析")
                        .font(.headline)
                    
                    Spacer()
                    
                    // 【新增】合併按鈕（只在編輯模式且選了2個項目時顯示）
                    if isEditMode && selectedForMerge.count == 2 {
                        Button(action: {
                            Task {
                                await performMerge()
                            }
                        }) {
                            if isMerging {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Label("合併", systemImage: "arrow.triangle.merge")
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isMerging)
                    }
                }
                .padding(.top, 5)
                
                if let mergeError = mergeError {
                    Text("合併失敗：\(mergeError)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                if isEditMode {
                    // 【修改】編輯模式下的可刪除、可選擇列表
                    List {
                        ForEach(editableErrors) { error in
                            ErrorAnalysisEditableCard(
                                error: error,
                                isSelected: selectedForMerge.contains(error.id),
                                onTap: {
                                    toggleSelection(for: error.id)
                                }
                            )
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    removeError(error)
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                        }
                        .onMove(perform: moveError)
                    }
                    .listStyle(PlainListStyle())
                    .frame(minHeight: CGFloat(editableErrors.count * 180))
                    .scrollDisabled(true)
                    
                } else {
                    // 非編輯模式下的靜態顯示
                    ForEach(editableErrors) { error in
                        ErrorAnalysisCard(error: error)
                    }
                }
                
                // 【新增】確認儲存按鈕
                if !editableErrors.isEmpty {
                    Button(action: {
                        showSaveAlert = true
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("儲存中...")
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("確認儲存到知識庫")
                            }
                        }
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(editableErrors.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(editableErrors.isEmpty || isSaving)
                    .padding(.top)
                }
                
                if let saveMessage = saveMessage {
                    Text(saveMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal)
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
        .onAppear {
            // 初始化可編輯的錯誤列表
            editableErrors = feedback.error_analysis
        }
        .alert("確認儲存", isPresented: $showSaveAlert) {
            Button("取消", role: .cancel) { }
            Button("確認") {
                Task {
                    await saveToKnowledgeBase()
                }
            }
        } message: {
            Text("確定要將這 \(editableErrors.count) 個錯誤分析儲存為知識點嗎？")
        }
    }
    
    // 【新增】處理拖動排序的函數
    private func moveError(from source: IndexSet, to destination: Int) {
        editableErrors.move(fromOffsets: source, toOffset: destination)
    }
    
    // 【新增】刪除錯誤
    private func removeError(_ error: ErrorAnalysis) {
        withAnimation {
            editableErrors.removeAll { $0.id == error.id }
            selectedForMerge.remove(error.id)
        }
    }
    
    // 【新增】切換選擇狀態
    private func toggleSelection(for errorId: UUID) {
        if selectedForMerge.contains(errorId) {
            selectedForMerge.remove(errorId)
        } else {
            // 最多只能選擇2個
            if selectedForMerge.count < 2 {
                selectedForMerge.insert(errorId)
            }
        }
    }
    
    // 【新增】執行合併
    private func performMerge() async {
        guard selectedForMerge.count == 2 else { return }
        
        isMerging = true
        mergeError = nil
        
        let selectedIds = Array(selectedForMerge)
        guard let error1 = editableErrors.first(where: { $0.id == selectedIds[0] }),
              let error2 = editableErrors.first(where: { $0.id == selectedIds[1] }) else {
            isMerging = false
            return
        }
        
        do {
            // 呼叫後端 API 進行合併
            let mergedError = try await KnowledgePointAPIService.mergeErrors(error1: error1, error2: error2)
            
            // 更新列表：移除原本的兩個，加入合併後的結果
            withAnimation {
                editableErrors.removeAll { selectedForMerge.contains($0.id) }
                editableErrors.append(mergedError)
                selectedForMerge.removeAll()
            }
        } catch {
            mergeError = "無法合併錯誤：\(error.localizedDescription)"
        }
        
        isMerging = false
    }
    
    // 【新增】儲存到知識庫
    private func saveToKnowledgeBase() async {
        isSaving = true
        saveMessage = nil
        
        // 準備要傳送的資料
        let questionDataDict: [String: Any?] = [
            "new_sentence": questionData.new_sentence,
            "type": questionData.type,
            "hint_text": questionData.hint_text,
            "knowledge_point_id": questionData.knowledge_point_id,
            "mastery_level": questionData.mastery_level
        ]
        
        do {
            let savedCount = try await KnowledgePointAPIService.finalizeKnowledgePoints(
                errors: editableErrors,
                questionData: questionDataDict,
                userAnswer: userAnswer
            )
            
            saveMessage = "✅ 成功儲存 \(savedCount) 個知識點"
            
            // 清空錯誤列表，表示已經處理完成
            withAnimation {
                editableErrors.removeAll()
            }
        } catch {
            saveMessage = "❌ 儲存失敗：\(error.localizedDescription)"
        }
        
        isSaving = false
    }
}

// 【新增】可編輯模式的錯誤卡片
struct ErrorAnalysisEditableCard: View {
    let error: ErrorAnalysis
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // 選擇圓圈
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title2)
                .onTapGesture {
                    onTap()
                }
            
            // 原本的錯誤卡片內容
            ErrorAnalysisCard(error: error)
        }
    }
}

// --- 錯誤分析卡片（維持原樣）---
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
