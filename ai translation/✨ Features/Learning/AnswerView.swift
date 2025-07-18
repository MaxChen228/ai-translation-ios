// AnswerView.swift

import SwiftUI

struct AnswerView: View {
    @EnvironmentObject var sessionManager: SessionManager
    let sessionQuestionId: UUID
    
    private var sessionQuestion: SessionQuestion {
        guard let question = sessionManager.sessionQuestions.first(where: { $0.id == sessionQuestionId }) else {
            return SessionQuestion(id: UUID(), question: Question(new_sentence: "錯誤：找不到題目", type: "error", hint_text: nil, knowledge_point_id: nil, mastery_level: nil))
        }
        return question
    }
    
    @State private var userAnswer: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showKeyboard = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Claude 風格的題目卡片
                ClaudeQuestionCard(
                    question: sessionQuestion.question,
                    questionNumber: getQuestionNumber(),
                    totalQuestions: sessionManager.sessionQuestions.count,
                    userAnswer: $userAnswer  // 加入這個參數
                )
                
                // Claude 風格的作答卡片
                ClaudeAnswerCard(
                    userAnswer: $userAnswer,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    showKeyboard: $showKeyboard,
                    onSubmit: {
                        Task {
                            await submitAnswer()
                        }
                    }
                )
                
                // Claude 風格的批改結果卡片
                if let feedback = sessionQuestion.feedback {
                    ClaudeFeedbackCard(
                        feedback: feedback,
                        questionData: sessionQuestion.question,
                        userAnswer: userAnswer
                    )
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("作答與批改")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let answer = sessionQuestion.userAnswer, !answer.isEmpty {
                self.userAnswer = answer
            }
        }
    }
    
    private func getQuestionNumber() -> Int {
        return (sessionManager.sessionQuestions.firstIndex(where: { $0.id == sessionQuestionId }) ?? 0) + 1
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
            
            let feedback = try JSONDecoder().decode(FeedbackResponse.self, from: data)
            
            sessionManager.updateQuestion(id: sessionQuestionId, userAnswer: userAnswer, feedback: feedback)

        } catch {
            self.errorMessage = "提交失敗，請檢查網路或稍後再試。\n(\(error.localizedDescription))"
            print("提交答案時發生錯誤: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Claude 風格組件

// 修改 ClaudeQuestionCard 結構，加入 userAnswer 參數
struct ClaudeQuestionCard: View {
    let question: Question
    let questionNumber: Int
    let totalQuestions: Int
    @Binding var userAnswer: String  // 新增這一行
    
    var body: some View {
        VStack(spacing: 20) {
            // 標題區域 (保持不變)
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 40, height: 40)
                        
                        Text("\(questionNumber)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("第 \(questionNumber) 題")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text("共 \(totalQuestions) 題")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                ClaudeQuestionTypeTag(type: question.type)
            }
            
            // 題目內容 (保持不變)
            VStack(alignment: .leading, spacing: 16) {
                Text("請翻譯以下句子：")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(question.new_sentence)
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundStyle(.primary)
                    .lineSpacing(4)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.08))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            }
                    }
            }
            
            // 提示區域 - 修改這裡，現在可以正確傳遞 userAnswer
            if let hint = question.hint_text, !hint.isEmpty {
                ClaudeHintCard(
                    hintText: hint,
                    chineseSentence: question.new_sentence,
                    userAnswer: $userAnswer  // 現在這個參數可以正確傳遞了
                )
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct ClaudeQuestionTypeTag: View {
    let type: String
    
    private var tagInfo: (text: String, color: Color, icon: String) {
        switch type {
        case "review":
            return ("複習題", .green, "arrow.clockwise")
        default:
            return ("新題目", .blue, "plus")
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: tagInfo.icon)
                .font(.system(size: 10, weight: .medium))
            
            Text(tagInfo.text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(tagInfo.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(tagInfo.color.opacity(0.15))
        }
    }
}

struct ClaudeHintCard: View {
    let hintText: String
    let chineseSentence: String
    @Binding var userAnswer: String
    
    @State private var showBasicHint = false
    @State private var showSmartHint = false
    @State private var smartHintData: SmartHintResponse?
    @State private var isLoadingSmartHint = false
    @State private var smartHintError: String?
    
    var body: some View {
        VStack(spacing: 16) {
            // 基本提示按鈕
            if !showBasicHint && !showSmartHint {
                HStack(spacing: 12) {
                    // 基本提示按鈕
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showBasicHint = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 14, weight: .medium))
                            
                            Text("基本提示")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background {
                            Capsule()
                                .fill(Color.orange.opacity(0.1))
                                .overlay {
                                    Capsule()
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                }
                        }
                    }
                    
                    // AI智慧提示按鈕
                    Button(action: {
                        Task {
                            await fetchSmartHint()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isLoadingSmartHint {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(Color.blue)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            
                            Text(isLoadingSmartHint ? "思考中..." : "AI智慧提示")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(Color.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background {
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                                .overlay {
                                    Capsule()
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                }
                        }
                    }
                    .disabled(isLoadingSmartHint)
                }
            }
            
            // 基本提示內容
            if showBasicHint {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.yellow)
                        
                        Text("考點提示")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showBasicHint = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text(hintText)
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.yellow.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.yellow.opacity(0.3), lineWidth: 1)
                        }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }
            
            // AI智慧提示內容
            if showSmartHint {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                        
                        Text("AI 智慧引導")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSmartHint = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let error = smartHintError {
                        ClaudeErrorMessage(message: error)
                    } else if let smartHint = smartHintData {
                        VStack(alignment: .leading, spacing: 16) {
                            // 主要引導提示
                            Text(smartHint.smart_hint)
                                .font(.system(size: 15))
                                .foregroundStyle(.primary)
                                .lineSpacing(2)
                            
                            // 思考問題
                            if !smartHint.thinking_questions.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("🤔 思考一下：")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.blue)
                                    
                                    ForEach(Array(smartHint.thinking_questions.enumerated()), id: \.offset) { index, question in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("\(index + 1).")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.blue)
                                            
                                            Text(question)
                                                .font(.system(size: 13))
                                                .foregroundStyle(.primary)
                                                .lineSpacing(1)
                                        }
                                    }
                                }
                            }
                            
                            // 鼓勵話語
                            if !smartHint.encouragement.isEmpty {
                                Text("💪 " + smartHint.encouragement)
                                    .font(.system(size: 13, weight: .medium, design: .serif))
                                    .foregroundStyle(.secondary)
                                    .italic()
                                    .padding(10)
                                    .background {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.08))
                                    }
                            }
                        }
                    }
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue.opacity(0.3), lineWidth: 1)
                        }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }
        }
    }
    
    private func fetchSmartHint() async {
        isLoadingSmartHint = true
        smartHintError = nil
        
        guard let url = URL(string: "\(APIConfig.apiBaseURL)/api/get_smart_hint") else {
            smartHintError = "無效的網址"
            isLoadingSmartHint = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "chinese_sentence": chineseSentence,
            "user_current_input": userAnswer,
            "original_hint": hintText,
            "model_name": SettingsManager.shared.generationModel.rawValue
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let response = try JSONDecoder().decode(SmartHintResponse.self, from: data)
            
            await MainActor.run {
                self.smartHintData = response
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showSmartHint = true
                }
            }
            
        } catch {
            await MainActor.run {
                self.smartHintError = "獲取智慧提示失敗：\(error.localizedDescription)"
            }
        }
        
        isLoadingSmartHint = false
    }
}

