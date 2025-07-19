// DailyDetailView.swift - Claude風格重新設計+AI總結

import SwiftUI

struct DailyDetailView: View {
    let selectedDate: Date
    
    @State private var details: DailyDetailResponse?
    @State private var aiSummary: DailySummaryResponse?
    @State private var isLoading = false
    @State private var isLoadingAISummary = false
    @State private var showAISummary = false
    
    private var formattedLearningTime: String {
        guard let totalSeconds = details?.total_learning_time_seconds else { return "0分0秒" }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return minutes > 0 ? "\(minutes)分\(seconds)秒" : "\(seconds)秒"
    }
    
    private var dateStringForAPI: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    private var navigationTitleString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: selectedDate)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private var dayStats: DayStats {
        DayStats(from: details)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                if isLoading {
                    ClaudeLoadingCard()
                } else if let details = details {
                    // AI總結卡片（置頂）
                    if showAISummary || aiSummary != nil {
                        ClaudeAISummaryCard(
                            summary: aiSummary,
                            isLoading: isLoadingAISummary,
                            onGenerate: generateAISummary,
                            onToggle: { showAISummary.toggle() }
                        )
                    }
                    
                    // 學習概覽卡片
                    ClaudeDayOverviewCard(
                        stats: dayStats,
                        isToday: isToday,
                        onAISummaryTap: {
                            if aiSummary == nil && !isLoadingAISummary {
                                generateAISummary()
                            }
                            showAISummary = true
                        }
                    )
                    
                    // 知識點分析卡片
                    if !details.reviewed_knowledge_points.isEmpty || !details.new_knowledge_points.isEmpty {
                        ClaudeKnowledgeAnalysisCard(
                            reviewedPoints: details.reviewed_knowledge_points,
                            newPoints: details.new_knowledge_points
                        )
                    }
                    
                    // 學習洞察卡片
                    ClaudeLearningInsightsCard(stats: dayStats)
                    
                } else {
                    ClaudeNoDataCard(date: selectedDate)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(navigationTitleString)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadDailyDetails)
    }
    
    private func loadDailyDetails() {
        isLoading = true
        Task {
            guard var urlComponents = URLComponents(string: "\(APIConfig.apiBaseURL)/api/get_daily_details") else { return }
            urlComponents.queryItems = [
                URLQueryItem(name: "date", value: dateStringForAPI)
            ]
            guard let url = urlComponents.url else { return }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decodedResponse = try JSONDecoder().decode(DailyDetailResponse.self, from: data)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.details = decodedResponse
                        self.isLoading = false
                    }
                }
            } catch {
                print("無法載入單日詳情: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func generateAISummary() {
        guard details != nil else { return }
        
        isLoadingAISummary = true
        Task {
            guard var urlComponents = URLComponents(string: "\(APIConfig.apiBaseURL)/api/generate_daily_summary") else { return }
            urlComponents.queryItems = [
                URLQueryItem(name: "date", value: dateStringForAPI)
            ]
            guard let url = urlComponents.url else { return }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let summaryResponse = try JSONDecoder().decode(DailySummaryResponse.self, from: data)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.aiSummary = summaryResponse
                        self.isLoadingAISummary = false
                    }
                }
            } catch {
                print("無法生成AI總結: \(error)")
                await MainActor.run {
                    self.isLoadingAISummary = false
                }
            }
        }
    }
}

// MARK: - 數據模型

struct DayStats {
    let totalTime: Int
    let totalKnowledgePoints: Int
    let reviewedCount: Int
    let newCount: Int
    let efficiency: Double // 每分鐘學會的知識點數
    
    init(from details: DailyDetailResponse?) {
        guard let details = details else {
            totalTime = 0
            totalKnowledgePoints = 0
            reviewedCount = 0
            newCount = 0
            efficiency = 0
            return
        }
        
        totalTime = details.total_learning_time_seconds
        reviewedCount = details.reviewed_knowledge_points.reduce(0) { $0 + $1.count }
        newCount = details.new_knowledge_points.reduce(0) { $0 + $1.count }
        totalKnowledgePoints = reviewedCount + newCount
        
        let minutes = max(1, totalTime / 60)
        efficiency = Double(totalKnowledgePoints) / Double(minutes)
    }
}

struct DailySummaryResponse: Codable {
    let summary: String
    let key_achievements: [String]
    let improvement_suggestions: [String]
    let motivational_message: String
}

// MARK: - Claude風格組件

