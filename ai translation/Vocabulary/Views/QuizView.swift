// AI-tutor-v1.0/ai translation/📚 Vocabulary/Views/QuizView.swift

import SwiftUI

struct QuizView: View {
    let quiz: QuizResponse
    let type: PracticeType
    let onComplete: (StudySummary) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vocabularyService = VocabularyService()
    
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var selectedIndex: Int?
    @State private var userInput: String = ""
    @State private var correctAnswers = 0
    @State private var startTime = Date()
    @State private var questionStartTime = Date()
    @State private var studiedWords: [VocabularyWord] = []
    @State private var isSubmittingReview = false
    @State private var showingResult = false
    @State private var isAnswered = false
    
    private var currentQuestion: QuizQuestion? {
        guard currentIndex < quiz.questions.count else { return nil }
        return quiz.questions[currentIndex]
    }
    
    private var progress: Double {
        Double(currentIndex) / Double(quiz.questions.count)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 頂部導航欄
                topNavigationBar
                
                // 進度條
                progressBar
                
                // 問題區域
                if let question = currentQuestion {
                    questionArea(question: question, in: geometry)
                } else {
                    studyCompleteView
                }
                
                Spacer()
                
                // 底部控制區域
                if currentQuestion != nil {
                    bottomControlArea
                }
            }
        }
        .background(Color.modernBackground)
        .onAppear {
            startTime = Date()
            questionStartTime = Date()
        }
    }
    
    // MARK: - 頂部導航
    
    private var topNavigationBar: some View {
        HStack {
            ModernButton(
                "結束",
                style: .tertiary
            ) {
                dismiss()
            }
            
            Spacer()
            
            Text(type == .multipleChoice ? "選擇題測驗" : "語境填空")
                .font(.appHeadline(for: "測驗標題"))
                .foregroundStyle(Color.modernTextPrimary)
            
            Spacer()
            
            Text("\(currentIndex + 1)/\(quiz.questions.count)")
                .font(.appSubheadline(for: "問題計數"))
                .foregroundStyle(Color.modernTextSecondary)
        }
        .padding(ModernSpacing.md)
    }
    
    // MARK: - 進度條
    
    private var progressBar: some View {
        VStack(spacing: ModernSpacing.xs) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.modernAccent))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("已完成 \(currentIndex)")
                    .font(.appCaption(for: "進度文字"))
                    .foregroundStyle(Color.modernTextSecondary)
                
                Spacer()
                
                Text("正確率: \(safeAccuracyPercentage)%")
                    .font(.appCaption(for: "正確率"))
                    .foregroundStyle(Color.modernAccent)
            }
        }
        .padding(.horizontal, ModernSpacing.md)
    }
    
    // MARK: - 問題區域
    
    private func questionArea(question: QuizQuestion, in geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: ModernSpacing.lg) {
                // 問題卡片
                questionCard(question: question)
                
                // 答題區域
                if type == .multipleChoice {
                    multipleChoiceOptions(question: question)
                } else {
                    contextFillInput(question: question)
                }
                
                // 結果顯示
                if showingResult {
                    resultCard(question: question)
                }
            }
            .padding(ModernSpacing.md)
        }
    }
    
    // MARK: - 問題卡片
    
    private func questionCard(question: QuizQuestion) -> some View {
        VStack(spacing: ModernSpacing.md) {
            // 單字或問題
            if type == .multipleChoice {
                VStack(spacing: ModernSpacing.sm) {
                    Text(question.word)
                        .font(.appLargeTitle(for: "測驗單字"))
                        .foregroundStyle(Color.modernTextPrimary)
                    
                    if let pronunciation = question.pronunciation {
                        Text("/\(pronunciation)/")
                            .font(.appTitle2(for: "單字發音"))
                            .foregroundStyle(Color.modernSpecial)
                    }
                    
                    if let partOfSpeech = question.partOfSpeech {
                        Text(partOfSpeech)
                            .font(.appCallout(for: "詞性標籤"))
                            .foregroundStyle(Color.modernAccent)
                            .padding(.horizontal, ModernSpacing.sm)
                            .padding(.vertical, ModernSpacing.xs)
                            .background {
                                RoundedRectangle(cornerRadius: ModernRadius.xs)
                                    .fill(Color.modernAccentSoft)
                            }
                    }
                    
                    Text("選擇正確的中文意思：")
                        .font(.appSubheadline(for: "選擇提示"))
                        .foregroundStyle(Color.modernTextSecondary)
                }
            } else {
                // 語境填空
                VStack(spacing: ModernSpacing.sm) {
                    Text("在下列句子中填入正確的單字：")
                        .font(.appHeadline(for: "填空提示"))
                        .foregroundStyle(Color.modernTextPrimary)
                    
                    if let questionSentence = question.questionSentence {
                        Text(questionSentence)
                            .font(.appTitle2(for: "問題句子"))
                            .foregroundStyle(Color.modernTextPrimary)
                            .padding(ModernSpacing.md)
                            .background {
                                RoundedRectangle(cornerRadius: ModernRadius.sm)
                                    .fill(Color.modernSurface)
                            }
                            .multilineTextAlignment(.center)
                    }
                    
                    if let hints = question.hints, !hints.isEmpty {
                        VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                            Text("提示：")
                                .font(.appCaption(for: "提示標籤"))
                                .foregroundStyle(Color.modernTextSecondary)
                            
                            ForEach(hints, id: \.self) { hint in
                                Text("• \(hint)")
                                    .font(.appCaption(for: "提示內容"))
                                    .foregroundStyle(Color.modernSpecial)
                            }
                        }
                        .padding(ModernSpacing.sm)
                        .background {
                            RoundedRectangle(cornerRadius: ModernRadius.xs)
                                .fill(Color.modernSpecialSoft)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(ModernSpacing.lg)
        .modernCard(.elevated)
    }
    
    // MARK: - 選擇題選項
    
    private func multipleChoiceOptions(question: QuizQuestion) -> some View {
        VStack(spacing: ModernSpacing.sm) {
            if let options = question.options {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    optionButton(
                        index: index,
                        text: option,
                        isSelected: selectedIndex == index,
                        isCorrect: showingResult ? index == question.correctIndex : nil
                    )
                }
            }
        }
    }
    
    private func optionButton(index: Int, text: String, isSelected: Bool, isCorrect: Bool?) -> some View {
        Button(action: {
            guard !isAnswered else { return }
            selectedIndex = index
            selectedAnswer = text
        }) {
            HStack(spacing: ModernSpacing.md) {
                // 選項標記
                ZStack {
                    Circle()
                        .fill(optionCircleBackgroundColor(isSelected: isSelected, isCorrect: isCorrect))
                        .frame(width: 28, height: 28)
                    
                    Text(optionLabel(for: index))
                        .font(.appHeadline(for: "選項標記"))
                        .foregroundStyle(optionCircleTextColor(isSelected: isSelected, isCorrect: isCorrect))
                }
                
                // 選項文字
                Text(text)
                    .font(.appHeadline(for: "選項文字"))
                    .foregroundStyle(optionTextColor(isSelected: isSelected, isCorrect: isCorrect))
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // 結果圖示
                if showingResult {
                    if isCorrect == true {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.appHeadline())
                            .foregroundStyle(Color.modernSuccess)
                    } else if isSelected && isCorrect == false {
                        Image(systemName: "xmark.circle.fill")
                            .font(.appHeadline())
                            .foregroundStyle(Color.modernError)
                    }
                }
            }
            .padding(ModernSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: ModernRadius.sm)
                    .fill(optionBackgroundColor(isSelected: isSelected, isCorrect: isCorrect))
                    .overlay {
                        RoundedRectangle(cornerRadius: ModernRadius.sm)
                            .stroke(optionBorderColor(isSelected: isSelected, isCorrect: isCorrect), lineWidth: 2)
                    }
            }
        }
        .disabled(isAnswered)
        .buttonStyle(.plain)
    }
    
    // MARK: - 語境填空輸入
    
    private func contextFillInput(question: QuizQuestion) -> some View {
        VStack(spacing: ModernSpacing.md) {
            TextField("請輸入單字", text: $userInput)
                .font(.appTitle2(for: "輸入文字"))
                .padding(ModernSpacing.md)
                .modernInput(isFocused: false)
                .disabled(isAnswered)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            if !userInput.isEmpty && !isAnswered {
                Text("你的答案：\(userInput)")
                    .font(.appSubheadline(for: "用戶答案"))
                    .foregroundStyle(Color.modernSpecial)
            }
        }
    }
    
    // MARK: - 結果卡片
    
    private func resultCard(question: QuizQuestion) -> some View {
        VStack(spacing: ModernSpacing.md) {
            // 結果標題
            HStack {
                Image(systemName: isCorrectAnswer(question: question) ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.appTitle())
                    .foregroundStyle(isCorrectAnswer(question: question) ? Color.modernSuccess : Color.modernError)
                
                Text(isCorrectAnswer(question: question) ? "答對了！" : "答錯了")
                    .font(.appTitle2(for: "結果標題"))
                    .foregroundStyle(isCorrectAnswer(question: question) ? Color.modernSuccess : Color.modernError)
                
                Spacer()
            }
            
            // 正確答案
            if type == .contextFill {
                VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                    Text("正確答案：")
                        .font(.appSubheadline(for: "正確答案標籤"))
                        .foregroundStyle(Color.modernTextSecondary)
                    
                    if let targetWord = question.targetWord {
                        Text(targetWord)
                            .font(.appTitle2(for: "正確答案"))
                            .foregroundStyle(Color.modernSuccess)
                    }
                    
                    if let completeSentence = question.completeSentence {
                        Text("完整句子：")
                            .font(.appCaption(for: "完整句子標籤"))
                            .foregroundStyle(Color.modernTextSecondary)
                        
                        Text(completeSentence)
                            .font(.appSubheadline(for: "完整句子"))
                            .foregroundStyle(Color.modernTextPrimary)
                    }
                }
            }
            
            // 解釋
            if let explanation = question.explanation {
                VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                    Text("解釋：")
                        .font(.appCaption(for: "解釋標籤"))
                        .foregroundStyle(Color.modernTextSecondary)
                    
                    Text(explanation)
                        .font(.appSubheadline(for: "解釋內容"))
                        .foregroundStyle(Color.modernTextPrimary)
                }
            }
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.sm)
                .fill(Color.modernSurface)
        }
    }
    
    // MARK: - 底部控制區域
    
    private var bottomControlArea: some View {
        VStack(spacing: ModernSpacing.md) {
            if !isAnswered {
                // 提交答案按鈕
                ModernButton(
                    isSubmittingReview ? "" : "提交答案",
                    style: canSubmit ? .primary : .secondary,
                    isLoading: isSubmittingReview,
                    isEnabled: canSubmit && !isSubmittingReview
                ) {
                    submitAnswer()
                }
            } else {
                // 下一題按鈕
                ModernButton(
                    currentIndex < quiz.questions.count - 1 ? "下一題" : "完成測驗",
                    icon: currentIndex < quiz.questions.count - 1 ? "arrow.right" : "checkmark",
                    style: .primary
                ) {
                    nextQuestion()
                }
            }
        }
        .padding(ModernSpacing.md)
    }
    
    // MARK: - 完成頁面
    
    private var studyCompleteView: some View {
        VStack(spacing: ModernSpacing.xxl) {
            Image(systemName: "star.circle.fill")
                .font(.appLargeTitle())
                .foregroundStyle(Color.modernSpecial)
            
            Text("測驗完成！")
                .font(.appLargeTitle(for: "完成標題"))
                .foregroundStyle(Color.modernTextPrimary)
            
            VStack(spacing: ModernSpacing.sm) {
                Text("答對率: \(safeFinalAccuracyPercentage)%")
                    .font(.appTitle2(for: "答對率"))
                    .foregroundStyle(correctAnswers >= quiz.questions.count / 2 ? Color.modernSuccess : Color.modernWarning)
                
                Text("共完成 \(quiz.questions.count) 題")
                    .font(.appHeadline(for: "題目數量"))
                    .foregroundStyle(Color.modernTextSecondary)
                
                Text("測驗時間: \(formatStudyTime())")
                    .font(.appSubheadline(for: "測驗時間"))
                    .foregroundStyle(Color.modernTextSecondary)
            }
            
            ModernButton(
                "完成學習",
                style: .primary
            ) {
                completeStudy()
            }
            .padding(.horizontal, ModernSpacing.lg)
        }
        .padding(ModernSpacing.lg)
    }
    
    // MARK: - 計算屬性
    
    private var canSubmit: Bool {
        if type == .multipleChoice {
            return selectedIndex != nil
        } else {
            return !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    // MARK: - 方法
    
    private func submitAnswer() {
        guard let question = currentQuestion else { return }
        
        let responseTime = Date().timeIntervalSince(questionStartTime)
        let isCorrect = isCorrectAnswer(question: question)
        
        if isCorrect {
            correctAnswers += 1
        }
        
        isAnswered = true
        showingResult = true
        
        // 提交到後端
        Task {
            await submitReviewToBackend(
                wordId: question.wordId,
                isCorrect: isCorrect,
                responseTime: responseTime
            )
        }
    }
    
    private func nextQuestion() {
        if currentIndex < quiz.questions.count - 1 {
            currentIndex += 1
            resetQuestionState()
        } else {
            // 完成測驗
            currentIndex += 1
        }
    }
    
    private func resetQuestionState() {
        selectedAnswer = nil
        selectedIndex = nil
        userInput = ""
        isAnswered = false
        showingResult = false
        questionStartTime = Date()
    }
    
    private func isCorrectAnswer(question: QuizQuestion) -> Bool {
        if type == .multipleChoice {
            return selectedIndex == question.correctIndex
        } else {
            let userAnswer = userInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let correctAnswer = question.targetWord?.lowercased() ?? ""
            return userAnswer == correctAnswer
        }
    }
    
    private func completeStudy() {
        let studyTime = Date().timeIntervalSince(startTime)
        let summary = StudySummary(
            totalQuestions: quiz.questions.count,
            correctAnswers: correctAnswers,
            studyTime: studyTime,
            wordsStudied: studiedWords
        )
        
        onComplete(summary)
    }
    
    @MainActor
    private func submitReviewToBackend(wordId: Int, isCorrect: Bool, responseTime: TimeInterval) async {
        isSubmittingReview = true
        
        let submission = ReviewSubmission(
            wordId: wordId,
            isCorrect: isCorrect,
            reviewType: type.rawValue,
            responseTime: responseTime
        )
        
        do {
            let result = try await vocabularyService.submitReview(submission: submission)
            studiedWords.append(result.updatedWord)
        } catch {
            print("提交複習結果失敗: \(error)")
        }
        
        isSubmittingReview = false
    }
    
    private func formatStudyTime() -> String {
        let totalSeconds = Int(Date().timeIntervalSince(startTime))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - 顏色和樣式輔助方法
    
    private func optionLabel(for index: Int) -> String {
        return String(UnicodeScalar(65 + index)!) // A, B, C, D
    }
    
    private func optionCircleBackgroundColor(isSelected: Bool, isCorrect: Bool?) -> Color {
        if let isCorrect = isCorrect {
            if isCorrect {
                return Color.modernSuccess
            } else if isSelected {
                return Color.modernError
            } else {
                return Color.modernTextTertiary
            }
        }
        return isSelected ? Color.modernAccent : Color.modernTextTertiary
    }
    
    private func optionCircleTextColor(isSelected: Bool, isCorrect: Bool?) -> Color {
        if showingResult {
            if let isCorrect = isCorrect {
                return isCorrect ? .white : (isSelected ? .white : Color.modernTextPrimary)
            }
        }
        return isSelected ? .white : Color.modernTextPrimary
    }
    
    private func optionTextColor(isSelected: Bool, isCorrect: Bool?) -> Color {
        if showingResult {
            if let isCorrect = isCorrect {
                return isCorrect ? Color.modernSuccess : (isSelected ? Color.modernError : Color.modernTextPrimary)
            }
        }
        return isSelected ? Color.modernAccent : Color.modernTextPrimary
    }
    
    private func optionBackgroundColor(isSelected: Bool, isCorrect: Bool?) -> Color {
        if let isCorrect = isCorrect {
            if isCorrect {
                return Color.modernSuccess.opacity(0.1)
            } else if isSelected {
                return Color.modernError.opacity(0.1)
            } else {
                return Color.modernSurface
            }
        }
        return isSelected ? Color.modernAccentSoft : Color.modernSurface
    }
    
    private func optionBorderColor(isSelected: Bool, isCorrect: Bool?) -> Color {
        if let isCorrect = isCorrect {
            if isCorrect {
                return Color.modernSuccess
            } else if isSelected {
                return Color.modernError
            } else {
                return Color.modernBorder
            }
        }
        return isSelected ? Color.modernAccent : Color.modernBorder
    }
    
    // MARK: - 安全計算方法
    
    private var safeAccuracyPercentage: Int {
        guard currentIndex > 0 else { return 0 }
        let accuracy = Double(correctAnswers) / Double(currentIndex) * 100
        if accuracy.isNaN || accuracy.isInfinite {
            return 0
        }
        return max(0, min(100, Int(accuracy.rounded())))
    }
    
    private var safeFinalAccuracyPercentage: Int {
        guard quiz.questions.count > 0 else { return 0 }
        let accuracy = Double(correctAnswers) / Double(quiz.questions.count) * 100
        if accuracy.isNaN || accuracy.isInfinite {
            return 0
        }
        return max(0, min(100, Int(accuracy.rounded())))
    }
}