// LearningAreaView.swift - 學習區獨立容器

import SwiftUI

struct LearningAreaView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        TabView {
            // AI 家教 - 學習主頁
            AITutorView()
                .tabItem {
                    Image(systemName: "brain.head.profile.fill")
                    Text("AI 家教")
                        .font(.appCaption())
                }
                .environmentObject(sessionManager)
            
            // 學習日曆
            LearningCalendarView()
                .tabItem {
                    Image(systemName: "calendar.circle.fill")
                    Text("日曆")
                        .font(.appCaption())
                }
            
            // 知識點儀表板
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.xaxis.ascending")
                    Text("儀表板")
                        .font(.appCaption())
                }
            
            // 學習統計
            LearningStatsView()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("統計")
                        .font(.appCaption())
                }
            
            // 學習設定
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                        .font(.appCaption())
                }
        }
        .accentColor(Color.modernAccent) // 學習區使用現代橙棕主題
    }
}

// MARK: - 學習統計頁面

struct LearningStatsView: View {
    @State private var weeklyStats: [WeeklyLearningData] = []
    @State private var monthlyStats: MonthlyLearningStats?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: ModernSpacing.lg) {
                    if isLoading {
                        ProgressView("載入統計數據中...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // 本月概覽
                        MonthlyOverviewCard(stats: monthlyStats)
                        
                        // 週學習趨勢
                        WeeklyTrendCard(weeklyData: weeklyStats)
                        
                        // 學習成就
                        AchievementsCard()
                        
                        // 學習建議
                        LearningAdviceCard()
                    }
                }
                .padding(ModernSpacing.lg)
            }
            .background(Color.modernBackground)
            .navigationTitle("學習統計")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshStats) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.modernAccent)
                    }
                }
            }
        }
        .onAppear {
            loadStats()
        }
    }
    
    private func loadStats() {
        isLoading = true
        // 模擬載入統計數據
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.weeklyStats = generateMockWeeklyData()
            self.monthlyStats = generateMockMonthlyStats()
            self.isLoading = false
        }
    }
    
    private func refreshStats() {
        loadStats()
    }
    
    private func generateMockWeeklyData() -> [WeeklyLearningData] {
        let calendar = Calendar.current
        var data: [WeeklyLearningData] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                data.append(WeeklyLearningData(
                    date: date,
                    questionsCompleted: Int.random(in: 0...15),
                    timeSpentMinutes: Int.random(in: 0...45)
                ))
            }
        }
        
        return data.reversed()
    }
    
    private func generateMockMonthlyStats() -> MonthlyLearningStats {
        MonthlyLearningStats(
            totalQuestions: 156,
            totalTimeMinutes: 720,
            averageAccuracy: 0.78,
            daysActive: 18,
            currentStreak: 5,
            longestStreak: 12
        )
    }
}

// MARK: - 統計數據模型

struct WeeklyLearningData: Identifiable {
    let id = UUID()
    let date: Date
    let questionsCompleted: Int
    let timeSpentMinutes: Int
}

struct MonthlyLearningStats {
    let totalQuestions: Int
    let totalTimeMinutes: Int
    let averageAccuracy: Double
    let daysActive: Int
    let currentStreak: Int
    let longestStreak: Int
}

// MARK: - 統計卡片組件