struct ClaudeLoadingCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.orange)
            
            Text("正在分析您的學習紀錄...")
                .font(.appBody(for: "正在分析您的學習紀錄..."))
                .foregroundStyle(.secondary)
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

struct ClaudeNoDataCard: View {
    let date: Date
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isToday ? "moon.zzz" : "calendar.badge.minus")
                .font(.appLargeTitle())
                .foregroundStyle(Color.orange.opacity(0.7))
            
            Text(isToday ? "今天還沒有學習紀錄" : "這天沒有學習紀錄")
                .font(.appHeadline(for: isToday ? "今天還沒有學習紀錄" : "這天沒有學習紀錄"))
                .foregroundStyle(.primary)
            
            Text(isToday ? "開始今天的第一道練習題吧！" : "在其他日子裡努力學習吧")
                .font(.appBody(for: isToday ? "開始今天的第一道練習題吧！" : "在其他日子裡努力學習吧"))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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

struct ClaudeDayOverviewCard: View {
    let stats: DayStats
    let isToday: Bool
    let onAISummaryTap: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 標題區域
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isToday ? "今日學習概覽" : "學習概覽")
                        .font(.appTitle2(for: isToday ? "今日學習概覽" : "學習概覽"))
                        .foregroundStyle(.primary)
                    
                    if stats.totalKnowledgePoints > 0 {
                        Text("共掌握 \(stats.totalKnowledgePoints) 個知識點")
                            .font(.appBody())
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // AI總結按鈕
                Button(action: onAISummaryTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.appCallout())
                        Text("AI總結")
                            .font(.appCallout(for: "AI總結"))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(Color.orange)
                    }
                }
            }
            
            // 統計網格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ClaudeStatBox(
                    title: "學習時長",
                    value: formatTime(stats.totalTime),
                    icon: "clock.fill",
                    color: .blue
                )
                
                ClaudeStatBox(
                    title: "學習效率",
                    value: String(format: "%.1f/分", stats.efficiency),
                    icon: "speedometer",
                    color: .purple
                )
                
                ClaudeStatBox(
                    title: "複習重點",
                    value: "\(stats.reviewedCount)",
                    icon: "arrow.clockwise.circle.fill",
                    color: .green
                )
                
                ClaudeStatBox(
                    title: "新增知識",
                    value: "\(stats.newCount)",
                    icon: "plus.circle.fill",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes > 0 {
            return "\(minutes)分\(remainingSeconds)秒"
        } else {
            return "\(remainingSeconds)秒"
        }
    }
}

struct ClaudeStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.appTitle3())
                .foregroundStyle(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.appHeadline())
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.appCaption())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        }
    }
}

