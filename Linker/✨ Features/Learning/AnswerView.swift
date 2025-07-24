// AnswerView.swift

import SwiftUI

struct AnswerView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var authManager: AuthenticationManager
    let sessionQuestionId: UUID
    @Environment(\.dismiss) private var dismiss
    
    private var sessionQuestion: SessionQuestion {
        guard let question = sessionManager.sessionQuestions.first(where: { $0.id == sessionQuestionId }) else {
            return SessionQuestion(id: UUID(), question: Question(newSentence: "錯誤：找不到題目", type: "error", hintText: nil, knowledgePointCompositeId: nil, knowledgePointId: nil, masteryLevel: nil))
        }
        return question
    }
    
    @State private var userAnswer: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showKeyboard = false
    @State private var showSaveSuccessAlert = false
    @State private var savedKnowledgePointsCount = 0
    @State private var isLocalStorage = false
    @State private var shouldNavigateToDashboard = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Claude 風格的題目卡片
                ModernQuestionCard(
                    question: sessionQuestion.question,
                    questionNumber: getQuestionNumber(),
                    totalQuestions: sessionManager.sessionQuestions.count,
                    userAnswer: $userAnswer  // 加入這個參數
                )
                
                // Claude 風格的作答卡片
                ModernAnswerCard(
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
                    FeedbackCard(
                        feedback: feedback,
                        questionData: sessionQuestion.question,
                        userAnswer: userAnswer,
                        savedKnowledgePointsCount: $savedKnowledgePointsCount,
                        showSaveSuccessAlert: $showSaveSuccessAlert,
                        isLocalStorage: $isLocalStorage,
                        isAuthenticated: authManager.isAuthenticated
                    )
                }
            }
            .padding(ModernSpacing.lg)
        }
        .background(Color.modernBackground)
        .navigationTitle("作答與批改")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let answer = sessionQuestion.userAnswer, !answer.isEmpty {
                self.userAnswer = answer
            }
        }
        .alert("成功儲存知識點", isPresented: $showSaveSuccessAlert) {
            Button("查看知識點") {
                shouldNavigateToDashboard = true
            }
            Button("繼續學習") { }
        } message: {
            if isLocalStorage {
                Text("已儲存 \(savedKnowledgePointsCount) 個知識點至本地資料庫。由於伺服器端點暫時不可用，知識點已保存在本地，您仍可在「儀表板」中查看它們。")
            } else {
                Text("已成功儲存 \(savedKnowledgePointsCount) 個知識點至雲端資料庫。您可以在「儀表板」中查看和管理它們。")
            }
        }
        .navigationDestination(isPresented: $shouldNavigateToDashboard) {
            DashboardView()
        }
    }
    
    private func getQuestionNumber() -> Int {
        return (sessionManager.sessionQuestions.firstIndex(where: { $0.id == sessionQuestionId }) ?? 0) + 1
    }
    
    func submitAnswer() async {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "\(APIConfig.apiBaseURL)/api/session/submit_answer") else {
            errorMessage = "無效的網址"
            isLoading = false
            return
        }

        var questionDataDict: [String: Any?] = [
            "new_sentence": sessionQuestion.question.newSentence,
            "type": sessionQuestion.question.type,
            "hint_text": sessionQuestion.question.hintText
        ]
        
        if sessionQuestion.question.type == "review" {
            questionDataDict["knowledge_point_id"] = sessionQuestion.question.knowledgePointId
            questionDataDict["mastery_level"] = sessionQuestion.question.masteryLevel
        }
        
        let body: [String: Any] = [
            "question_data": questionDataDict,
            "user_answer": userAnswer,
            "grading_model": SettingsManager.shared.gradingModel.rawValue
        ]
        
        do {
            let bodyData = try JSONSerialization.data(withJSONObject: body, options: [])
            let (data, response) = try await NetworkManager.shared.performPOSTRequest(url: url, body: bodyData, requireAuth: false)
            
            try NetworkManager.shared.validateHTTPResponse(response, data: data)
            let feedback = try NetworkManager.shared.safeDecodeJSON(data, as: FeedbackResponse.self)
            
            sessionManager.updateQuestion(id: sessionQuestionId, userAnswer: userAnswer, feedback: feedback)

        } catch {
            self.errorMessage = "提交失敗，請檢查網路或稍後再試。\n(\(error.localizedDescription))"
            Logger.error("提交答案時發生錯誤: \(error.localizedDescription)", category: .api)
        }
        
        isLoading = false
    }
}

