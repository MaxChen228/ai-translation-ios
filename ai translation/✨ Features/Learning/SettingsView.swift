// SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @State private var reviewCount: Int = SettingsManager.shared.reviewCount
    @State private var newCount: Int = SettingsManager.shared.newCount
    @State private var difficulty: Int = SettingsManager.shared.difficulty
    @State private var length: SettingsManager.SentenceLength = SettingsManager.shared.length
    @State private var dailyGoal: Int = SettingsManager.shared.dailyGoal
    @State private var generationModel: SettingsManager.AIModel = SettingsManager.shared.generationModel
    @State private var gradingModel: SettingsManager.AIModel = SettingsManager.shared.gradingModel

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
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
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("⚙️ 個人化設定")
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
                    .foregroundStyle(Color.orange)
                
                Text(title)
                    .font(.appTitle3(for: "設定標題"))
                    .foregroundStyle(.primary)
            }
            
            content
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.appCaption(for: "設定說明"))
                    .foregroundStyle(.secondary)
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
                            .foregroundStyle(value > range.lowerBound ? Color.orange : .secondary)
                            .frame(width: 32, height: 32)
                            .background {
                                Circle()
                                    .fill(Color(.systemGray6))
                            }
                    }
                    .disabled(value <= range.lowerBound)
                    
                    Text("\(value)")
                        .font(.appTitle3(for: "設定標題"))
                        .foregroundStyle(.primary)
                        .frame(minWidth: 30)
                    
                    Button(action: {
                        if value < range.upperBound {
                            value += 1
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.appCallout(for: "設定項目"))
                            .foregroundStyle(value < range.upperBound ? Color.orange : .secondary)
                            .frame(width: 32, height: 32)
                            .background {
                                Circle()
                                    .fill(Color(.systemGray6))
                            }
                    }
                    .disabled(value >= range.upperBound)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
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
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("\(value)")
                        .font(.appCallout(for: "設定值"))
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(Color.orange.opacity(0.15))
                        }
                }
                
                Text(description)
                    .font(.appCaption(for: "設定說明"))
                    .foregroundStyle(.secondary)
                    .lineSpacing(1)
            }
            
            HStack(spacing: 12) {
                Text("\(range.lowerBound)")
                    .font(.appCaption(for: "小標題"))
                    .foregroundStyle(.tertiary)
                
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
                .tint(Color.orange)
                
                Text("\(range.upperBound)")
                    .font(.appCaption(for: "小標題"))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
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
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.appCaption(for: "設定說明"))
                    .foregroundStyle(.secondary)
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
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(value == option ? Color.orange : Color(.systemBackground))
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
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
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.appCaption(for: "設定說明"))
                    .foregroundStyle(.secondary)
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
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if value == model {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.appCallout(for: "模型選項"))
                                    .foregroundStyle(Color.orange)
                            } else {
                                Image(systemName: "circle")
                                    .font(.appCallout(for: "模型選項"))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(value == model ? Color.orange.opacity(0.1) : Color(.systemBackground))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(value == model ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        }
    }
}

struct ClaudeInfoBox: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.appSubheadline(for: "說明文字"))
                .foregroundStyle(Color.blue)
            
            Text(text)
                .font(.appSubheadline(for: text))
                .foregroundStyle(.secondary)
                .lineSpacing(1)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        }
    }
}

struct ClaudeInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.appHeadline(for: "設定圖示"))
                    .foregroundStyle(.yellow)
                
                Text("使用提示")
                    .font(.appHeadline(for: "使用提示"))
                    .foregroundStyle(.primary)
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
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                .foregroundStyle(Color.orange)
                .padding(.top, 1)
            
            Text(text)
                .font(.appSubheadline(for: "說明文字"))
                .foregroundStyle(.secondary)
                .lineSpacing(1)
        }
    }
}

#Preview {
    SettingsView()
}
