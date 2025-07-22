// AI-tutor-v1.0/ai translation/📚 Vocabulary/Views/StudyModeSelectionView.swift

import SwiftUI

struct StudyModeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vocabularyService = VocabularyService()
    
    @State private var selectedStudyMode: StudyMode = .review
    @State private var selectedPracticeType: PracticeType = .flashcard
    @State private var wordCount: Int = 10
    @State private var selectedDifficulty: Int? = nil
    @State private var isStartingStudy = false
    @State private var errorMessage: String?
    
    // 導航狀態
    @State private var showingPractice = false
    @State private var generatedQuiz: QuizResponse?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ModernSpacing.lg) {
                    // 學習模式選擇
                    studyModeSection
                    
                    // 練習類型選擇
                    practiceTypeSection
                    
                    // 學習設定
                    settingsSection
                    
                    // 開始按鈕
                    startButton
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("選擇學習模式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPractice) {
            if let quiz = generatedQuiz {
                switch selectedPracticeType {
                case .flashcard:
                    FlashcardView(quiz: quiz, onComplete: handleStudyComplete)
                case .multipleChoice:
                    QuizView(quiz: quiz, type: .multipleChoice, onComplete: handleStudyComplete)
                case .contextFill:
                    QuizView(quiz: quiz, type: .contextFill, onComplete: handleStudyComplete)
                }
            }
        }
    }
    
    // MARK: - 學習模式選擇
    
    private var studyModeSection: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.md) {
            HStack {
                Image(systemName: "graduationcap")
                    .foregroundStyle(Color.modernAccent)
                Text("學習模式")
                    .font(.appHeadline())
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: ModernSpacing.md) {
                ForEach(StudyMode.allCases, id: \.self) { mode in
                    StudyModeCard(
                        mode: mode,
                        isSelected: selectedStudyMode == mode,
                        onTap: { selectedStudyMode = mode }
                    )
                }
            }
        }
        .padding()
        .background(Color.modernSurface)
        .cornerRadius(ModernRadius.md)
        .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
    }
    
    // MARK: - 練習類型選擇
    
    private var practiceTypeSection: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.md) {
            HStack {
                Image(systemName: "gamecontroller")
                    .foregroundStyle(Color.modernAccent)
                Text("練習類型")
                    .font(.appHeadline())
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: ModernSpacing.md) {
                ForEach(PracticeType.allCases, id: \.self) { type in
                    PracticeTypeCard(
                        type: type,
                        isSelected: selectedPracticeType == type,
                        onTap: { selectedPracticeType = type }
                    )
                }
            }
        }
        .padding()
        .background(Color.modernSurface)
        .cornerRadius(ModernRadius.md)
        .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
    }
    
    // MARK: - 設定區域
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.md) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(Color.modernAccent)
                Text("學習設定")
                    .font(.appHeadline())
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: ModernSpacing.md) {
                // 單字數量
                VStack(alignment: .leading, spacing: ModernSpacing.sm) {
                    Text("單字數量: \(wordCount)")
                        .font(.appSubheadline())
                        .fontWeight(.medium)
                    
                    Slider(value: Binding(
                        get: { Double(wordCount) },
                        set: { wordCount = Int($0) }
                    ), in: 5...20, step: 5)
                    .accentColor(Color.modernAccent)
                    
                    HStack {
                        Text("5")
                            .font(.appCaption())
                            .foregroundStyle(Color.modernTextSecondary)
                        Spacer()
                        Text("10")
                            .font(.appCaption())
                            .foregroundStyle(Color.modernTextSecondary)
                        Spacer()
                        Text("15")
                            .font(.appCaption())
                            .foregroundStyle(Color.modernTextSecondary)
                        Spacer()
                        Text("20")
                            .font(.appCaption())
                            .foregroundStyle(Color.modernTextSecondary)
                    }
                }
                
                Divider()
                
                // 難度選擇（專項練習時顯示）
                if selectedStudyMode == .targeted {
                    VStack(alignment: .leading, spacing: ModernSpacing.sm) {
                        Text("難度等級")
                            .font(.appSubheadline())
                            .fontWeight(.medium)
                        
                        HStack(spacing: ModernSpacing.sm) {
                            Button("全部") {
                                selectedDifficulty = nil
                            }
                            .buttonStyle(DifficultyButtonStyle(isSelected: selectedDifficulty == nil))
                            
                            ForEach(1...5, id: \.self) { level in
                                Button("\(level)") {
                                    selectedDifficulty = level
                                }
                                .buttonStyle(DifficultyButtonStyle(isSelected: selectedDifficulty == level))
                            }
                            
                            Spacer()
                        }
                        
                        Text("1=簡單, 5=困難")
                            .font(.appCaption())
                            .foregroundStyle(Color.modernTextSecondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.modernSurface)
        .cornerRadius(ModernRadius.md)
        .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
    }
    
    // MARK: - 開始按鈕
    
    private var startButton: some View {
        VStack(spacing: 12) {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.appCaption())
                    .foregroundStyle(Color.modernError)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: startStudy) {
                HStack {
                    if isStartingStudy {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    
                    Text(isStartingStudy ? "準備中..." : "開始學習")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isStartingStudy ? Color.modernTextSecondary : Color.modernAccent)
                .cornerRadius(ModernRadius.md)
            }
            .disabled(isStartingStudy)
            
            Text("根據你的選擇，將生成 \(wordCount) 個單字的 \(selectedPracticeType.displayName)")
                .font(.appCaption())
                .foregroundStyle(Color.modernTextSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - 方法
    
    private func startStudy() {
        Task {
            await generateAndStartQuiz()
        }
    }
    
    @MainActor
    private func generateAndStartQuiz() async {
        isStartingStudy = true
        errorMessage = nil
        
        do {
            let quiz = try await vocabularyService.generateQuiz(
                type: selectedPracticeType,
                wordCount: wordCount,
                difficultyLevel: selectedDifficulty
            )
            
            generatedQuiz = quiz
            showingPractice = true
            
        } catch {
            errorMessage = "生成測驗失敗: \(error.localizedDescription)"
        }
        
        isStartingStudy = false
    }
    
    private func handleStudyComplete(summary: StudySummary) {
        // 關閉練習界面
        showingPractice = false
        
        // 關閉選擇界面，回到主頁
        dismiss()
        
        // 這裡可以添加顯示學習總結的邏輯
        print("學習完成: \(summary.correctAnswers)/\(summary.totalQuestions)")
    }
}

// MARK: - 輔助元件

struct StudyModeCard: View {
    let mode: StudyMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ModernSpacing.md) {
                Image(systemName: mode.systemImageName)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color.modernAccent)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                    Text(mode.displayName)
                        .font(.appHeadline())
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? .white : Color.modernTextPrimary)
                    
                    Text(mode.description)
                        .font(.appCaption())
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : Color.modernTextSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.modernAccent : Color.modernSurface.opacity(0.7))
            .cornerRadius(ModernRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PracticeTypeCard: View {
    let type: PracticeType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ModernSpacing.md) {
                Image(systemName: type.systemImageName)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color.modernAccent)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                    Text(type.displayName)
                        .font(.appHeadline())
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? .white : Color.modernTextPrimary)
                    
                    Text(practiceDescription(for: type))
                        .font(.appCaption())
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : Color.modernTextSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.modernAccent : Color.modernSurface.opacity(0.7))
            .cornerRadius(ModernRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func practiceDescription(for type: PracticeType) -> String {
        switch type {
        case .flashcard:
            return "查看單字，回想中文意思"
        case .multipleChoice:
            return "選擇正確的中文意思"
        case .contextFill:
            return "在語境中填入正確單字"
        }
    }
}

struct DifficultyButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appCaption())
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : Color.modernAccent)
            .padding(.horizontal, ModernSpacing.md)
            .padding(.vertical, ModernSpacing.sm)
            .background(isSelected ? Color.modernAccent : Color.modernAccent.opacity(0.1))
            .cornerRadius(ModernRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