// MARK: - Claude 風格組件

// 修改 ModernQuestionCard 結構，加入 userAnswer 參數
struct ModernQuestionCard: View {
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
                            .fill(Color.modernAccent)
                            .frame(width: 40, height: 40)
                        
                        Text("\(questionNumber)")
                            .font(.appBody())
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("第 \(questionNumber) 題")
                            .font(.appHeadline())
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("共 \(totalQuestions) 題")
                            .font(.appFootnote())
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                ModernQuestionTypeTag(type: question.type)
            }
            
            // 題目內容 (保持不變)
            VStack(alignment: .leading, spacing: 16) {
                Text("請翻譯以下句子：")
                    .font(.appBody(for: "請翻譯以下句子："))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(question.newSentence)
                    .font(.appHeadline(for: question.newSentence))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineSpacing(4)
                    .padding(ModernSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: ModernRadius.md)
                            .fill(Color.modernAccent.opacity(0.08))
                            .overlay {
                                RoundedRectangle(cornerRadius: ModernRadius.md)
                                    .stroke(Color.modernAccent.opacity(0.25), lineWidth: 1)
                            }
                    }
            }
            
            // 提示區域 - 修改這裡，現在可以正確傳遞 userAnswer
            if let hint = question.hintText, !hint.isEmpty {
                ModernHintCard(
                    hintText: hint,
                    chineseSentence: question.newSentence,
                    userAnswer: $userAnswer  // 現在這個參數可以正確傳遞了
                )
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .modernShadow()
        }
    }      
}

struct ModernQuestionTypeTag: View {
    let type: String
    
