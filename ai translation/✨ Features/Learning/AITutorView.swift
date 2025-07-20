// AITutorView.swift - 重命名後的 AI 家教主頁

import SwiftUI

struct AITutorView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showStartLearning = true

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    if isLoading {
                        ModernQuestionGenerationStatus()
                    }
                    if showStartLearning && sessionManager.sessionQuestions.isEmpty {
                        // Claude 風格的開始學習卡片
                        ModernStartLearningCard(
                            isLoading: isLoading,
                            errorMessage: errorMessage,
                            onStartLearning: {
                                Task {
                                    await fetchQuestions()
                                }
                            }
                        )
                        
                        // Claude 風格的設定預覽卡片
                        ModernSettingsPreviewCard()
                        
                    } else if sessionManager.sessionQuestions.isEmpty {
                        // 空狀態
                        ModernEmptyLearningState {
                            showStartLearning = true
                        }
                    } else {
                        // Claude 風格的學習進度概覽
                        ModernLearningProgressCard(
                            sessionQuestions: sessionManager.sessionQuestions,
                            onNewSession: {
                                Task {
                                    await fetchQuestions()
                                }
                            }
                        )
                        
                        // Claude 風格的題目列表
                        ModernQuestionListCard(
                            sessionQuestions: sessionManager.sessionQuestions
                        )
                    }
                }
                .padding(ModernSpacing.lg)
            }
            .background(Color.modernBackground)
            .navigationTitle("AI 英文家教")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    func fetchQuestions() async {
        isLoading = true
        errorMessage = nil
        showStartLearning = false

        let reviewCount = SettingsManager.shared.reviewCount
        let newCount = SettingsManager.shared.newCount
        let difficulty = SettingsManager.shared.difficulty
        let length = SettingsManager.shared.length.rawValue
        let generationModel = SettingsManager.shared.generationModel.rawValue

        guard var urlComponents = URLComponents(string: "\(APIConfig.apiBaseURL)/api/session/start_session") else {
            errorMessage = "無效的網址"
            isLoading = false
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "num_review", value: String(reviewCount)),
            URLQueryItem(name: "num_new", value: String(newCount)),
            URLQueryItem(name: "difficulty", value: String(difficulty)),
            URLQueryItem(name: "length", value: length),
            URLQueryItem(name: "generation_model", value: generationModel)
        ]
        
        guard let url = urlComponents.url else {
            errorMessage = "無法建立 URL"
            isLoading = false
            return
        }
        
        print("Requesting URL: \(url.absoluteString)")
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedResponse = try JSONDecoder().decode(QuestionsResponse.self, from: data)
            sessionManager.startNewSession(questions: decodedResponse.questions)
        } catch {
            self.errorMessage = "無法獲取題目，請檢查網路連線或稍後再試。\n(\(error.localizedDescription))"
            print("獲取題目時發生錯誤: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Claude 風格組件

struct ModernStartLearningCard: View {
    let isLoading: Bool
    let errorMessage: String?
    let onStartLearning: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 歡迎區塊
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.appTitle2())
                        .foregroundStyle(Color.modernAccent)
                    
                    Text("AI 英文家教")
                        .font(.appTitle2(for: "AI 英文家教"))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                
                Text("個人化學習路徑，智慧複習系統")
                    .font(.appSubheadline(for: "個人化學習路徑，智慧複習系統"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 快速設定概覽
            ModernQuickStatsRow()
            
            // 開始學習按鈕
            Button(action: onStartLearning) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "play.fill")
                            .font(.appCallout())
                    }
                    
                    Text(isLoading ? "準備題目中..." : "開始學習")
                        .font(.appCallout(for: isLoading ? "準備題目中..." : "開始學習"))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ModernSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: ModernRadius.md)
                        .fill(Color.modernAccent)
                }
            }
            .disabled(isLoading)
            
            // 錯誤訊息
            if let errorMessage = errorMessage {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.appCaption())
                        .foregroundStyle(Color.modernError)
                        .padding(.top, 1)
                    
                    Text(errorMessage)
                        .font(.appCaption(for: errorMessage))
                        .foregroundStyle(Color.modernError)
                        .lineSpacing(1)
                }
                .padding(ModernSpacing.md)
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
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .modernShadow()
        }
    }
}

struct ModernQuickStatsRow: View {
    private var settings: (review: Int, new: Int, difficulty: Int, length: String) {
        (
            SettingsManager.shared.reviewCount,
            SettingsManager.shared.newCount,
            SettingsManager.shared.difficulty,
            SettingsManager.shared.length.displayName
        )
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ModernQuickStat(title: "複習題", value: "\(settings.review)")
            ModernQuickStat(title: "新題目", value: "\(settings.new)")
            ModernQuickStat(title: "難度", value: "\(settings.difficulty)")
            ModernQuickStat(title: "長度", value: settings.length)
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
        }
    }
}

struct ModernQuickStat: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.appCallout(for: value))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.appCaption2(for: title))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ModernSettingsPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.appCallout())
                    .foregroundStyle(Color.modernAccent)
                
                Text("學習設定")
                    .font(.appHeadline(for: "學習設定"))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                NavigationLink(destination: SettingsView()) {
                    Text("調整")
                        .font(.appSubheadline(for: "調整"))
                        .foregroundStyle(Color.modernAccent)
                }
            }
            
            Text("在設定中可以調整每次學習的題目數量、難度、句子長度等參數。")
                .font(.appSubheadline(for: "在設定中可以調整每次學習的題目數量、難度、句子長度等參數。"))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .modernShadow()
        }
    }
}

