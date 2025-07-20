// DashboardStatsCard.swift - 儀表板統計卡片組件

import SwiftUI

struct DashboardStatsCard: View {
    let stats: DashboardStats
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: ModernSpacing.md), count: 2), spacing: ModernSpacing.md) {
            
            StatCard(
                title: "總知識點",
                value: "\(stats.totalPoints)",
                icon: "brain.head.profile",
                color: .modernAccent
            )
            .accessibleStatistic(
                label: "總知識點數量",
                value: "\(stats.totalPoints) 個"
            )
            
            StatCard(
                title: "熟練掌握",
                value: "\(stats.masteredPoints)",
                icon: "checkmark.circle.fill",
                color: .modernSuccess
            )
            .accessibleStatistic(
                label: "已熟練掌握的知識點",
                value: "\(stats.masteredPoints) 個"
            )
            
            StatCard(
                title: "平均熟練度",
                value: String(format: "%.1f%%", stats.averageMastery * 100),
                icon: "chart.line.uptrend.xyaxis",
                color: .modernSpecial
            )
            .accessibleStatistic(
                label: "平均熟練度",
                value: String(format: "%.1f%%", stats.averageMastery * 100)
            )
            
            StatCard(
                title: "完成率",
                value: String(format: "%.1f%%", stats.completionRate),
                icon: "percent",
                color: .modernWarning
            )
            .accessibleStatistic(
                label: "整體完成率",
                value: String(format: "%.1f%%", stats.completionRate)
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: ModernSpacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.appTitle3())
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                Text(value)
                    .font(.appTitle(for: "統計數值"))
                    .foregroundStyle(Color.modernTextPrimary)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.appCaption(for: "統計標題"))
                    .foregroundStyle(Color.modernTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(ModernSpacing.lg)
        .modernCard(.standard)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)：\(value)")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - 進度環形圖組件
struct CircularProgressCard: View {
    let progress: Double
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: ModernSpacing.lg) {
            ZStack {
                // 背景圓環
                Circle()
                    .stroke(color.opacity(0.1), lineWidth: 8)
                
                // 進度圓環
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: progress)
                
                // 中央數值
                VStack(spacing: 4) {
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.appTitle(for: "進度百分比"))
                        .foregroundStyle(color)
                        .fontWeight(.bold)
                    
                    Text(subtitle)
                        .font(.appCaption(for: "進度描述"))
                        .foregroundStyle(Color.modernTextSecondary)
                }
            }
            .frame(width: 120, height: 120)
            
            Text(title)
                .font(.appHeadline(for: "進度標題"))
                .foregroundStyle(Color.modernTextPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(ModernSpacing.xl)
        .modernCard(.elevated)
        .accessibleProgress(
            value: progress,
            total: 1.0,
            label: title
        )
        .accessibilityValue("\(Int(progress * 100))% \(subtitle)")
    }
}

// MARK: - 趨勢卡片組件
struct TrendCard: View {
    let title: String
    let currentValue: String
    let trend: TrendDirection
    let trendValue: String
    let icon: String
    
    enum TrendDirection {
        case up, down, neutral
        
        var color: Color {
            switch self {
            case .up: return .modernSuccess
            case .down: return .modernError
            case .neutral: return .modernTextSecondary
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var description: String {
            switch self {
            case .up: return "上升"
            case .down: return "下降"
            case .neutral: return "持平"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: ModernSpacing.md) {
            // 主圖示
            Image(systemName: icon)
                .font(.appTitle2())
                .foregroundStyle(Color.modernAccent)
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                Text(title)
                    .font(.appCallout(for: "趨勢標題"))
                    .foregroundStyle(Color.modernTextSecondary)
                
                Text(currentValue)
                    .font(.appTitle2(for: "當前數值"))
                    .foregroundStyle(Color.modernTextPrimary)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // 趨勢指示器
            HStack(spacing: ModernSpacing.xs) {
                Image(systemName: trend.icon)
                    .font(.appCaption())
                    .foregroundStyle(trend.color)
                
                Text(trendValue)
                    .font(.appCaption(for: "趨勢數值"))
                    .foregroundStyle(trend.color)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, ModernSpacing.sm)
            .padding(.vertical, ModernSpacing.xs)
            .background(trend.color.opacity(0.1))
            .cornerRadius(ModernRadius.sm)
        }
        .padding(ModernSpacing.lg)
        .modernCard(.standard)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)：\(currentValue)，趨勢\(trend.description) \(trendValue)")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - 統計數據結構
struct DashboardStats {
    let totalPoints: Int
    let masteredPoints: Int
    let averageMastery: Double
    let completionRate: Double
    let weeklyProgress: Double
    let monthlyGoal: Int
    let currentStreak: Int
    let needReviewToday: Int
    let weakPoints: Int
    let mediumPoints: Int
    let strongPoints: Int
    let categoriesCount: Int
    
    init(from knowledgePoints: [KnowledgePoint]) {
        self.totalPoints = knowledgePoints.count
        self.masteredPoints = knowledgePoints.filter { $0.mastery_level >= 0.8 }.count
        
        // 計算不同熟練度的分布
        self.weakPoints = knowledgePoints.filter { $0.mastery_level < 1.5 }.count
        self.mediumPoints = knowledgePoints.filter { $0.mastery_level >= 1.5 && $0.mastery_level < 3.5 }.count
        self.strongPoints = knowledgePoints.filter { $0.mastery_level >= 3.5 }.count
        
        if totalPoints > 0 {
            self.averageMastery = knowledgePoints.reduce(0) { $0 + $1.mastery_level } / Double(totalPoints)
            self.completionRate = Double(masteredPoints) / Double(totalPoints)
        } else {
            self.averageMastery = 0.0
            self.completionRate = 0.0
        }
        
        // 這些數值在實際應用中應該從數據庫或 API 獲取
        self.weeklyProgress = 0.65 // 本週進度 65%
        self.monthlyGoal = 50 // 月目標 50 個知識點
        self.currentStreak = 7 // 當前連續學習 7 天
        self.needReviewToday = knowledgePoints.filter { point in
            // 簡單的複習邏輯：低熟練度的需要複習
            point.mastery_level < 2.0
        }.count
        
        // 計算類別數量
        self.categoriesCount = Set(knowledgePoints.map { $0.category }).count
    }
}

// MARK: - 預覽
#Preview("統計卡片") {
    let sampleStats = DashboardStats(from: [])
    
    VStack(spacing: ModernSpacing.lg) {
        DashboardStatsCard(stats: sampleStats)
        
        CircularProgressCard(
            progress: 0.78,
            title: "本週學習進度",
            subtitle: "已完成",
            color: .modernAccent
        )
        
        TrendCard(
            title: "本週新增",
            currentValue: "12",
            trend: .up,
            trendValue: "+25%",
            icon: "plus.circle"
        )
    }
    .padding()
    .background(Color.modernBackground)
}