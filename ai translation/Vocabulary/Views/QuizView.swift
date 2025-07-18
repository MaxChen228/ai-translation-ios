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
        .background(Color(.systemGroupedBackground))
        .onAppear {
            startTime = Date()
            questionStartTime = Date()
        }
    }
    
    // MARK: - 頂部導航
    
    private var topNavigationBar: some View {
        HStack {
            Button("結束") {
                dismiss()
            }
            .foregroundColor(.red)
            
            Spacer()
            
            Text(type == .multipleChoice ? "選擇題測驗" : "語境填空")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(currentIndex + 1)/\(quiz.questions.count)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    // MARK: - 進度條
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("已完成 \(currentIndex)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("正確率: \(currentIndex > 0 ? Int(Double(correctAnswers) / Double(currentIndex) * 100) : 0)%")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - 問題區域
    
    private func questionArea(question: QuizQuestion, in geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 24) {
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
            .padding()
        }
    }
    
    // MARK: - 問題卡片
    
    private func questionCard(question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            // 單字或問題
            if type == .multipleChoice {
                VStack(spacing: 12) {
                    Text(question.word)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if let pronunciation = question.pronunciation {
                        Text("/\(pronunciation)/")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    if let partOfSpeech = question.partOfSpeech {
                        Text(partOfSpeech)
                            .font(.headline)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Text("選擇正確的中文意思：")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                // 語境填空
                VStack(spacing: 12) {
                    Text("在下列句子中填入正確的單字：")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let questionSentence = question.questionSentence {
                        Text(questionSentence)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let hints = question.hints, !hints.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("提示：")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            ForEach(hints, id: \.self) { hint in
                                Text("• \(hint)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 選擇題選項
    
    private func multipleChoiceOptions(question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
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
            HStack {
                // 選項標記
                ZStack {
                    Circle()
                        .fill(backgroundColor(isSelected: isSelected, isCorrect: isCorrect))
                        .frame(width: 28, height: 28)
                    
                    Text(optionLabel(for: index))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor(isSelected: isSelected, isCorrect: isCorrect))
                }
                
                // 選項文字
                Text(text)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(textColor(isSelected: isSelected, isCorrect: isCorrect))
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // 結果圖示
                if showingResult {
                    if isCorrect == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if isSelected && isCorrect == false {
                        Image(systemName: "x.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(backgroundFillColor(isSelected: isSelected, isCorrect: isCorrect))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor(isSelected: isSelected, isCorrect: isCorrect), lineWidth: 2)
            )
        }
        .disabled(isAnswered)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 語境填空輸入
    
    private func contextFillInput(question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            TextField("請輸入單字", text: $userInput)
                .font(.title2)
                .fontWeight(.medium)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .disabled(isAnswered)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !userInput.isEmpty && !isAnswered {
                Text("你的答案：\(userInput)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - 結果卡片
    
    private func resultCard(question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            // 結果標題
            HStack {
                Image(systemName: isCorrectAnswer(question: question) ? "checkmark.circle.fill" : "x.circle.fill")
                    .font(.title)
                    .foregroundColor(isCorrectAnswer(question: question) ? .green : .red)
                
                Text(isCorrectAnswer(question: question) ? "答對了！" : "答錯了")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isCorrectAnswer(question: question) ? .green : .red)
                
                Spacer()
            }
            
            // 正確答案
            if type == .contextFill {
                VStack(alignment: .leading, spacing: 8) {
                    Text("正確答案：")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let targetWord = question.targetWord {
                        Text(targetWord)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    if let completeSentence = question.completeSentence {
                        Text("完整句子：")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(completeSentence)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // 解釋
            if let explanation = question.explanation {
                VStack(alignment: .leading, spacing: 4) {
                    Text("解釋：")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(explanation)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 底部控制區域
    
    private var bottomControlArea: some View {
        VStack(spacing: 16) {
            if !isAnswered {
                // 提交答案按鈕
                Button(action: submitAnswer) {
                    HStack {
                        if isSubmittingReview {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Text("提交答案")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(canSubmit ? Color.blue : Color.gray)
                    .cornerRadius(16)
                }
                .disabled(!canSubmit || isSubmittingReview)
            } else {
                // 下一題按鈕
                Button(action: nextQuestion) {
                    HStack {
                        Text(currentIndex < quiz.questions.count - 1 ? "下一題" : "完成測驗")
                            .fontWeight(.semibold)
                        
                        Image(systemName: currentIndex < quiz.questions.count - 1 ? "arrow.right" : "checkmark")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue)
                    .cornerRadius(16)
                }
            }
        }
        .padding()
    }
    
    // MARK: - 完成頁面
    
    private var studyCompleteView: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("🎉 測驗完成！")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Text("答對率: \(Int(Double(correctAnswers) / Double(quiz.questions.count) * 100))%")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(correctAnswers >= quiz.questions.count / 2 ? .green : .orange)
                
                Text("共完成 \(quiz.questions.count) 題")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("測驗時間: \(formatStudyTime())")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Button(action: completeStudy) {
                Text("完成學習")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue)
                    .cornerRadius(16)
            }
        }
        .padding()
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
    
    private func backgroundColor(isSelected: Bool, isCorrect: Bool?) -> Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green : (isSelected ? .red : .gray)
        }
        return isSelected ? .blue : .gray
    }
    
    private func textColor(isSelected: Bool, isCorrect: Bool?) -> Color {
        if showingResult {
            if let isCorrect = isCorrect {
                return isCorrect ? .white : (isSelected ? .white : .primary)
            }
        }
        return isSelected ? .white : .primary
    }
    
    private func backgroundFillColor(isSelected: Bool, isCorrect: Bool?) -> Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green.opacity(0.1) : (isSelected ? .red.opacity(0.1) : .clear)
        }
        return isSelected ? .blue.opacity(0.1) : .clear
    }
    
    private func borderColor(isSelected: Bool, isCorrect: Bool?) -> Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green : (isSelected ? .red : .gray.opacity(0.3))
        }
        return isSelected ? .blue : .gray.opacity(0.3)
    }
}
