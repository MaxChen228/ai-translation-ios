// VocabularyAreaView.swift - 單字記憶庫

import SwiftUI

struct VocabularyAreaView: View {
    var body: some View {
        TabView {
            // 多分類系統 (主要單字系統)
            MultiClassificationSystemView()
                .tabItem {
                    Image(systemName: "square.grid.3x3.fill")
                    Text("單字庫")
                        .font(.appCaption())
                }
            
            // 我的單字庫
            VocabularyHomeView()
                .tabItem {
                    Image(systemName: "book.closed.fill")
                    Text("我的單字")
                        .font(.appCaption())
                }
            
            // 複習計劃
            VocabularyReviewView()
                .tabItem {
                    Image(systemName: "arrow.clockwise.circle.fill")
                    Text("複習")
                        .font(.appCaption())
                }
            
            // 學習進度
            VocabularyProgressView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    Text("進度")
                        .font(.appCaption())
                }
        }
        .accentColor(Color.modernAccent)
    }
}

// MARK: - 單字庫主頁面

struct VocabularyLibraryView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ModernSpacing.xxl) {
                    VStack(spacing: ModernSpacing.lg) {
                        // 佔位圖示
                        Image(systemName: "book.closed")
                            .font(.appLargeTitle())
                            .foregroundStyle(Color.modernAccent)
                            .padding(.top, ModernSpacing.xl)
                        
                        VStack(spacing: ModernSpacing.md) {
                            Text("單字記憶庫")
                                .font(.appLargeTitle(for: "頁面標題"))
                                .foregroundStyle(Color.modernTextPrimary)
                            
                            Text("這裡將會是您的個人單字記憶庫\n敬請期待後續功能開發")
                                .font(.appBody(for: "描述文字"))
                                .foregroundStyle(Color.modernTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    
                    // 現代風卡片設計
                    VStack(spacing: ModernSpacing.md) {
                        Button(action: {
                            // 待實作：新增單字功能
                        }) {
                            HStack(spacing: ModernSpacing.sm) {
                                Image(systemName: "plus.circle")
                                    .font(.appHeadline(for: "按鈕圖示"))
                                
                                Text("新增單字")
                                    .font(.appHeadline(for: "按鈕文字"))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, ModernSpacing.lg)
                            .padding(.vertical, ModernSpacing.md)
                            .background {
                                RoundedRectangle(cornerRadius: ModernRadius.sm)
                                    .fill(Color.modernAccent.opacity(0.6))
                            }
                        }
                        .disabled(true)
                        
                        Text("功能開發中")
                            .font(.appCaption(for: "狀態文字"))
                            .foregroundStyle(Color.modernTextTertiary)
                    }
                    .padding(ModernSpacing.lg)
                    .background {
                        RoundedRectangle(cornerRadius: ModernRadius.md)
                            .fill(Color.modernSurface)
                            .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
                    }
                    .padding(.horizontal, ModernSpacing.lg)
                    
                    Spacer(minLength: ModernSpacing.xl)
                }
            }
            .background(Color.modernBackground)
            .navigationTitle("單字庫")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 複習計劃頁面

struct VocabularyReviewView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ModernSpacing.xxl) {
                    VStack(spacing: ModernSpacing.lg) {
                        Image(systemName: "arrow.clockwise")
                            .font(.appLargeTitle())
                            .foregroundStyle(Color.modernAccent)
                            .padding(.top, ModernSpacing.xl)
                        
                        VStack(spacing: ModernSpacing.md) {
                            Text("複習計劃")
                                .font(.appLargeTitle(for: "頁面標題"))
                                .foregroundStyle(Color.modernTextPrimary)
                            
                            Text("智能複習系統將幫助您\n有效記憶和複習單字")
                                .font(.appBody(for: "描述文字"))
                                .foregroundStyle(Color.modernTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    
                    VStack(spacing: ModernSpacing.md) {
                        ModernEmptyStateCard(
                            icon: "calendar",
                            title: "今日複習",
                            subtitle: "0 個單字待複習"
                        )
                        
                        ModernEmptyStateCard(
                            icon: "clock",
                            title: "下次複習",
                            subtitle: "無排程"
                        )
                    }
                    .padding(.horizontal, ModernSpacing.lg)
                    
                    Spacer(minLength: ModernSpacing.xl)
                }
            }
            .background(Color.modernBackground)
            .navigationTitle("複習計劃")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 學習進度頁面

struct VocabularyProgressView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ModernSpacing.xxl) {
                    VStack(spacing: ModernSpacing.lg) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.appLargeTitle())
                            .foregroundStyle(Color.modernAccent)
                            .padding(.top, ModernSpacing.xl)
                        