    private var tagInfo: (text: String, color: Color, icon: String) {
        switch type {
        case "review":
            return ("複習題", Color.modernSuccess, "arrow.clockwise")
        default:
            return ("新題目", Color.modernSpecial, "plus")
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: tagInfo.icon)
                .font(.appCaption2(for: "圖示"))
            
            Text(tagInfo.text)
                .font(.appCaption(for: tagInfo.text))
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

struct ModernHintCard: View {
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
                                .font(.appSubheadline())
                            
                            Text("基本提示")
                                .font(.appSubheadline(for: "基本提示"))
                        }
                        .foregroundStyle(Color.modernAccent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background {
                            Capsule()
                                .fill(Color.modernAccent.opacity(0.1))
                                .overlay {
                                    Capsule()
                                        .stroke(Color.modernAccent.opacity(0.3), lineWidth: 1)
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
                                    .tint(Color.modernSpecial)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.appCallout())
                            }
                            
                            Text(isLoadingSmartHint ? "思考中..." : "AI智慧提示")
                                .font(.appCallout())
                        }
                        .foregroundStyle(Color.modernSpecial)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background {
                            Capsule()
                                .fill(Color.modernSpecial.opacity(0.1))
                                .overlay {
                                    Capsule()
                                        .stroke(Color.modernSpecial.opacity(0.3), lineWidth: 1)
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
                            .font(.appHeadline())
                            .foregroundStyle(Color.modernWarning)
                        
                        Text("考點提示")
                            .font(.appHeadline())
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showBasicHint = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.appHeadline())
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text(hintText)
                        .font(.appBody())
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                }
                .padding(ModernSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: ModernRadius.md)
                        .fill(Color.modernWarning.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: ModernRadius.md)
                                .stroke(Color.modernWarning.opacity(0.3), lineWidth: 1)
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
                            .font(.appHeadline())
                            .foregroundStyle(Color.modernSpecial)
                        
                        Text("AI 智慧引導")
                            .font(.appHeadline())
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSmartHint = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.appHeadline())
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let error = smartHintError {
                        ModernErrorMessage(message: error)
                    } else if let smartHint = smartHintData {
                        VStack(alignment: .leading, spacing: 16) {
                            // 主要引導提示
                            Text(smartHint.smartHint)
                                .font(.appBody())
                                .foregroundStyle(.primary)
                                .lineSpacing(2)
                            
                            // 思考問題
                            if !smartHint.thinkingQuestions.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("思考一下：")
                                        .font(.appCallout())
                                        .foregroundStyle(Color.modernSpecial)
                                    
                                    ForEach(Array(smartHint.thinkingQuestions.enumerated()), id: \.offset) { index, question in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("\(index + 1).")
                                                .font(.appSubheadline())
                                                .foregroundStyle(Color.modernSpecial)
                                            
                                            Text(question)
                                                .font(.appSubheadline())
                                                .foregroundStyle(.primary)
                                                .lineSpacing(1)
                                        }
                                    }
                                }
                            }
                            
                            // 鼓勵話語
                            if !smartHint.encouragement.isEmpty {
                                Text(smartHint.encouragement)
                                    .font(.appSubheadline())
                                    .foregroundStyle(.secondary)
                                    .italic()
                                    .padding(ModernSpacing.sm)
                                    .background {
                                        RoundedRectangle(cornerRadius: ModernRadius.sm)
                                            .fill(Color.modernSpecial.opacity(0.08))
                                    }
                            }
                        }
                    }
                }
                .padding(ModernSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: ModernRadius.md)
                        .fill(Color.modernSpecial.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: ModernRadius.md)
                                .stroke(Color.modernSpecial.opacity(0.3), lineWidth: 1)
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
        
        guard let url = URL(string: "\(APIConfig.apiBaseURL)/api/session/get_smart_hint") else {
            smartHintError = "無效的網址"
            isLoadingSmartHint = false
            return
        }
        
        let body: [String: Any] = [
            "chinese_sentence": chineseSentence,
            "user_current_input": userAnswer,
            "original_hint": hintText,
            "model_name": SettingsManager.shared.generationModel.rawValue
        ]
        
        do {
            let bodyData = try JSONSerialization.data(withJSONObject: body, options: [])
            let (data, response) = try await NetworkManager.shared.performPOSTRequest(url: url, body: bodyData, requireAuth: false)
            
            try NetworkManager.shared.validateHTTPResponse(response, data: data)
            let smartResponse = try NetworkManager.shared.safeDecodeJSON(data, as: SmartHintResponse.self)
            
            await MainActor.run {
                self.smartHintData = smartResponse
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

struct ModernAnswerCard: View {
    @Binding var userAnswer: String
    let isLoading: Bool
    let errorMessage: String?
    @Binding var showKeyboard: Bool
    let onSubmit: () -> Void
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // 標題
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .font(.appBody())
                    .foregroundStyle(Color.modernAccent)
                
                Text("您的翻譯")
                    .font(.appBody(for: "您的翻譯"))
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            // 輸入區域
            VStack(spacing: 16) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: ModernRadius.md)
                        .fill(Color.modernSurface.opacity(0.7))
                        .overlay {
                            RoundedRectangle(cornerRadius: ModernRadius.md)
                                .stroke(showKeyboard ? Color.modernAccent : Color.clear, lineWidth: 2)
                        }
                        .frame(minHeight: 120)
                    
                    if userAnswer.isEmpty {
                        Text("請在此輸入您的英文翻譯...")
                            .font(.appBody(for: "請在此輸入您的英文翻譯..."))
                            .foregroundStyle(Color.secondary.opacity(0.6))
                            .padding(ModernSpacing.md)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $userAnswer)
                        .font(.appBody())
                        .scrollContentBackground(.hidden)
                        .padding(ModernSpacing.sm + 4)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isTextEditorFocused)
                        .onChange(of: isTextEditorFocused) { _, newValue in
                            showKeyboard = newValue
                        }
                }
                
                // 字數統計
                HStack {
                    Spacer()
                    Text("\(userAnswer.count) 字元")
                        .font(.appCaption())
                        .fontWeight(.medium)
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
                                .font(.appCallout(for: "✓"))
                            Text("提交批改")
                        }
                    }
                    .font(.appCallout())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: ModernRadius.md)
                            .fill(userAnswer.isEmpty ? Color.modernBorder : Color.modernAccent)
                    }
                }
                .disabled(isLoading || userAnswer.isEmpty)
                
                // 錯誤訊息
                if let errorMessage = errorMessage {
                    ModernErrorMessage(message: errorMessage)
                }
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .modernShadow()
        }
    }
}