struct MonthlyOverviewCard: View {
    let stats: MonthlyLearningStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.lg) {
            HStack {
                Image(systemName: "calendar")
                    .font(.appHeadline())
                    .foregroundStyle(Color.modernAccent)
                
                Text("本月學習概覽")
                    .font(.appTitle3(for: "本月學習概覽"))
                
                Spacer()
            }
            
            if let stats = stats {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: ModernSpacing.md), count: 2), spacing: ModernSpacing.md) {
                    StatMiniCard(title: "完成題數", value: "\(stats.totalQuestions)", icon: "list.number")
                    StatMiniCard(title: "學習時間", value: "\(stats.totalTimeMinutes / 60)小時", icon: "clock")
                    StatMiniCard(title: "平均準確率", value: "\(Int(stats.averageAccuracy * 100))%", icon: "target")
                    StatMiniCard(title: "活躍天數", value: "\(stats.daysActive)天", icon: "calendar.badge.checkmark")
                }
                
                // 連續學習天數
                HStack {
                    VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                        Text("當前連續")
                            .font(.appCaption(for: "當前連續"))
                            .foregroundStyle(Color.modernTextSecondary)
                        
                        HStack(spacing: ModernSpacing.xs) {
                            Image(systemName: "flame.fill")
                                .font(.appCallout(for: "熱度"))
                                .foregroundStyle(Color.modernAccent)
                            
                            Text("\(stats.currentStreak)天")
                                .font(.appHeadline())
                                .foregroundStyle(Color.modernTextPrimary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: ModernSpacing.xs) {
                        Text("最長紀錄")
                            .font(.appCaption(for: "最長紀錄"))
                            .foregroundStyle(Color.modernTextSecondary)
                        
                        Text("\(stats.longestStreak)天")
                            .font(.appCallout())
                            .foregroundStyle(Color.modernTextSecondary)
                    }
                }
                .padding(.top, 8)
            } else {
                Text("載入中...")
                    .foregroundStyle(Color.modernTextSecondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
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

struct WeeklyTrendCard: View {
    let weeklyData: [WeeklyLearningData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.lg) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.appHeadline())
                    .foregroundStyle(Color.modernAccent)
                
                Text("近七天學習趨勢")
                    .font(.appTitle3(for: "近七天學習趨勢"))
                
                Spacer()
            }
            
            if weeklyData.isEmpty {
                Text("暫無數據")
                    .foregroundStyle(Color.modernTextSecondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                VStack(spacing: ModernSpacing.md) {
                    // 圖表
                    HStack(alignment: .bottom, spacing: ModernSpacing.sm) {
                        ForEach(weeklyData) { data in
                            VStack(spacing: ModernSpacing.sm) {
                                RoundedRectangle(cornerRadius: ModernRadius.xs)
                                    .fill(Color.modernAccent.opacity(0.8))
                                    .frame(width: 32, height: CGFloat(max(4, data.questionsCompleted * 8)))
                                
                                Text(data.date, formatter: dayFormatter)
                                    .font(.appCaption(for: "日期"))
                                    .foregroundStyle(Color.modernTextSecondary)
                            }
                        }
                    }
                    .frame(height: 120)
                    
                    // 統計資訊
                    HStack {
                        VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                            Text("總題數")
                                .font(.appCaption(for: "總題數"))
                                .foregroundStyle(Color.modernTextSecondary)
                            
                            Text("\(weeklyData.reduce(0) { $0 + $1.questionsCompleted })")
                                .font(.appCallout())
                                .foregroundStyle(Color.modernTextPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: ModernSpacing.xs) {
                            Text("平均每天")
                                .font(.appCaption(for: "平均每天"))
                                .foregroundStyle(Color.modernTextSecondary)
                            
                            Text("\(weeklyData.reduce(0) { $0 + $1.questionsCompleted } / max(1, weeklyData.count))題")
                                .font(.appCallout())
                                .foregroundStyle(Color.modernTextPrimary)
                        }
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
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }
}

struct AchievementsCard: View {
    private let achievements = [
        Achievement(title: "初學者", description: "完成第一題", icon: "star.fill", isUnlocked: true),
        Achievement(title: "勤奮學者", description: "連續學習7天", icon: "flame.fill", isUnlocked: true),
        Achievement(title: "精準射手", description: "準確率達到90%", icon: "target", isUnlocked: false),
        Achievement(title: "馬拉松選手", description: "累計學習10小時", icon: "timer", isUnlocked: false)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.lg) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.appHeadline())
                    .foregroundStyle(Color.modernAccent)
                
                Text("學習成就")
                    .font(.appTitle3(for: "學習成就"))
                
                Spacer()
                
                Text("\(achievements.filter { $0.isUnlocked }.count)/\(achievements.count)")
                    .font(.appCaption())
                    .foregroundStyle(Color.modernAccent)
                    .padding(.horizontal, ModernSpacing.sm)
                    .padding(.vertical, ModernSpacing.xs)
                    .background(Color.modernAccent.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: ModernSpacing.md), count: 2), spacing: ModernSpacing.md) {
                ForEach(achievements) { achievement in
                    AchievementMiniCard(achievement: achievement)
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

struct LearningAdviceCard: View {
    private let advice = [
        "建議每天學習15-30分鐘，保持學習習慣",
        "複習舊的知識點比學習新內容更重要",
        "錯誤是學習的好機會，不要害怕犯錯",
        "定期回顧筆記可以幫助加深記憶"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.appHeadline())
                    .foregroundStyle(Color.modernAccent)
                
                Text("學習建議")
                    .font(.appTitle3(for: "學習建議"))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: ModernSpacing.md) {
                ForEach(Array(advice.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: ModernSpacing.md) {
                        Text("\(index + 1)")
                            .font(.appCaption())
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.modernAccent))
                        
                        Text(tip)
                            .font(.appBody(for: tip))
                            .foregroundStyle(Color.modernTextPrimary)
                            .lineSpacing(2)
                        
                        Spacer()
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

// MARK: - 輔助組件

struct StatMiniCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: ModernSpacing.sm) {
            Image(systemName: icon)
                .font(.appTitle3(for: icon))
                .foregroundStyle(Color.modernAccent)
            
            Text(value)
                .font(.appHeadline(for: value))
                .foregroundStyle(Color.modernTextPrimary)
            
            Text(title)
                .font(.appCaption(for: title))
                .foregroundStyle(Color.modernTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
        }
    }
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
}

struct AchievementMiniCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: ModernSpacing.sm) {
            Image(systemName: achievement.icon)
                .font(.appTitle2(for: achievement.icon))
                .foregroundStyle(achievement.isUnlocked ? Color.modernAccent : .secondary)
            
            Text(achievement.title)
                .font(.appCaption(for: achievement.title))
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.appCaption2(for: achievement.description))
                .foregroundStyle(Color.modernTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.sm)
                .fill(achievement.isUnlocked ? Color.modernAccent.opacity(0.1) : Color.modernSurface)
                .overlay {
                    if !achievement.isUnlocked {
                        RoundedRectangle(cornerRadius: ModernRadius.sm)
                            .stroke(ModernDesignSystem.Colors.textTertiary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
        }
    }
}

#Preview {
    LearningAreaView()
        .environmentObject(SessionManager())
}
