// GuestPromptComponents.swift

import SwiftUI

// MARK: - 訪客限制提示組件
struct GuestFeatureLimitView: View {
    let feature: GuestFeatureLimit
    let onRegister: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: ModernSpacing.lg) {
            // 圖示和標題
            VStack(spacing: ModernSpacing.md) {
                Image(systemName: featureIcon)
                    .font(.system(size: 48))
                    .foregroundStyle(Color.modernAccent)
                
                Text("功能限制")
                    .font(.appTitle2(for: "限制標題"))
                    .foregroundStyle(Color.modernTextPrimary)
                
                Text(feature.description)
                    .font(.appBody(for: "限制說明"))
                    .foregroundStyle(Color.modernTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // 升級優勢說明
            VStack(alignment: .leading, spacing: ModernSpacing.md) {
                Text("註冊後享有完整功能：")
                    .font(.appHeadline(for: "升級標題"))
                    .foregroundStyle(Color.modernTextPrimary)
                
                VStack(spacing: ModernSpacing.sm) {
                    GuestUpgradeBenefit(
                        icon: "icloud.and.arrow.up",
                        title: "雲端同步",
                        description: "學習進度跨設備同步"
                    )
                    
                    GuestUpgradeBenefit(
                        icon: "infinity",
                        title: "無限練習",
                        description: "每日練習次數不受限制"
                    )
                    
                    GuestUpgradeBenefit(
                        icon: "brain.head.profile",
                        title: "進階AI模型",
                        description: "更準確的錯誤分析與建議"
                    )
                    
                    GuestUpgradeBenefit(
                        icon: "chart.bar.fill",
                        title: "詳細統計",
                        description: "完整的學習數據分析"
                    )
                }
            }
            .padding(ModernSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: ModernRadius.md)
                    .fill(Color.modernSurface)
            }
            
            // 按鈕組
            VStack(spacing: ModernSpacing.sm) {
                ModernButton(
                    "立即註冊",
                    style: .primary,
                    action: onRegister
                )
                
                ModernButton(
                    "稍後再說",
                    style: .tertiary,
                    action: onDismiss
                )
            }
        }
        .padding(ModernSpacing.lg)
        .modernCard(.elevated)
        .padding(ModernSpacing.lg)
    }
    
    private var featureIcon: String {
        switch feature {
        case .dailyPractice: return "calendar.badge.exclamationmark"
        case .knowledgePointsSave: return "bookmark.circle"
        case .aiModelAccess: return "brain.head.profile"
        case .cloudSync: return "icloud.and.arrow.up"
        }
    }
}

// MARK: - 升級優勢項目組件
struct GuestUpgradeBenefit: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: ModernSpacing.sm) {
            Image(systemName: icon)
                .font(.appCallout(for: "優勢圖示"))
                .foregroundStyle(Color.modernAccent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                Text(title)
                    .font(.appCallout(for: "優勢標題"))
                    .foregroundStyle(Color.modernTextPrimary)
                
                Text(description)
                    .font(.appCaption(for: "優勢說明"))
                    .foregroundStyle(Color.modernTextSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 訪客模式指示器
struct GuestModeIndicator: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingPrompt = false
    
    var body: some View {
        if authManager.isGuest {
            Button(action: {
                showingPrompt = true
            }) {
                HStack(spacing: ModernSpacing.xs) {
                    Image(systemName: "eye")
                        .font(.appCaption(for: "訪客圖示"))
                    
                    Text("訪客模式")
                        .font(.appCaption(for: "訪客文字"))
                    
                    Image(systemName: "arrow.up.right")
                        .font(.appCaption(for: "升級圖示"))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, ModernSpacing.sm)
                .padding(.vertical, ModernSpacing.xs)
                .background {
                    Capsule()
                        .fill(Color.modernSpecial)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingPrompt) {
                GuestRegistrationPromptView()
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - 註冊轉換提示視圖
struct GuestRegistrationPromptView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingRegister = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ModernSpacing.xl) {
                    // 慶祝圖示
                    VStack(spacing: ModernSpacing.md) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.modernSpecial)
                        
                        Text("太棒了！")
                            .font(.appLargeTitle(for: "慶祝標題"))
                            .foregroundStyle(Color.modernTextPrimary)
                        
                        Text("您已經體驗了我們的核心功能")
                            .font(.appSubheadline(for: "慶祝說明"))
                            .foregroundStyle(Color.modernTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, ModernSpacing.lg)
                    
                    // 學習成果展示
                    if let user = authManager.currentUser {
                        VStack(spacing: ModernSpacing.md) {
                            Text("您的學習成果")
                                .font(.appTitle3(for: "成果標題"))
                                .foregroundStyle(Color.modernTextPrimary)
                            
                            HStack(spacing: ModernSpacing.lg) {
                                GuestAchievementCard(
                                    icon: "clock.fill",
                                    title: "學習時間",
                                    value: formatTime(user.totalLearningTime),
                                    color: Color.modernSpecial
                                )
                                
                                GuestAchievementCard(
                                    icon: "brain.head.profile",
                                    title: "知識點",
                                    value: "\(user.knowledgePointsCount)個",
                                    color: Color.modernAccent
                                )
                            }
                        }
                        .padding(ModernSpacing.lg)
                        .background {
                            RoundedRectangle(cornerRadius: ModernRadius.md)
                                .fill(Color.modernSurface)
                        }
                    }
                    
                    // 升級優勢
                    VStack(alignment: .leading, spacing: ModernSpacing.md) {
                        Text("註冊享有更多功能")
                            .font(.appTitle3(for: "升級標題"))
                            .foregroundStyle(Color.modernTextPrimary)
                        
                        VStack(spacing: ModernSpacing.sm) {
                            GuestUpgradeBenefit(
                                icon: "icloud.and.arrow.up",
                                title: "永久保存學習進度",
                                description: "再也不用擔心數據丟失"
                            )
                            
                            GuestUpgradeBenefit(
                                icon: "infinity",
                                title: "無限制學習",
                                description: "想學多久就學多久"
                            )
                            
                            GuestUpgradeBenefit(
                                icon: "person.2.fill",
                                title: "與朋友比較進度",
                                description: "加入學習社群"
                            )
                        }
                    }
                    
                    // 行動按鈕
                    VStack(spacing: ModernSpacing.sm) {
                        ModernButton(
                            "立即註冊，保存學習成果",
                            style: .primary
                        ) {
                            showingRegister = true
                        }
                        
                        ModernButton(
                            "繼續訪客體驗",
                            style: .tertiary
                        ) {
                            dismiss()
                        }
                    }
                }
                .padding(ModernSpacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                    .foregroundStyle(Color.modernAccent)
                }
            }
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
                .environmentObject(authManager)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小時"
        } else {
            return "\(minutes)分鐘"
        }
    }
}

// MARK: - 成就卡片組件
struct GuestAchievementCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: ModernSpacing.xs) {
            Image(systemName: icon)
                .font(.appTitle3(for: "成就圖示"))
                .foregroundStyle(color)
            
            Text(value)
                .font(.appTitle2(for: "成就數值"))
                .foregroundStyle(Color.modernTextPrimary)
            
            Text(title)
                .font(.appCaption(for: "成就標題"))
                .foregroundStyle(Color.modernTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.sm)
                .fill(Color.modernSurfaceElevated)
        }
    }
}

#Preview("功能限制提示") {
    GuestFeatureLimitView(
        feature: .dailyPractice,
        onRegister: {},
        onDismiss: {}
    )
}

#Preview("註冊轉換提示") {
    GuestRegistrationPromptView()
        .environmentObject(AuthenticationManager())
}