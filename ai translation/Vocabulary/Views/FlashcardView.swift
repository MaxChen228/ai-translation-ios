// AI-tutor-v1.0/ai translation/📚 Vocabulary/Views/FlashcardView.swift

import SwiftUI

struct FlashcardView: View {
    let quiz: QuizResponse
    let onComplete: (StudySummary) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vocabularyService = VocabularyService()
    
    @State private var currentIndex = 0
    @State private var isShowingAnswer = false
    @State private var correctAnswers = 0
    @State private var startTime = Date()
    @State private var cardStartTime = Date()
    @State private var studiedWords: [VocabularyWord] = []
    @State private var isSubmittingReview = false
    
    // 動畫狀態
    @State private var cardRotation: Double = 0
    @State private var showingEvaluation = false
    
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
                
                // 卡片區域
                if let question = currentQuestion {
                    cardArea(question: question, in: geometry)
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
            cardStartTime = Date()
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
            
            Text("翻卡練習")
                .font(.appHeadline(for: "翻卡練習"))
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
                
                Text("正確率: \(currentIndex > 0 ? Int(Double(correctAnswers) / Double(currentIndex) * 100) : 0)%")
                    .font(.appCaption(for: "正確率"))
                    .foregroundStyle(Color.modernAccent)
            }
        }
        .padding(.horizontal, ModernSpacing.md)
    }
    
    // MARK: - 卡片區域
    
    private func cardArea(question: QuizQuestion, in geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            
            // 翻卡
            ZStack {
                // 背面（答案）
                if isShowingAnswer {
                    answerCard(question: question)
                        .rotation3DEffect(.degrees(cardRotation), axis: (x: 0, y: 1, z: 0))
                        .opacity(cardRotation < 90 ? 0 : 1)
                } else {
                    // 正面（問題）
                    questionCard(question: question)
                        .rotation3DEffect(.degrees(cardRotation), axis: (x: 0, y: 1, z: 0))
                        .opacity(cardRotation > 90 ? 0 : 1)
                }
            }
            .frame(width: geometry.size.width * 0.9, height: min(geometry.size.height * 0.5, 400))
            .onTapGesture {
                flipCard()
            }
            
            // 翻卡提示
            if !isShowingAnswer {
                HStack {
                    Image(systemName: "hand.tap")
                        .foregroundStyle(Color.modernTextSecondary)
                    Text("點擊卡片查看答案")
                        .font(.appCaption(for: "提示文字"))
                        .foregroundStyle(Color.modernTextSecondary)
                }
                .padding(.top, 16)
            }
            
            Spacer()
        }
        .padding(ModernSpacing.md)
    }
    
    // MARK: - 問題卡片
    
    private func questionCard(question: QuizQuestion) -> some View {
        VStack(spacing: 20) {
            // 單字
            Text(question.word)
                .font(.appLargeTitle(for: question.word))
                .foregroundStyle(Color.modernTextPrimary)
            
            // 音標
            if let pronunciation = question.pronunciation {
                Text("/\(pronunciation)/")
                    .font(.appTitle2(for: "發音"))
                    .foregroundStyle(Color.modernSpecial)
            }
            
            // 詞性
            if let partOfSpeech = question.partOfSpeech {
                Text(partOfSpeech)
                    .font(.appHeadline(for: "詞性"))
                    .foregroundStyle(Color.modernAccent)
                    .padding(.horizontal, ModernSpacing.sm)
                    .padding(.vertical, ModernSpacing.xs)
                    .background {
                        RoundedRectangle(cornerRadius: ModernRadius.xs)
                            .fill(Color.modernAccentSoft)
                    }
            }
            
            // 提示文字
            VStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.appTitle())
                    .foregroundStyle(Color.modernAccent)
                
                Text("你知道這個單字的意思嗎？")
                    .font(.appSubheadline(for: "提示文字"))
                    .foregroundStyle(Color.modernTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(ModernSpacing.lg)
        .modernCard(.elevated)
    }
    
    // MARK: - 答案卡片
    
    private func answerCard(question: QuizQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 單字和音標
                VStack(spacing: 8) {
                    Text(question.word)
                        .font(.appTitle(for: question.word))
                        .foregroundStyle(Color.modernTextPrimary)
                    
                    if let pronunciation = question.pronunciation {
                        Text("/\(pronunciation)/")
                            .font(.appTitle3(for: "發音"))
                            .foregroundStyle(Color.modernSpecial)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // 中文定義
                if let definitionZH = question.definitionZH {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("中文意思")
                            .font(.appCaption(for: "標籤"))
                            .foregroundStyle(Color.modernTextSecondary)
                            .textCase(.uppercase)
                        
                        Text(definitionZH)
                            .font(.appTitle2(for: definitionZH))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.modernTextPrimary)
                    }
                }
                
                // 英文定義
                if let definitionEN = question.definitionEN {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("English Definition")
                            .font(.appCaption(for: "English Definition"))
                            .foregroundStyle(Color.modernTextSecondary)
                            .textCase(.uppercase)
                        
                        Text(definitionEN)
                            .font(.appSubheadline(for: definitionEN))
                            .foregroundStyle(Color.modernTextSecondary)
                    }
                }
                
                // 例句
                if let examples = question.examples, !examples.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("例句")
                            .font(.appCaption(for: "標籤"))
                            .foregroundStyle(Color.modernTextSecondary)
                            .textCase(.uppercase)
                        
                        ForEach(Array(examples.prefix(2).enumerated()), id: \.offset) { index, example in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(example.sentenceEN)
                                    .font(.appSubheadline(for: example.sentenceEN))
                                    .foregroundStyle(Color.modernTextPrimary)
                                
                                if let sentenceZH = example.sentenceZH {
                                    Text(sentenceZH)
                                        .font(.appCaption(for: sentenceZH))
                                        .foregroundStyle(Color.modernTextSecondary)
                                }
                            }
                            .padding(.vertical, 4)
                            
                            if index < examples.prefix(2).count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding(ModernSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modernCard(.elevated)
    }
    
    // MARK: - 底部控制區域
    
    private var bottomControlArea: some View {
        VStack(spacing: 20) {
            if isShowingAnswer && !showingEvaluation {
                // 評價按鈕
                VStack(spacing: 16) {
                    Text("你答對了嗎？")
                        .font(.appHeadline(for: "評價提示"))
                        .foregroundStyle(Color.modernTextPrimary)
                    
                    HStack(spacing: 20) {
                        // 錯誤按鈕
                        ModernButton(
                            "不知道",
                            icon: "x.circle.fill",
                            style: .primary,
                            backgroundColor: Color.modernError,
                            isEnabled: !isSubmittingReview
                        ) {
                            submitAnswer(isCorrect: false)
                        }
                        
                        // 正確按鈕
                        ModernButton(
                            "知道",
                            icon: "checkmark.circle.fill",
                            style: .primary,
                            backgroundColor: Color.modernSuccess,
                            isEnabled: !isSubmittingReview
                        ) {
                            submitAnswer(isCorrect: true)
                        }
                    }
                }
            }
            
            if showingEvaluation {
                // 下一題按鈕
                ModernButton(
                    "下一題",
                    icon: "arrow.right",
                    style: .primary
                ) {
                    nextCard()
                }
            }
        }
        .padding(ModernSpacing.md)
    }
    
    // MARK: - 完成頁面
    
    private var studyCompleteView: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.modernSpecial)
            
            Text("練習完成！")
                .font(.appLargeTitle(for: "完成標題"))
                .foregroundStyle(Color.modernTextPrimary)
            
            VStack(spacing: 12) {
                Text("答對率: \(Int(Double(correctAnswers) / Double(quiz.questions.count) * 100))%")
                    .font(.appTitle2(for: "答對率"))
                    .foregroundStyle(correctAnswers >= quiz.questions.count / 2 ? Color.modernSuccess : Color.modernWarning)
                
                Text("共完成 \(quiz.questions.count) 個單字")
                    .font(.appHeadline(for: "題目數量"))
                    .foregroundStyle(Color.modernTextSecondary)
                
                Text("學習時間: \(formatStudyTime())")
                    .font(.appSubheadline(for: "學習時間"))
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
    
    // MARK: - 方法
    
    private func flipCard() {
        guard !isShowingAnswer else { return }
        
        withAnimation(.easeInOut(duration: 0.6)) {
            cardRotation = 180
            isShowingAnswer = true
        }
    }
    
    private func submitAnswer(isCorrect: Bool) {
        guard let question = currentQuestion else { return }
        
        let responseTime = Date().timeIntervalSince(cardStartTime)
        
        if isCorrect {
            correctAnswers += 1
        }
        
        showingEvaluation = true
        
        // 提交到後端
        Task {
            await submitReviewToBackend(
                wordId: question.wordId,
                isCorrect: isCorrect,
                responseTime: responseTime
            )
        }
    }
    
    private func nextCard() {
        currentIndex += 1
        
        // 重置卡片狀態
        withAnimation(.easeInOut(duration: 0.3)) {
            cardRotation = 0
            isShowingAnswer = false
            showingEvaluation = false
        }
        
        cardStartTime = Date()
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
            reviewType: "flashcard",
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
}
