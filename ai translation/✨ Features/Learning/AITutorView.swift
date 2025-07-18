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
                        ClaudeQuestionGenerationStatus()
                    }
                    if showStartLearning && sessionManager.sessionQuestions.isEmpty {
                        // Claude 風格的開始學習卡片
                        ClaudeStartLearningCard(
                            isLoading: isLoading,
                            errorMessage: errorMessage,
                            onStartLearning: {
                                Task {
                                    await fetchQuestions()
                                }
                            }
                        )
                        
                        // Claude 風格的設定預覽卡片
                        ClaudeSettingsPreviewCard()
                        
                    } else if sessionManager.sessionQuestions.isEmpty {
                        // 空狀態
                        ClaudeEmptyLearningState {
                            showStartLearning = true
                        }
                    } else {
                        // Claude 風格的學習進度概覽
                        ClaudeLearningProgressCard(
                            sessionQuestions: sessionManager.sessionQuestions,
                            onNewSession: {
                                Task {
                                    await fetchQuestions()
                                }
                            }
                        )
                        
                        // Claude 風格的題目列表
                        ClaudeQuestionListCard(
                            sessionQuestions: sessionManager.sessionQuestions
                        )
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("🎯 AI 英文家教")
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

        guard var urlComponents = URLComponents(string: "\(APIConfig.apiBaseURL)/api/start_session") else {
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

struct ClaudeStartLearningCard: View {
    let isLoading: Bool
    let errorMessage: String?
    let onStartLearning: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 歡迎區塊
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.orange)
                    
                    Text("AI 英文家教")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                
                Text("個人化學習路徑，智慧複習系統")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 快速設定概覽
            ClaudeQuickStatsRow()
            
            // 開始學習按鈕
            Button(action: onStartLearning) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(isLoading ? "準備題目中..." : "開始學習")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.linearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                }
            }
            .disabled(isLoading)
            
            // 錯誤訊息
            if let errorMessage = errorMessage {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                        .padding(.top, 1)
                    
                    Text(errorMessage)
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
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct ClaudeQuickStatsRow: View {
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
            ClaudeQuickStat(title: "複習題", value: "\(settings.review)")
            ClaudeQuickStat(title: "新題目", value: "\(settings.new)")
            ClaudeQuickStat(title: "難度", value: "\(settings.difficulty)")
            ClaudeQuickStat(title: "長度", value: settings.length)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        }
    }
}

struct ClaudeQuickStat: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ClaudeSettingsPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.orange)
                
                Text("學習設定")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                NavigationLink(destination: SettingsView()) {
                    Text("調整")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.orange)
                }
            }
            
            Text("在設定中可以調整每次學習的題目數量、難度、句子長度等參數。")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct ClaudeEmptyLearningState: View {
    let onRestart: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.green)
            
            Text("學習回合已完成")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
            
            Text("準備好迎接新的挑戰了嗎？")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            
            Button(action: onRestart) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                    Text("開始新回合")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background {
                    Capsule()
                        .fill(Color.orange)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct ClaudeLearningProgressCard: View {
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
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.orange)
                
                Text("學習進度")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button(action: onNewSession) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                        Text("新回合")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                    }
                }
            }
            
            // 進度條和統計
            VStack(spacing: 12) {
                HStack {
                    Text("\(completedCount) / \(sessionQuestions.count) 題已完成")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(progressPercentage * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.orange)
                }
                
                ProgressView(value: progressPercentage)
                    .progressViewStyle(.linear)
                    .tint(Color.orange)
                    .scaleEffect(y: 1.5)
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

struct ClaudeQuestionListCard: View {
    let sessionQuestions: [SessionQuestion]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "list.bullet")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.orange)
                
                Text("題目列表")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(sessionQuestions.enumerated()), id: \.element.id) { index, sessionQuestion in
                    ClaudeQuestionItem(
                        sessionQuestion: sessionQuestion,
                        questionNumber: index + 1
                    )
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

struct ClaudeQuestionItem: View {
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
                    .fill(sessionQuestion.isCompleted ? Color.green : Color.orange)
                    .frame(width: 32, height: 32)
                
                if sessionQuestion.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(questionNumber)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // 中文句子預覽
                Text(sessionQuestion.question.new_sentence)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                // 題目標籤
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: sessionQuestion.question.type == "review" ? "arrow.clockwise" : "plus")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        
                        Text(sessionQuestion.question.type == "review" ? "複習題" : "新題目")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let hint = sessionQuestion.question.hint_text, !hint.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                            
                            Text("有提示")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        }
    }
}

#Preview {
    AITutorView()
        .environmentObject(SessionManager())
}
struct ClaudeQuestionGenerationStatus: View {
    @State private var animationScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 16) {
            // 動畫圖標
            HStack(spacing: 12) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.orange)
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
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("正在根據您的學習狀況設計個人化題目")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.linearGradient(
                    colors: [Color.orange.opacity(0.1), Color.red.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.linearGradient(
                            colors: [Color.orange.opacity(0.3), Color.red.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 1.5)
                }
        }
    }
}