                        VStack(spacing: ModernSpacing.md) {
                            Text("學習進度")
                                .font(.appLargeTitle(for: "頁面標題"))
                                .foregroundStyle(Color.modernTextPrimary)
                            
                            Text("追蹤您的單字學習成果\n和記憶效果統計")
                                .font(.appBody(for: "描述文字"))
                                .foregroundStyle(Color.modernTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    
                    VStack(spacing: ModernSpacing.md) {
                        ModernProgressCard(
                            title: "總單字數",
                            value: "0",
                            icon: "book.closed"
                        )
                        
                        ModernProgressCard(
                            title: "已掌握",
                            value: "0",
                            icon: "checkmark.circle"
                        )
                        
                        ModernProgressCard(
                            title: "學習中",
                            value: "0",
                            icon: "clock"
                        )
                    }
                    .padding(.horizontal, ModernSpacing.lg)
                    
                    Spacer(minLength: ModernSpacing.xl)
                }
            }
            .background(Color.modernBackground)
            .navigationTitle("學習進度")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 設定頁面

struct VocabularySettingsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ModernSpacing.xxl) {
                    VStack(spacing: ModernSpacing.lg) {
                        Image(systemName: "gearshape")
                            .font(.appLargeTitle())
                            .foregroundStyle(Color.modernAccent)
                            .padding(.top, ModernSpacing.xl)
                        
                        VStack(spacing: ModernSpacing.md) {
                            Text("單字庫設定")
                                .font(.appLargeTitle(for: "頁面標題"))
                                .foregroundStyle(Color.modernTextPrimary)
                            
                            Text("自訂您的單字學習偏好\n和複習排程設定")
                                .font(.appBody(for: "描述文字"))
                                .foregroundStyle(Color.modernTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    
                    VStack(spacing: ModernSpacing.sm) {
                        ModernSettingsRow(title: "複習提醒", icon: "bell")
                        ModernSettingsRow(title: "學習目標", icon: "target")
                        ModernSettingsRow(title: "難度設定", icon: "slider.horizontal.3")
                        ModernSettingsRow(title: "匯入/匯出", icon: "arrow.up.arrow.down")
                    }
                    .padding(.horizontal, ModernSpacing.lg)
                    
                    Spacer(minLength: ModernSpacing.xl)
                }
            }
            .background(Color.modernBackground)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 現代風輔助視圖組件

struct ModernEmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: ModernSpacing.md) {
            Image(systemName: icon)
                .font(.appTitle2(for: "卡片圖示"))
                .foregroundStyle(Color.modernAccent)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                Text(title)
                    .font(.appHeadline(for: "卡片標題"))
                    .foregroundStyle(Color.modernTextPrimary)
                
                Text(subtitle)
                    .font(.appSubheadline(for: "卡片副標題"))
                    .foregroundStyle(Color.modernTextSecondary)
            }
            
            Spacer()
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
                .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
        }
    }
}

struct ModernProgressCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: ModernSpacing.md) {
            Image(systemName: icon)
                .font(.appTitle2(for: "進度圖示"))
                .foregroundStyle(Color.modernAccent)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                Text(title)
                    .font(.appHeadline(for: "進度標題"))
                    .foregroundStyle(Color.modernTextPrimary)
                
                Text(value)
                    .font(.appTitle2(for: "進度數值"))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.modernAccent)
            }
            
            Spacer()
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernAccentSoft)
                .overlay {
                    RoundedRectangle(cornerRadius: ModernRadius.md)
                        .stroke(Color.modernAccent.opacity(0.2), lineWidth: 1)
                }
        }
    }
}

struct ModernSettingsRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: ModernSpacing.md) {
            Image(systemName: icon)
                .font(.appHeadline(for: "設定圖示"))
                .foregroundStyle(Color.modernAccent)
                .frame(width: 24)
            
            Text(title)
                .font(.appBody(for: "設定項目"))
                .foregroundStyle(Color.modernTextPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.appCaption(for: "箭頭"))
                .foregroundStyle(Color.modernTextTertiary)
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.sm)
                .fill(Color.modernSurface)
                .shadow(color: ModernShadow.subtle.color, radius: ModernShadow.subtle.radius, x: ModernShadow.subtle.x, y: ModernShadow.subtle.y)
        }
    }
}

#Preview {
    VocabularyAreaView()
}
