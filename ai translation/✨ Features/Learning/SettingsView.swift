// SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var reviewCount: Int = SettingsManager.shared.reviewCount
    @State private var newCount: Int = SettingsManager.shared.newCount
    @State private var difficulty: Int = SettingsManager.shared.difficulty
    @State private var length: SettingsManager.SentenceLength = SettingsManager.shared.length
    @State private var dailyGoal: Int = SettingsManager.shared.dailyGoal
    @State private var generationModel: SettingsManager.AIModel = SettingsManager.shared.generationModel
    @State private var gradingModel: SettingsManager.AIModel = SettingsManager.shared.gradingModel
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // 使用者資料區塊
                    if let user = authManager.currentUser {
                        ClaudeUserProfileCard(user: user) {
                            showLogoutAlert = true
                        }
                    }
                    
                    // 學習題數設定
                    ClaudeSettingsCard(title: "學習題數設定", icon: "list.number") {
                        VStack(spacing: 20) {
                            ClaudeStepperSetting(
                                title: "智慧複習題",
                                description: "根據您的錯誤記錄安排的複習題目",
                                value: $reviewCount,
                                range: 0...10
                            )
                            
                            ClaudeStepperSetting(
                                title: "全新挑戰題",
                                description: "基於文法句型生成的新題目",
                                value: $newCount,
                                range: 0...10
                            )
                        }
                    }
                    
                    // 新題目設定
                    ClaudeSettingsCard(title: "新題目客製化", icon: "sparkles") {
                        VStack(spacing: 20) {
                            ClaudeSliderSetting(
                                title: "題目難度",
                                description: "數字越高，題目越具挑戰性",
                                value: $difficulty,
                                range: 1...5
                            )
                            
                            ClaudePickerSetting(
                                title: "句子長度",
                                description: "選擇您偏好的練習句子類型",
                                value: $length
                            )
                        }
                    }
                    
                    // AI 模型設定
                    ClaudeSettingsCard(title: "AI 模型設定", icon: "cpu") {
                        VStack(spacing: 20) {
                            ClaudeAIModelSetting(
                                title: "出題模型",
                                description: "負責生成練習題目的 AI 模型",
                                value: $generationModel
                            )
                            
                            ClaudeAIModelSetting(
                                title: "批改模型",
                                description: "負責評分和提供建議的 AI 模型",
                                value: $gradingModel
                            )
                        }
                        
                        ClaudeInfoBox(text: "更強的模型通常更準確，但回應速度可能較慢。")
                    }
                    
                    // 學習目標設定
                    ClaudeSettingsCard(title: "學習目標", icon: "target") {
                        ClaudeStepperSetting(
                            title: "每日目標",
                            description: "設定您每天想要完成的題目數量",
                            value: $dailyGoal,
                            range: 1...50
                        )
                    }
                    
                    // 說明區塊
                    ClaudeInfoCard()
                }
                .padding(ModernSpacing.lg)
            }
            .background(Color.modernBackground)
            .navigationTitle("個人化設定")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                syncSettings()
            }
            .onChange(of: reviewCount) { _, newValue in SettingsManager.shared.reviewCount = newValue }
            .onChange(of: newCount) { _, newValue in SettingsManager.shared.newCount = newValue }
            .onChange(of: difficulty) { _, newValue in SettingsManager.shared.difficulty = newValue }
            .onChange(of: length) { _, newValue in SettingsManager.shared.length = newValue }
            .onChange(of: dailyGoal) { _, newValue in SettingsManager.shared.dailyGoal = newValue }
            .onChange(of: generationModel) { _, newValue in SettingsManager.shared.generationModel = newValue }
            .onChange(of: gradingModel) { _, newValue in SettingsManager.shared.gradingModel = newValue }
            .alert("確認登出", isPresented: $showLogoutAlert) {
                Button("取消", role: .cancel) { }
                Button("登出", role: .destructive) {
                    Task {
                        await authManager.logout()
                    }
                }
            } message: {
                Text("您確定要登出嗎？登出後需要重新登入才能繼續使用。")
            }
        }
    }
    
    private func syncSettings() {
        self.reviewCount = SettingsManager.shared.reviewCount
        self.newCount = SettingsManager.shared.newCount
        self.difficulty = SettingsManager.shared.difficulty
        self.length = SettingsManager.shared.length
        self.dailyGoal = SettingsManager.shared.dailyGoal
        self.generationModel = SettingsManager.shared.generationModel
        self.gradingModel = SettingsManager.shared.gradingModel
    }
}

// MARK: - Claude 風格設定組件

struct ClaudeSettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.appHeadline(for: "設定圖示"))
                    .foregroundStyle(Color.modernAccent)
                
                Text(title)
                    .font(.appTitle3(for: "設定標題"))
                    .foregroundStyle(Color.modernTextPrimary)
            }
            
            content
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
                .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
        }
    }
}

