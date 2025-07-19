// VocabularyAreaView.swift - 單字記憶庫佔位界面

import SwiftUI

struct VocabularyAreaView: View {
    var body: some View {
        TabView {
            // 我的單字庫
            VocabularyLibraryView()
                .tabItem {
                    Image(systemName: "book.closed.fill")
                    Text("單字庫")
                }
            
            // 複習計劃
            VocabularyReviewView()
                .tabItem {
                    Image(systemName: "repeat.circle.fill")
                    Text("複習")
                }
            
            // 學習進度
            VocabularyProgressView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("進度")
                }
            
            // 單字設定
            VocabularySettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
        }
        .accentColor(.blue) // 單字庫使用藍色主題
    }
}

// MARK: - 單字庫主頁面

struct VocabularyLibraryView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // 佔位圖示
                Image(systemName: "book.closed")
                    .font(.appLargeTitle())
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 16) {
                    Text("單字記憶庫")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("這裡將會是您的個人單字記憶庫\n敬請期待後續功能開發")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                // 佔位按鈕
                VStack(spacing: 12) {
                    Button(action: {
                        // 待實作：新增單字功能
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("新增單字")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(true)
                    
                    Text("功能開發中...")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(20)
            .navigationTitle("📚 單字庫")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 複習計劃頁面

struct VocabularyReviewView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Image(systemName: "repeat.circle")
                    .font(.appLargeTitle())
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 16) {
                    Text("複習計劃")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("智能複習系統將幫助您\n有效記憶和複習單字")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                VStack(spacing: 16) {
                    EmptyStateCard(
                        icon: "calendar",
                        title: "今日複習",
                        subtitle: "0 個單字待複習"
                    )
                    
                    EmptyStateCard(
                        icon: "clock",
                        title: "下次複習",
                        subtitle: "無排程"
                    )
                }
            }
            .padding(20)
            .navigationTitle("🔄 複習計劃")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 學習進度頁面

struct VocabularyProgressView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.appLargeTitle())
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 16) {
                    Text("學習進度")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("追蹤您的單字學習成果\n和記憶效果統計")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                VStack(spacing: 16) {
                    ProgressCard(
                        title: "總單字數",
                        value: "0",
                        icon: "book.closed"
                    )
                    
                    ProgressCard(
                        title: "已掌握",
                        value: "0",
                        icon: "checkmark.circle"
                    )
                    
                    ProgressCard(
                        title: "學習中",
                        value: "0",
                        icon: "clock"
                    )
                }
            }
            .padding(20)
            .navigationTitle("📊 學習進度")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 設定頁面

struct VocabularySettingsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Image(systemName: "gearshape")
                    .font(.appLargeTitle())
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 16) {
                    Text("單字庫設定")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("自訂您的單字學習偏好\n和複習排程設定")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                VStack(spacing: 12) {
                    SettingsPlaceholderRow(title: "複習提醒", icon: "bell")
                    SettingsPlaceholderRow(title: "學習目標", icon: "target")
                    SettingsPlaceholderRow(title: "難度設定", icon: "slider.horizontal.3")
                    SettingsPlaceholderRow(title: "匯入/匯出", icon: "arrow.up.arrow.down")
                }
            }
            .padding(20)
            .navigationTitle("⚙️ 設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 輔助視圖組件

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ProgressCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
            
            Spacer()
        }
        .padding(16)
        .background(.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SettingsPlaceholderRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    VocabularyAreaView()
}