struct ClaudeAnswerCard: View {
    @Binding var userAnswer: String
    let isLoading: Bool
    let errorMessage: String?
    @Binding var showKeyboard: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 標題
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.orange)
                
                Text("您的翻譯")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            // 輸入區域
            VStack(spacing: 16) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(showKeyboard ? Color.orange : Color.clear, lineWidth: 2)
                        }
                        .frame(minHeight: 120)
                    
                    if userAnswer.isEmpty {
                        Text("請在此輸入您的英文翻譯...")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.secondary.opacity(0.6))
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $userAnswer)
                        .font(.system(size: 16))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .onTapGesture {
                            showKeyboard = true
                        }
                        .onChange(of: userAnswer) { _, _ in
                            showKeyboard = !userAnswer.isEmpty
                        }
                }
                
                // 字數統計
                HStack {
                    Spacer()
                    Text("\(userAnswer.count) 字元")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                // 提交按鈕
                Button(action: onSubmit) {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.9)
                                .tint(.white)
                            Text("AI 批改中...")
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("提交批改")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(userAnswer.isEmpty ? Color.gray : Color.orange)
                    }
                }
                .disabled(isLoading || userAnswer.isEmpty)
                
                // 錯誤訊息
                if let errorMessage = errorMessage {
                    ClaudeErrorMessage(message: errorMessage)
                }
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct ClaudeErrorMessage: View {
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.red)
                .padding(.top, 1)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.red)
                .lineSpacing(1)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.red.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