struct ClaudeStepperSetting: View {
    let title: String
    let description: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.appCallout(for: "設定項目"))
                    .foregroundStyle(Color.modernTextPrimary)
                
                Text(description)
                    .font(.appCaption(for: "設定說明"))
                    .foregroundStyle(Color.modernTextSecondary)
                    .lineSpacing(1)
            }
            
            HStack {
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        if value > range.lowerBound {
                            value -= 1
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.appCallout(for: "設定項目"))
                            .foregroundStyle(value > range.lowerBound ? Color.modernAccent : .secondary)
                            .frame(width: 32, height: 32)
                            .background {
                                Circle()
                                    .fill(Color.modernSurface.opacity(0.7))
                            }
                    }
                    .disabled(value <= range.lowerBound)
                    
                    Text("\(value)")
                        .font(.appTitle3(for: "設定標題"))
                        .foregroundStyle(Color.modernTextPrimary)
                        .frame(minWidth: 30)
                    
                    Button(action: {
                        if value < range.upperBound {
                            value += 1
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.appCallout(for: "設定項目"))
                            .foregroundStyle(value < range.upperBound ? Color.modernAccent : .secondary)
                            .frame(width: 32, height: 32)
                            .background {
                                Circle()
                                    .fill(Color.modernSurface.opacity(0.7))
                            }
                    }
                    .disabled(value >= range.upperBound)
                }
                
                Spacer()
            }
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.sm + 4)
                .fill(Color.modernSurface.opacity(0.7))
        }
    }
}

struct ClaudeSliderSetting: View {
    let title: String
    let description: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.appCallout(for: "設定項目"))
                        .foregroundStyle(Color.modernTextPrimary)
                    
                    Spacer()
                    
                    Text("\(value)")
                        .font(.appCallout(for: "設定值"))
                        .foregroundStyle(Color.modernAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(Color.modernAccent.opacity(0.15))
                        }
                }
                
                Text(description)
                    .font(.appCaption(for: "設定說明"))
                    .foregroundStyle(Color.modernTextSecondary)
                    .lineSpacing(1)
            }
            
            HStack(spacing: 12) {
                Text("\(range.lowerBound)")
                    .font(.appCaption(for: "小標題"))
                    .foregroundStyle(Color.modernTextTertiary)
                
                Slider(
                    value: Binding(
                        get: { Double(value) },
                        set: { value = Int($0) }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: 1
                ) {
                    Text(title)
                } minimumValueLabel: {
                    EmptyView()
                } maximumValueLabel: {
                    EmptyView()
                }
                .tint(Color.modernAccent)
                
                Text("\(range.upperBound)")
                    .font(.appCaption(for: "小標題"))
                    .foregroundStyle(Color.modernTextTertiary)
            }
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.sm + 4)
                .fill(Color.modernSurface.opacity(0.7))
        }
    }
}

struct ClaudePickerSetting: View {
    let title: String
    let description: String
    @Binding var value: SettingsManager.SentenceLength
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.appCallout(for: "設定項目"))
                    .foregroundStyle(Color.modernTextPrimary)
                
                Text(description)
                    .font(.appCaption(for: "設定說明"))
                    .foregroundStyle(Color.modernTextSecondary)
                    .lineSpacing(1)
            }
            
            HStack(spacing: 8) {
                ForEach(SettingsManager.SentenceLength.allCases) { option in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            value = option
                        }
                    }) {
                        Text(option.displayName)
                            .font(.appSubheadline(for: "選項"))
                            .foregroundStyle(value == option ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background {
                                RoundedRectangle(cornerRadius: ModernRadius.sm)
                                    .fill(value == option ? Color.modernAccent : Color(.systemBackground))
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.sm + 4)
                .fill(Color.modernSurface.opacity(0.7))
        }
    }
}

struct ClaudeAIModelSetting: View {
    let title: String
    let description: String
    @Binding var value: SettingsManager.AIModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.appCallout(for: "設定項目"))
                    .foregroundStyle(Color.modernTextPrimary)
                
                Text(description)
                    .font(.appCaption(for: "設定說明"))
                    .foregroundStyle(Color.modernTextSecondary)
                    .lineSpacing(1)
            }
            
            VStack(spacing: 8) {
                ForEach(SettingsManager.AIModel.allCases) { model in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            value = model
                        }
                    }) {
                        HStack {
                            Text(model.displayName)
                                .font(.appSubheadline(for: "選項"))
                                .foregroundStyle(Color.modernTextPrimary)
                            
                            Spacer()
                            
                            if value == model {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.appCallout(for: "模型選項"))
                                    .foregroundStyle(Color.modernAccent)
                            } else {
                                Image(systemName: "circle")
                                    .font(.appCallout(for: "模型選項"))
                                    .foregroundStyle(Color.modernTextTertiary)
                            }
                        }
                        .padding(ModernSpacing.sm + 4)
                        .background {
                            RoundedRectangle(cornerRadius: ModernRadius.sm)
                                .fill(value == model ? Color.modernAccent.opacity(0.1) : Color(.systemBackground))
                                .overlay {
                                    RoundedRectangle(cornerRadius: ModernRadius.sm)
                                        .stroke(value == model ? Color.modernAccent.opacity(0.3) : Color.clear, lineWidth: 1)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.sm + 4)
                .fill(Color.modernSurface.opacity(0.7))
        }
    }
}