struct ModernErrorMessage: View {
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.appCallout())
                .foregroundStyle(Color.modernError)
                .padding(.top, 1)
            
            Text(message)
                .font(.appSubheadline())
                .foregroundStyle(Color.modernError)
                .lineSpacing(1)
        }
        .padding(ModernSpacing.sm + 4)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.sm)
                .fill(Color.modernError.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: ModernRadius.sm)
                        .stroke(Color.modernError.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

struct FeedbackCard: View {
    let feedback: FeedbackResponse
    let questionData: Question
    let userAnswer: String
    @Binding var savedKnowledgePointsCount: Int
    @Binding var showSaveSuccessAlert: Bool
    @Binding var isLocalStorage: Bool
    let isAuthenticated: Bool
    
    @State private var editableErrors: [ErrorAnalysis] = []
    @State private var isEditMode: Bool = false
    @State private var selectedForMerge: Set<UUID> = []
    @State private var isMerging: Bool = false
    @State private var mergeError: String?
    @State private var isSaving: Bool = false
    @State private var saveTask: Task<Void, Never>?
    @State private var saveMessage: String?
    @State private var showSaveAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            // 【修改】Claude 風格的整體評估 - 傳入 questionData 參數
            ModernOverallAssessment(feedback: feedback, questionData: questionData)
            
            // Claude 風格的錯誤分析（保持不變）
            if !editableErrors.isEmpty {
                ErrorAnalysisCard(
                    editableErrors: $editableErrors,
                    isEditMode: $isEditMode,
                    selectedForMerge: $selectedForMerge,
                    isMerging: $isMerging,
                    mergeError: $mergeError,
                    onMerge: performMerge
                )
                
                // Claude 風格的儲存區域（保持不變）
                ModernSaveSection(
                    editableErrors: editableErrors,
                    isSaving: isSaving,
                    saveMessage: saveMessage,
                    isAuthenticated: isAuthenticated,
                    onSave: { showSaveAlert = true }
                )
            } else {
                ModernNoErrorsCard()
            }
        }
        .onAppear {
            editableErrors = feedback.errorAnalysis
        }
        .alert("確認儲存", isPresented: $showSaveAlert) {
            Button("取消", role: .cancel) { }
            Button("確認") {
                Task {
                    await saveToKnowledgeBase(isAuthenticated: isAuthenticated, userEmail: nil)
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
            let mergedError = try await UnifiedAPIService.shared.mergeErrors(error1: error1, error2: error2)
            
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
    
    @MainActor
    private func saveToKnowledgeBase(isAuthenticated: Bool, userEmail: String?) async {
        // Cancel any existing save task
        saveTask?.cancel()
        
        saveTask = Task {
            isSaving = true
            saveMessage = nil
            
            Logger.info("開始儲存\(editableErrors.count)個知識點", category: .database)
            Logger.info("當前認證狀態: \(isAuthenticated ? "已認證" : "未認證")", category: .authentication)
            if isAuthenticated {
                Logger.info("登入用戶: \(userEmail ?? "unknown")", category: .authentication)
            }
            
            let questionDataDict: [String: Any?] = [
                "new_sentence": questionData.newSentence,
                "type": questionData.type,
                "hint_text": questionData.hintText,
                "knowledge_point_id": questionData.knowledgePointId,
                "mastery_level": questionData.masteryLevel
            ]
            
            do {
                // Check for cancellation
                guard !Task.isCancelled else {
                    Logger.info("儲存任務已取消", category: .general)
                    return
                }
                
                let questionDataStruct = QuestionData(from: questionDataDict)
                let finalizationRequest = KnowledgePointFinalizationRequest(
                    errorAnalyses: editableErrors,
                    questionData: questionDataStruct,
                    userAnswer: userAnswer
                )
                let savedCount = try await UnifiedAPIService.shared.finalizeKnowledgePoints(request: finalizationRequest)
                
                // Check for cancellation again after async operation
                guard !Task.isCancelled else {
                    Logger.info("API 呼叫後儲存任務已取消", category: .api)
                    return
                }
                
                await MainActor.run {
                    // Check if local storage was used (negative return value)
                    if savedCount < 0 {
                        isLocalStorage = true
                        savedKnowledgePointsCount = abs(savedCount)
                        saveMessage = "已儲存至本地 \(abs(savedCount)) 個知識點"
                        Logger.success("知識點已儲存至本地，數量: \(abs(savedCount))", category: .database)
                    } else {
                        isLocalStorage = false
                        savedKnowledgePointsCount = savedCount
                        saveMessage = "成功儲存 \(savedCount) 個知識點"
                        Logger.success("知識點已儲存至雲端，數量: \(savedCount)", category: .database)
                    }
                    
                    showSaveSuccessAlert = true
                    
                    // Add haptic feedback for success
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.easeInOut(duration: 0.5)) {
                        editableErrors.removeAll()
                    }
                }
                
            } catch is CancellationError {
                Logger.info("儲存操作已取消", category: .general)
            } catch let apiError as APIError {
                await MainActor.run {
                    switch apiError {
                    case .requestFailed(let underlyingError):
                        saveMessage = "網路請求失敗：\(underlyingError.localizedDescription)"
                    case .serverError(let statusCode, let message):
                        saveMessage = "伺服器錯誤 (\(statusCode)): \(message)"
                    case .decodingError:
                        saveMessage = "資料解析錯誤，請稍後再試"
                    case .invalidURL:
                        saveMessage = "無效的網址配置"
                    case .invalidResponse:
                        saveMessage = "無效的伺服器回應"
                    case .unknownError:
                        saveMessage = "未知錯誤，請稍後再試"
                    }
                }
            } catch {
                await MainActor.run {
                    saveMessage = "儲存失敗：\(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isSaving = false
            }
        }
        
        await saveTask?.value
    }
}

struct ModernOverallAssessment: View {
    let feedback: FeedbackResponse
    let questionData: Question  // 新增這個參數，用於判斷題目類型
    
    var body: some View {
        VStack(spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "sparkles")
                    .font(.appTitle3())
                    .foregroundStyle(Color.modernAccent)
                
                Text("AI 家教點評")
                    .font(.appTitle3())
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            // 【新增】複習題專屬區域
            if questionData.type == "review" {
                ModernReviewResultCard(
                    feedback: feedback,
                    questionData: questionData
                )
            }
            
            // 評估結果（原有的，但針對複習題略做調整）
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(feedback.isGenerallyCorrect ? Color.modernSuccess.opacity(0.15) : Color.modernAccent.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: feedback.isGenerallyCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.appTitle2())
                        .foregroundStyle(feedback.isGenerallyCorrect ? Color.modernSuccess : Color.modernAccent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(feedback.isGenerallyCorrect ? "整體大致正確" : "存在主要錯誤")
                        .font(.appHeadline())
                        .foregroundStyle(.primary)
                    
                    // 【修改】根據題目類型顯示不同的描述
                    Text(questionData.type == "review" ? "複習題批改完成" : "AI 已完成詳細分析")
                        .font(.appSubheadline())
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // 建議翻譯
            VStack(alignment: .leading, spacing: 8) {
                Text("整體建議翻譯：")
                    .font(.appCallout())
                    .foregroundStyle(.secondary)
                
                Text(feedback.overallSuggestion)
                    .font(.appBody())
                    .foregroundStyle(.primary)
                    .lineSpacing(2)
                    .padding(ModernSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: ModernRadius.md)
                            .fill(Color.modernSurface.opacity(0.7))
                    }
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .modernShadow()
        }
    }
}

struct ModernReviewResultCard: View {
    let feedback: FeedbackResponse
    let questionData: Question
    
    private var masteryChange: String {
        // 根據複習結果顯示熟練度變化
        if feedback.didMasterReviewConcept == true {
            return "熟練度提升！"
        } else if feedback.isGenerallyCorrect {
            return "輕微進步"
        } else {
            return "需要再次複習"
        }
    }
    
    private var masteryColor: Color {
        if feedback.didMasterReviewConcept == true {
            return Color.modernSuccess
        } else if feedback.isGenerallyCorrect {
            return Color.modernSpecial
        } else {
            return Color.modernAccent
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 複習題標示
            HStack {
                Image(systemName: "arrow.clockwise")
                    .font(.appCallout())
                    .foregroundStyle(Color.modernSuccess)
                
                Text("複習題結果")
                    .font(.appHeadline(for: "複習題結果"))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // 【明顯標示】正確/錯誤指示器
                HStack(spacing: 6) {
                    Image(systemName: feedback.isGenerallyCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.appHeadline())
                        .foregroundStyle(feedback.isGenerallyCorrect ? Color.modernSuccess : Color.modernError)
                    
                    Text(feedback.isGenerallyCorrect ? "答對" : "答錯")
                        .font(.appCallout())
                        .foregroundStyle(feedback.isGenerallyCorrect ? Color.modernSuccess : Color.modernError)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill((feedback.isGenerallyCorrect ? Color.modernSuccess : Color.modernError).opacity(0.15))
                }
            }
            
            // 【新增】熟練度變化顯示
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("學習成果")
                        .font(.appCaption())
                        .foregroundStyle(.secondary)
                    
                    Text(masteryChange)
                        .font(.appCallout())
                        .foregroundStyle(masteryColor)
                }
                
                Spacer()
                
                // 【新增】熟練度進度條
                if let masteryLevel = questionData.masteryLevel {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("熟練度")
                            .font(.appCaption())
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 4) {
                            Text("\(Int(masteryLevel * 100))%")
                                .font(.appCaption())
                                .foregroundStyle(masteryColor)
                            
                            ProgressView(value: masteryLevel, total: 1.0)
                                .progressViewStyle(.linear)
                                .tint(masteryColor)
                                .frame(width: 60)
                                .scaleEffect(y: 1.5)
                        }
                    }
                }
            }
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: ModernRadius.md)
                        .stroke(masteryColor.opacity(0.3), lineWidth: 1.5)
                }
        }
    }
}


