// LearningAreaView.swift - 學習區獨立容器

import SwiftUI

struct LearningAreaView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        TabView {
            // AI 家教 - 學習主頁
            AITutorView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI 家教")
                }
                .environmentObject(sessionManager)
            
            // 學習日曆
            LearningCalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("日曆")
                }
            
            // 知識點儀表板
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.xaxis")
                    Text("儀表板")
                }
            
            // 學習統計
            LearningStatsView()
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("統計")
                }
            
            // 學習設定
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
        }
        .accentColor(.orange) // 學習區使用橙色主題
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
                LazyVStack(spacing: 24) {
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
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("📊 學習統計")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshStats) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.orange)
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
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.orange)
                
                Text("本月學習概覽")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
            }
            
            if let stats = stats {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    StatMiniCard(title: "完成題數", value: "\(stats.totalQuestions)", icon: "list.number")
                    StatMiniCard(title: "學習時間", value: "\(stats.totalTimeMinutes / 60)小時", icon: "clock")
                    StatMiniCard(title: "平均準確率", value: "\(Int(stats.averageAccuracy * 100))%", icon: "target")
                    StatMiniCard(title: "活躍天數", value: "\(stats.daysActive)天", icon: "calendar.badge.checkmark")
                }
                
                // 連續學習天數
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("當前連續")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.orange)
                            
                            Text("\(stats.currentStreak)天")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("最長紀錄")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(stats.longestStreak)天")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)
            } else {
                Text("載入中...")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct WeeklyTrendCard: View {
    let weeklyData: [WeeklyLearningData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.orange)
                
                Text("近七天學習趨勢")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
            }
            
            if weeklyData.isEmpty {
                Text("暫無數據")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                VStack(spacing: 16) {
                    // 圖表
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(weeklyData) { data in
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.orange.opacity(0.8))
                                    .frame(width: 32, height: CGFloat(max(4, data.questionsCompleted * 8)))
                                
                                Text(data.date, formatter: dayFormatter)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(height: 120)
                    
                    // 統計資訊
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("總題數")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("\(weeklyData.reduce(0) { $0 + $1.questionsCompleted })")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("平均每天")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("\(weeklyData.reduce(0) { $0 + $1.questionsCompleted } / max(1, weeklyData.count))題")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.orange)
                
                Text("學習成就")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                Text("\(achievements.filter { $0.isUnlocked }.count)/\(achievements.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementMiniCard(achievement: achievement)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.orange)
                
                Text("學習建議")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(advice.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.orange))
                        
                        Text(tip)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineSpacing(2)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - 輔助組件

struct StatMiniCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.orange)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
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
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(achievement.isUnlocked ? Color.orange : .secondary)
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(achievement.isUnlocked ? Color.orange.opacity(0.1) : Color(.systemGray6))
                .overlay {
                    if !achievement.isUnlocked {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
        }
    }
}

#Preview {
    LearningAreaView()
        .environmentObject(SessionManager())
}