struct ClaudeInfoBox: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.appSubheadline(for: "說明文字"))
                .foregroundStyle(Color.modernSpecial)
            
            Text(text)
                .font(.appSubheadline(for: text))
                .foregroundStyle(Color.modernTextSecondary)
                .lineSpacing(1)
        }
        .padding(ModernSpacing.sm + 4)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.modernSpecialSoft)
        }
    }
}

struct ClaudeInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.appHeadline(for: "設定圖示"))
                    .foregroundStyle(Color.modernWarning)
                
                Text("使用提示")
                    .font(.appHeadline(for: "使用提示"))
                    .foregroundStyle(Color.modernTextPrimary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ClaudeInfoTip(
                    icon: "1.circle.fill",
                    text: "設定將在下一次生成新題目時生效"
                )
                
                ClaudeInfoTip(
                    icon: "2.circle.fill",
                    text: "建議複習題數量保持在 3-5 題，以達到最佳學習效果"
                )
                
                ClaudeInfoTip(
                    icon: "3.circle.fill",
                    text: "較強的 AI 模型（如 Gemini 2.5 Pro）會提供更準確的分析"
                )
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
                .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
        }
    }
}

struct ClaudeInfoTip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.appCallout())
                .foregroundStyle(Color.modernAccent)
                .padding(.top, 1)
            
            Text(text)
                .font(.appSubheadline(for: "說明文字"))
                .foregroundStyle(Color.modernTextSecondary)
                .lineSpacing(1)
        }
    }
}

// MARK: - 使用者資料卡片
struct ClaudeUserProfileCard: View {
    let user: User
    let onLogout: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.appHeadline(for: "使用者頭像"))
                    .foregroundStyle(Color.modernAccent)
                
                Text("使用者資料")
                    .font(.appTitle3(for: "使用者資料"))
                    .foregroundStyle(Color.modernTextPrimary)
            }
            
            VStack(spacing: 16) {
                // 基本資訊
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(user.displayName ?? user.username)
                            .font(.appTitle2(for: "使用者名稱"))
                            .foregroundStyle(Color.modernTextPrimary)
                        
                        Text(user.email)
                            .font(.appSubheadline(for: "電子郵件"))
                            .foregroundStyle(Color.modernTextSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("學習時間")
                            .font(.appCaption(for: "標籤"))
                            .foregroundStyle(Color.modernTextSecondary)
                        
                        Text(formatLearningTime(user.totalLearningTime))
                            .font(.appHeadline(for: "學習時間"))
                            .foregroundStyle(Color.modernAccent)
                    }
                }
                
                // 學習統計
                HStack(spacing: 20) {
                    ClaudeUserStatCard(
                        title: "知識點",
                        value: "\(user.knowledgePointsCount)",
                        icon: "brain.head.profile"
                    )
                    
                    if let nativeLanguage = user.nativeLanguage {
                        ClaudeUserStatCard(
                            title: "母語",
                            value: nativeLanguage,
                            icon: "globe"
                        )
                    }
                    
                    if let targetLanguage = user.targetLanguage {
                        ClaudeUserStatCard(
                            title: "目標語言",
                            value: targetLanguage,
                            icon: "target"
                        )
                    }
                }
                
                // 登出按鈕
                Button(action: onLogout) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.square")
                            .font(.appCallout(for: "登出圖示"))
                        
                        Text("登出")
                            .font(.appCallout(for: "登出按鈕"))
                    }
                    .foregroundStyle(Color.modernError)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: ModernRadius.sm)
                            .fill(Color.modernError.opacity(0.1))
                            .overlay {
                                RoundedRectangle(cornerRadius: ModernRadius.sm)
                                    .stroke(Color.modernError.opacity(0.3), lineWidth: 1)
                            }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
                .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
        }
    }
    
    private func formatLearningTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小時\(minutes)分"
        } else {
            return "\(minutes)分鐘"
        }
    }
}

struct ClaudeUserStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.appSubheadline(for: "統計圖示"))
                .foregroundStyle(Color.modernAccent)
            
            Text(value)
                .font(.appCallout(for: "統計數值"))
                .foregroundStyle(Color.modernTextPrimary)
                .lineLimit(1)
            
            Text(title)
                .font(.appCaption(for: "統計標題"))
                .foregroundStyle(Color.modernTextSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.modernSurface.opacity(0.7))
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
}