struct ClaudeFeedbackCard: View {
    let feedback: FeedbackResponse
    let questionData: Question
    let userAnswer: String
    
    @State private var editableErrors: [ErrorAnalysis] = []
    @State private var isEditMode: Bool = false
    @State private var selectedForMerge: Set<UUID> = []
    @State private var isMerging: Bool = false
    @State private var mergeError: String?
    @State private var isSaving: Bool = false
    @State private var saveMessage: String?
    @State private var showSaveAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Claude 風格的整體評估
            ClaudeOverallAssessment(feedback: feedback)
            
            // Claude 風格的錯誤分析
            if !editableErrors.isEmpty {
                ClaudeErrorAnalysisCard(
                    editableErrors: $editableErrors,
                    isEditMode: $isEditMode,
                    selectedForMerge: $selectedForMerge,
                    isMerging: $isMerging,
                    mergeError: $mergeError,
                    onMerge: performMerge
                )
                
                // Claude 風格的儲存區域
                ClaudeSaveSection(
                    editableErrors: editableErrors,
                    isSaving: isSaving,
                    saveMessage: saveMessage,
                    onSave: { showSaveAlert = true }
                )
            } else {
                ClaudeNoErrorsCard()
            }
        }
        .onAppear {
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
            let mergedError = try await KnowledgePointAPIService.mergeErrors(error1: error1, error2: error2)
            
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
    
    private func saveToKnowledgeBase() async {
        isSaving = true
        saveMessage = nil
        
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
            
            withAnimation {
                editableErrors.removeAll()
            }
        } catch {
            saveMessage = "❌ 儲存失敗：\(error.localizedDescription)"
        }
        
        isSaving = false
    }
}

struct ClaudeOverallAssessment: View {
    let feedback: FeedbackResponse
    