struct ClaudeAISummaryCard: View {
    let summary: DailySummaryResponse?
    let isLoading: Bool
    let onGenerate: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 標題區域
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.appHeadline())
                        .foregroundStyle(Color.orange)
                    
                    Text("AI 當日總結")
                        .font(.appHeadline(for: "AI 當日總結"))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Button(action: onToggle) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
            }
            
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(Color.orange)
                    
                    Text("AI正在分析您的學習表現...")
                        .font(.appBody(for: "AI正在分析您的學習表現..."))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                
            } else if let summary = summary {
                VStack(alignment: .leading, spacing: 16) {
                    // 主要總結
                    VStack(alignment: .leading, spacing: 8) {
                        Text("學習總結")
                            .font(.appCallout(for: "學習總結"))
                            .foregroundStyle(Color.orange)
                        
                        Text(summary.summary)
                            .font(.appBody(for: summary.summary))
                            .foregroundStyle(.primary)
                            .lineSpacing(2)
                    }
                    
                    // 主要成就
                    if !summary.key_achievements.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("今日亮點")
                                .font(.appCallout(for: "今日亮點"))
                                .foregroundStyle(Color.green)
                            
                            ForEach(summary.key_achievements, id: \.self) { achievement in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "star.fill")
                                        .font(.appCaption())
                                        .foregroundStyle(Color.yellow)
                                        .padding(.top, 3)
                                    
                                    Text(achievement)
                                        .font(.appSubheadline(for: achievement))
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }
                    
                    // 改進建議
                    if !summary.improvement_suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("改進建議")
                                .font(.appCallout(for: "改進建議"))
                                .foregroundStyle(Color.blue)
                            
                            ForEach(summary.improvement_suggestions, id: \.self) { suggestion in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.appCaption())
                                        .foregroundStyle(Color.yellow)
                                        .padding(.top, 3)
                                    
                                    Text(suggestion)
                                        .font(.appSubheadline(for: suggestion))
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }
                    
                    // 激勵訊息
                    if !summary.motivational_message.isEmpty {
                        Text(summary.motivational_message)
                            .font(.appBody(for: summary.motivational_message))
                            .foregroundStyle(.secondary)
                            .italic()
                            .padding(12)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.1))
                            }
                    }
                }
                
            } else {
                Button(action: onGenerate) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.appCallout())
                        
                        Text("生成AI總結")
                            .font(.appBody(for: "生成AI總結"))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange)
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct ClaudeKnowledgeAnalysisCard: View {
    let reviewedPoints: [LearnedPoint]
    let newPoints: [LearnedPoint]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("知識點分析")
                    .font(.appHeadline(for: "知識點分析"))
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            VStack(spacing: 16) {
                // 複習的知識點
                if !reviewedPoints.isEmpty {
                    ClaudeKnowledgeSection(
                        title: "強化複習",
                        points: reviewedPoints,
                        color: .green,
                        icon: "arrow.clockwise.circle.fill"
                    )
                }
                
                // 新學的知識點
                if !newPoints.isEmpty {
                    ClaudeKnowledgeSection(
                        title: "新增掌握",
                        points: newPoints,
                        color: .orange,
                        icon: "plus.circle.fill"
                    )
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

struct ClaudeKnowledgeSection: View {
    let title: String
    let points: [LearnedPoint]
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.appCallout())
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.appHeadline(for: title))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(points.reduce(0) { $0 + $1.count }) 個")
                    .font(.appCaption())
                    .foregroundStyle(.secondary)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(points) { point in
                    HStack {
                        Text(point.summary)
                            .font(.appBody(for: point.summary))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Text("×\(point.count)")
                            .font(.appCaption())
                            .foregroundStyle(color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background {
                                Capsule()
                                    .fill(color.opacity(0.15))
                            }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    }
                }
            }
        }
    }
}

struct ClaudeLearningInsightsCard: View {
    let stats: DayStats
    
    private var insights: [LearningInsight] {
        generateInsights(from: stats)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("學習洞察")
                    .font(.appHeadline(for: "學習洞察"))
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(insights) { insight in
                    ClaudeInsightRow(insight: insight)
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
    
    private func generateInsights(from stats: DayStats) -> [LearningInsight] {
        var insights: [LearningInsight] = []
        
        // 效率分析
        if stats.efficiency > 2.0 {
            insights.append(LearningInsight(
                title: "高效學習",
                description: "您的學習效率很高，平均每分鐘掌握 \(String(format: "%.1f", stats.efficiency)) 個知識點",
                icon: "bolt.fill",
                color: .yellow
            ))
        } else if stats.efficiency > 0 {
            insights.append(LearningInsight(
                title: "穩定進步",
                description: "保持這樣的學習節奏，持續積累知識",
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            ))
        }
        
        // 複習比例分析
        let reviewRatio = stats.totalKnowledgePoints > 0 ? Double(stats.reviewedCount) / Double(stats.totalKnowledgePoints) : 0
        if reviewRatio > 0.7 {
            insights.append(LearningInsight(
                title: "鞏固為主",
                description: "今天主要在鞏固舊知識，建議適當嘗試新挑戰",
                icon: "arrow.clockwise",
                color: .green
            ))
        } else if reviewRatio < 0.3 && stats.newCount > 0 {
            insights.append(LearningInsight(
                title: "探索新知",
                description: "今天學了很多新知識，記得定期複習哦",
                icon: "star.fill",
                color: .orange
            ))
        }
        
        // 時間建議
        let minutes = stats.totalTime / 60
        if minutes > 30 {
            insights.append(LearningInsight(
                title: "專注投入",
                description: "今天學習了 \(minutes) 分鐘，投入度很高！",
                icon: "clock.badge.checkmark",
                color: .purple
            ))
        }
        
        return insights
    }
}

struct LearningInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct ClaudeInsightRow: View {
    let insight: LearningInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.appHeadline())
                .foregroundStyle(insight.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.appCallout(for: insight.title))
                    .foregroundStyle(.primary)
                
                Text(insight.description)
                    .font(.appSubheadline(for: insight.description))
                    .foregroundStyle(.secondary)
                    .lineSpacing(1)
            }
            
            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(insight.color.opacity(0.08))
        }
    }
}

#Preview {
    NavigationView {
        DailyDetailView(selectedDate: Date())
    }
}