struct ModernEmptyLearningState: View {
    let onRestart: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.appLargeTitle())
                .foregroundStyle(Color.modernSuccess)
            
            Text("學習回合已完成")
                .font(.appTitle3(for: "學習回合已完成"))
                .foregroundStyle(.primary)
            
            Text("準備好迎接新的挑戰了嗎？")
                .font(.appSubheadline(for: "準備好迎接新的挑戰了嗎？"))
                .foregroundStyle(.secondary)
            
            Button(action: onRestart) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.appSubheadline(for: "🔄"))
                    Text("開始新回合")
                        .font(.appSubheadline(for: "開始新回合"))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, ModernSpacing.lg)
                .padding(.vertical, ModernSpacing.md)
                .background {
                    Capsule()
                        .fill(Color.modernAccent)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(ModernSpacing.xxl)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .modernShadow()
        }
    }
}

struct ModernLearningProgressCard: View {
    let sessionQuestions: [SessionQuestion]
    let onNewSession: () -> Void
    
    private var completedCount: Int {
        sessionQuestions.filter { $0.isCompleted }.count
    }
    
    private var progressPercentage: Double {
        sessionQuestions.isEmpty ? 0 : Double(completedCount) / Double(sessionQuestions.count)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 進度標題
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.appHeadline(for: "📈"))
                    .foregroundStyle(Color.modernAccent)
                
                Text("學習進度")
                    .font(.appTitle3(for: "學習進度"))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button(action: onNewSession) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.appCaption())
                        Text("新回合")
                            .font(.appSubheadline(for: "新回合"))
                    }
                    .foregroundStyle(Color.modernAccent)
                    .padding(.horizontal, ModernSpacing.md)
                    .padding(.vertical, ModernSpacing.sm)
                    .background {
                        Capsule()
                            .fill(Color.modernAccentSoft)
                    }
                }
            }
            
            // 進度條和統計
            VStack(spacing: 12) {
                HStack {
                    Text("\(completedCount) / \(sessionQuestions.count) 題已完成")
                        .font(.appCallout())
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(progressPercentage * 100))%")
                        .font(.appCallout())
                        .foregroundStyle(Color.modernAccent)
                }
                
                ProgressView(value: progressPercentage)
                    .progressViewStyle(.linear)
                    .tint(Color.modernAccent)
                    .scaleEffect(y: 1.5)
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

struct ModernQuestionListCard: View {
    let sessionQuestions: [SessionQuestion]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "list.bullet")
                    .font(.appHeadline())
                    .foregroundStyle(Color.modernAccent)
                
                Text("題目列表")
                    .font(.appTitle3(for: "題目列表"))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(sessionQuestions.enumerated()), id: \.element.id) { index, sessionQuestion in
                    ModernQuestionItem(
                        sessionQuestion: sessionQuestion,
                        questionNumber: index + 1
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
}

struct ModernQuestionItem: View {
    let sessionQuestion: SessionQuestion
    let questionNumber: Int
    
    var body: some View {
        NavigationLink(destination: AnswerView(sessionQuestionId: sessionQuestion.id)) {
            questionItemContent
        }
        .buttonStyle(.plain)
    }
    
    private var questionItemContent: some View {
        HStack(spacing: 16) {
            // 題目編號和狀態
            ZStack {
                Circle()
                    .fill(sessionQuestion.isCompleted ? Color.modernSuccess : Color.modernAccent)
                    .frame(width: 32, height: 32)
                
                if sessionQuestion.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.appSubheadline())
                        .foregroundStyle(.white)
                } else {
                    Text("\(questionNumber)")
                        .font(.appSubheadline())
                        .foregroundStyle(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // 中文句子預覽
                Text(sessionQuestion.question.new_sentence)
                    .font(.appCallout(for: sessionQuestion.question.new_sentence))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                // 題目標籤
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: sessionQuestion.question.type == "review" ? "arrow.clockwise" : "plus")
                            .font(.appCaption2(for: sessionQuestion.question.type == "review" ? "🔄" : "➕"))
                            .foregroundStyle(.secondary)
                        
                        Text(sessionQuestion.question.type == "review" ? "複習題" : "新題目")
                            .font(.appCaption2(for: sessionQuestion.question.type == "review" ? "複習題" : "新題目"))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let hint = sessionQuestion.question.hint_text, !hint.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.appCaption2())
                                .foregroundStyle(Color.modernWarning)
                            
                            Text("有提示")
                                .font(.appCaption2(for: "有提示"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.appCaption(for: "›"))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, ModernSpacing.lg)
        .padding(.vertical, ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
        }
    }
}

#Preview {
    AITutorView()
        .environmentObject(SessionManager())
}
struct ModernQuestionGenerationStatus: View {
    @State private var animationScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 16) {
            // 動畫圖標
            HStack(spacing: 12) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.modernAccent)
                        .frame(width: 12, height: 12)
                        .scaleEffect(animationScale)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animationScale
                        )
                }
            }
            .onAppear {
                animationScale = 0.5
            }
            
            // 狀態文字
            VStack(spacing: 8) {
                Text("正在出題...")
                    .font(.appHeadline(for: "正在出題..."))
                    .foregroundStyle(.primary)
                
                Text("正在根據您的學習狀況設計個人化題目")
                    .font(.appSubheadline(for: "正在根據您的學習狀況設計個人化題目"))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernAccentSoft)
                .overlay {
                    RoundedRectangle(cornerRadius: ModernRadius.lg)
                        .stroke(Color.modernAccent.opacity(0.3), lineWidth: 1.5)
                }
        }
    }
}