    var body: some View {
        VStack(spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.orange)
                
                Text("AI 家教點評")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            // 評估結果
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(feedback.is_generally_correct ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: feedback.is_generally_correct ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(feedback.is_generally_correct ? .green : .orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(feedback.is_generally_correct ? "整體大致正確" : "存在主要錯誤")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text("AI 已完成詳細分析")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // 建議翻譯
            VStack(alignment: .leading, spacing: 8) {
                Text("整體建議翻譯：")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Text(feedback.overall_suggestion)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .lineSpacing(2)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct ClaudeErrorAnalysisCard: View {
    @Binding var editableErrors: [ErrorAnalysis]
    @Binding var isEditMode: Bool
    @Binding var selectedForMerge: Set<UUID>
    @Binding var isMerging: Bool
    @Binding var mergeError: String?
    let onMerge: () async -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 標題和控制按鈕
            HStack {
                Text("詳細錯誤分析")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if !editableErrors.isEmpty {
                    HStack(spacing: 12) {
                        if isEditMode && selectedForMerge.count == 2 {
                            Button(action: {
                                Task {
                                    await onMerge()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    if isMerging {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "arrow.triangle.merge")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    Text("合併")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background {
                                    Capsule()
                                        .fill(Color.blue)
                                }
                            }
                            .disabled(isMerging)
                        }
                        
                        Button(action: {
                            withAnimation {
                                isEditMode.toggle()
                                if !isEditMode {
                                    selectedForMerge.removeAll()
                                }
                            }
                        }) {
                            Text(isEditMode ? "完成" : "編輯")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background {
                                    Capsule()
                                        .fill(Color.orange.opacity(0.15))
                                }
                        }
                    }
                }
            }
            
            // 合併錯誤訊息
            if let mergeError = mergeError {
                ClaudeErrorMessage(message: mergeError)
            }
            
            // 錯誤列表
            LazyVStack(spacing: 12) {
                ForEach(editableErrors) { error in
                    ClaudeErrorAnalysisRow(
                        error: error,
                        isEditMode: isEditMode,
                        isSelected: selectedForMerge.contains(error.id),
                        onTap: {
                            toggleSelection(for: error.id)
                        },
                        onDelete: {
                            removeError(error)
                        }
                    )
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    private func toggleSelection(for errorId: UUID) {
        if selectedForMerge.contains(errorId) {
            selectedForMerge.remove(errorId)
        } else {
            if selectedForMerge.count < 2 {
                selectedForMerge.insert(errorId)
            }
        }
    }
    
    private func removeError(_ error: ErrorAnalysis) {
        withAnimation {
            editableErrors.removeAll { $0.id == error.id }
            selectedForMerge.remove(error.id)
        }
    }
}

struct ClaudeErrorAnalysisRow: View {
    let error: ErrorAnalysis
    let isEditMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 選擇按鈕（編輯模式）
            if isEditMode {
                Button(action: onTap) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? Color.blue : Color.secondary.opacity(0.6))
                }
                .padding(.trailing, 16)
            }
            
            // 錯誤內容
            VStack(alignment: .leading, spacing: 12) {
                // 分類標籤
                HStack(spacing: 8) {
                    Image(systemName: error.categoryIcon)
                        .font(.system(size: 12, weight: .medium))
                    
                    Text(error.categoryName)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(error.categoryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(error.categoryColor.opacity(0.15))
                }
                
                Divider()
                
                // 核心觀念
                Text(error.key_point_summary)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                // 錯誤與修正
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("原文：")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        
                        Text("\"\(error.original_phrase)\"")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.red)
                            .strikethrough(color: .red)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("修正：")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        
                        Text("\"\(error.correction)\"")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.green)
                    }
                }
                
                // 解釋
                Text(error.explanation)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 刪除按鈕（編輯模式）
            if isEditMode {
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.red)
                }
                .padding(.leading, 16)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    }
                }
        }
    }
}

struct ClaudeNoErrorsCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            
            Text("🎉 恭喜！")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
            
            Text("AI 沒有發現任何錯誤")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

struct ClaudeSaveSection: View {
    let editableErrors: [ErrorAnalysis]
    let isSaving: Bool
    let saveMessage: String?
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: onSave) {
                HStack(spacing: 12) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                        Text("儲存中...")
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("確認儲存到知識庫")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(editableErrors.isEmpty ? Color.gray : Color.green)
                }
            }
            .disabled(editableErrors.isEmpty || isSaving)
            
            if let saveMessage = saveMessage {
                Text(saveMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(saveMessage.contains("✅") ? .green : .red)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill((saveMessage.contains("✅") ? Color.green : Color.red).opacity(0.1))
                    }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    NavigationView {
        AnswerView(sessionQuestionId: UUID())
            .environmentObject(SessionManager())
    }
}