struct ErrorAnalysisCard: View {
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
                    .font(.appTitle3())
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if !editableErrors.isEmpty {
                    HStack(spacing: 12) {
                        // 編輯提示
                        if isEditMode && !editableErrors.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle.fill")
                                    .font(.appCaption())
                                    .foregroundStyle(Color.orange)
                                Text("記得儲存")
                                    .font(.appCaption())
                                    .foregroundStyle(Color.orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background {
                                Capsule()
                                    .fill(Color.orange.opacity(0.15))
                            }
                        }
                        
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
                                            .font(.appCaption())
                                    }
                                    Text("合併")
                                        .font(.appCaption())
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background {
                                    Capsule()
                                        .fill(Color.modernSpecial)
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
                                .font(.appCallout())
                                .foregroundStyle(Color.modernAccent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background {
                                    Capsule()
                                        .fill(Color.modernAccent.opacity(0.15))
                                }
                        }
                    }
                }
            }
            
            // 合併錯誤訊息
            if let mergeError = mergeError {
                ModernErrorMessage(message: mergeError)
            }
            
            // 錯誤列表
            LazyVStack(spacing: 12) {
                ForEach(editableErrors) { error in
                    ModernErrorAnalysisRow(
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
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .modernShadow()
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

struct ModernErrorAnalysisRow: View {
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
                        .font(.appTitle3())
                        .foregroundStyle(isSelected ? Color.modernSpecial : Color.secondary.opacity(0.6))
                }
                .padding(.trailing, 16)
            }
            
            // 錯誤內容
            VStack(alignment: .leading, spacing: 12) {
                // 分類標籤
                HStack(spacing: 8) {
                    Image(systemName: error.categoryIcon)
                        .font(.appCaption())
                    
                    Text(error.categoryName)
                        .font(.appCaption())
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
                Text(error.keyPointSummary)
                    .font(.appHeadline())
                    .foregroundStyle(.primary)
                
                // 錯誤與修正
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("原文：")
                            .font(.appSubheadline())
                            .foregroundStyle(.secondary)
                        
                        Text("\"\(error.originalPhrase)\"")
                            .font(.appSubheadline())
                            .foregroundStyle(Color.modernError)
                            .strikethrough(color: Color.modernError)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("修正：")
                            .font(.appSubheadline())
                            .foregroundStyle(.secondary)
                        
                        Text("\"\(error.correction)\"")
                            .font(.appSubheadline())
                            .foregroundStyle(Color.modernSuccess)
                    }
                }
                
                // 解釋
                Text(error.explanation)
                    .font(.appSubheadline())
                    .foregroundStyle(.secondary)
                    .lineSpacing(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 刪除按鈕（編輯模式）
            if isEditMode {
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.appHeadline())
                        .foregroundStyle(Color.modernError)
                }
                .padding(.leading, 16)
            }
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: ModernRadius.md)
                            .stroke(Color.modernSpecial, lineWidth: 2)
                    }
                }
        }
    }
}

