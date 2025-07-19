// GuestPromptComponents.swift

import SwiftUI

// MARK: - 訪客限制提示組件
struct GuestFeatureLimitView: View {
    let feature: GuestFeatureLimit
    let onRegister: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 圖示和標題
            VStack(spacing: 12) {
                Image(systemName: featureIcon)
                    .font(.system(size: 48))
                    .foregroundStyle(Color.orange)
                
                Text("功能限制")
                    .font(.appTitle2(for: "限制標題"))
                    .foregroundStyle(.primary)
                
                Text(feature.description)
                    .font(.appBody(for: "限制說明"))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 升級優勢說明
            VStack(alignment: .leading, spacing: 12) {
                Text("註冊後享有完整功能：")
                    .font(.appHeadline(for: "升級標題"))
                    .foregroundStyle(.primary)
                
                VStack(spacing: 8) {
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
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            }
            
            // 按鈕組
            VStack(spacing: 12) {
                Button(action: onRegister) {
                    Text("立即註冊")
                        .font(.appHeadline(for: "註冊按鈕"))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange)
                        }
                }
                .buttonStyle(.plain)
                
                Button(action: onDismiss) {
                    Text("稍後再說")
                        .font(.appCallout(for: "取消按鈕"))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding(20)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.appCallout(for: "優勢圖示"))
                .foregroundStyle(Color.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appCallout(for: "優勢標題"))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.appCaption(for: "優勢說明"))
                    .foregroundStyle(.secondary)
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
                HStack(spacing: 8) {
                    Image(systemName: "eye")
                        .font(.appCaption(for: "訪客圖示"))
                    
                    Text("訪客模式")
                        .font(.appCaption(for: "訪客文字"))
                    
                    Image(systemName: "arrow.up.right")
                        .font(.appCaption(for: "升級圖示"))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(Color.blue)
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
                VStack(spacing: 32) {
                    // 慶祝圖示
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.yellow)
                        
                        Text("太棒了！")
                            .font(.appLargeTitle(for: "慶祝標題"))
                            .foregroundStyle(.primary)
                        
                        Text("您已經體驗了我們的核心功能")
                            .font(.appSubheadline(for: "慶祝說明"))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // 學習成果展示
                    if let user = authManager.currentUser {
                        VStack(spacing: 16) {
                            Text("您的學習成果")
                                .font(.appTitle3(for: "成果標題"))
                                .foregroundStyle(.primary)
                            
                            HStack(spacing: 20) {
                                GuestAchievementCard(
                                    icon: "clock.fill",
                                    title: "學習時間",
                                    value: formatTime(user.totalLearningTime),
                                    color: .blue
                                )
                                
                                GuestAchievementCard(
                                    icon: "brain.head.profile",
                                    title: "知識點",
                                    value: "\(user.knowledgePointsCount)個",
                                    color: .orange
                                )
                            }
                        }
                        .padding(20)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        }
                    }
                    
                    // 升級優勢
                    VStack(alignment: .leading, spacing: 16) {
                        Text("註冊享有更多功能")
                            .font(.appTitle3(for: "升級標題"))
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: 12) {
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
                    VStack(spacing: 12) {
                        Button(action: {
                            showingRegister = true
                        }) {
                            Text("立即註冊，保存學習成果")
                                .font(.appHeadline(for: "註冊按鈕"))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange)
                                }
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("繼續訪客體驗")
                                .font(.appCallout(for: "繼續按鈕"))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                    .foregroundStyle(Color.orange)
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
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.appTitle3(for: "成就圖示"))
                .foregroundStyle(color)
            
            Text(value)
                .font(.appTitle2(for: "成就數值"))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.appCaption(for: "成就標題"))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
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