struct ModernNoErrorsCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.appLargeTitle())
                .foregroundStyle(Color.modernSuccess)
            
            Text("恭喜！")
                .font(.appTitle2())
                .foregroundStyle(.primary)
            
            Text("AI 沒有發現任何錯誤")
                .font(.appBody())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(ModernSpacing.xl)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSuccess.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: ModernRadius.lg)
                        .stroke(Color.modernSuccess.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

struct ModernSaveSection: View {
    let editableErrors: [ErrorAnalysis]
    let isSaving: Bool
    let saveMessage: String?
    let isAuthenticated: Bool
    let onSave: () -> Void
    
    @State private var pulseAnimation = false
    @State private var showLoginPrompt = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 醒目提示區
            if !editableErrors.isEmpty && !isSaving {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Color.orange)
                    Text("有 \(editableErrors.count) 個錯誤分析待儲存")
                        .font(.appCallout())
                        .foregroundStyle(Color.orange)
                    Spacer()
                }
                .padding(ModernSpacing.sm)
                .background {
                    RoundedRectangle(cornerRadius: ModernRadius.sm)
                        .fill(Color.orange.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: ModernRadius.sm)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        }
                }
            }
            
            Button(action: isAuthenticated ? onSave : { showLoginPrompt = true }) {
                HStack(spacing: 12) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                        Text("儲存中...")
                    } else if !isAuthenticated {
                        Image(systemName: "lock.fill")
                            .font(.appHeadline())
                        Text("登入後即可儲存")
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.appHeadline())
                        Text("確認儲存到知識庫")
                    }
                }
                .font(.appHeadline())
                .foregroundStyle(isAuthenticated ? .white : Color.modernTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: ModernRadius.md)
                        .fill(isAuthenticated ? (editableErrors.isEmpty ? Color.modernBorder : Color.modernSuccess) : Color.modernBorder.opacity(0.5))
                        .scaleEffect(pulseAnimation && !editableErrors.isEmpty ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                }
            }
            .disabled(editableErrors.isEmpty || isSaving)
            .onAppear {
                if !editableErrors.isEmpty {
                    pulseAnimation = true
                }
            }
            
            if let saveMessage = saveMessage {
                Text(saveMessage)
                    .font(.appSubheadline())
                    .foregroundStyle(saveMessage.contains("成功") ? Color.modernSuccess : Color.modernError)
                    .padding(ModernSpacing.sm + 4)
                    .background {
                        RoundedRectangle(cornerRadius: ModernRadius.sm)
                            .fill((saveMessage.contains("成功") ? Color.modernSuccess : Color.modernError).opacity(0.1))
                    }
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .modernShadow()
        }
        .alert("需要登入", isPresented: $showLoginPrompt) {
            Button("稍後") { }
            Button("登入/註冊") {
                // 這裡可以添加導航到登入/註冊頁面的邏輯
            }
        } message: {
            Text("需要登入才能將知識點儲存到雲端資料庫。訪客模式的學習記錄將僅保存在本地。")
        }
    }
}

#Preview {
    NavigationView {
        AnswerView(sessionQuestionId: UUID())
            .environmentObject(SessionManager())
            .environmentObject(AuthenticationManager.shared)
    }
}
