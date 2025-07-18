//  DashboardView.swift - Claude 風格簡約設計

import SwiftUI

// 【重新設計】簡約的檢視模式
enum ModernDashboardMode: String, CaseIterable, Identifiable {
    case overview = "概覽"
    case categories = "分類"
    case progress = "進度"
    case schedule = "排程"
    
    var id: Self { self }
    
    var icon: String {
        switch self {
        case .overview: return "chart.pie"
        case .categories: return "folder"
        case .progress: return "chart.bar"
        case .schedule: return "calendar"
        }
    }
    
    // 【改為】簡約的主題色
    var accentColor: Color {
        return Color.orange // Claude 風格的橙色重點色
    }
}

struct DashboardView: View {
    @State private var knowledgePoints: [KnowledgePoint] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedMode: ModernDashboardMode = .overview
    
    private var stats: DashboardStats {
        DashboardStats(from: knowledgePoints)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 【簡化】模式選擇器
                ClaudeModeSelector(selectedMode: $selectedMode)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                if isLoading {
                    ClaudeLoadingView()
                } else if let errorMessage = errorMessage {
                    ClaudeErrorView(message: errorMessage) {
                        Task { await fetchDashboardData() }
                    }
                } else if knowledgePoints.isEmpty {
                    ClaudeEmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            switch selectedMode {
                            case .overview:
                                OverviewSection(stats: stats, points: knowledgePoints)
                            case .categories:
                                CategoriesSection(points: knowledgePoints)
                            case .progress:
                               ProgressSection(points: knowledgePoints)
                            case .schedule:
                                ScheduleSection(points: knowledgePoints)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("知識儀表板")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { Task { await fetchDashboardData() } }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.orange)
                    }
                    
                    NavigationLink(destination: ArchivedPointsView()) {
                        Image(systemName: "archivebox")
                            .foregroundStyle(Color.orange)
                    }
                }
            }
            .onAppear {
                Task { await fetchDashboardData() }
                
                #if DEBUG
                // 字體測試代碼
                print("=== 字體載入測試 ===")
                let testFonts = [
                    "SourceHanSerifTCVF-Regular",
                    "SourceHanSerifTCVF-Bold",
                    "SourceHanSerifTCVF-Light"
                ]

                for fontName in testFonts {
                    if let font = UIFont(name: fontName, size: 16) {
                        print("✅ \(fontName) 載入成功")
                    } else {
                        print("❌ \(fontName) 載入失敗")
                    }
                }
                #endif
            }
        }
    }
    
    func fetchDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(APIConfig.apiBaseURL)/api/get_dashboard") else {
            errorMessage = "無效的網址"
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedResponse = try JSONDecoder().decode(DashboardResponse.self, from: data)
            withAnimation(.easeInOut(duration: 0.3)) {
                self.knowledgePoints = decodedResponse.knowledge_points
            }
        } catch {
            self.errorMessage = "無法獲取數據，請稍後再試。"
            print("獲取儀表板數據時發生錯誤: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Claude 風格組件

struct DashboardStats {
    let totalPoints: Int
    let weakPoints: Int
    let mediumPoints: Int
    let strongPoints: Int
    let averageMastery: Double
    let categoriesCount: Int
    let needReviewToday: Int
    
    init(from points: [KnowledgePoint]) {
        totalPoints = points.count
        weakPoints = points.filter { $0.mastery_level < 1.5 }.count
        mediumPoints = points.filter { $0.mastery_level >= 1.5 && $0.mastery_level < 3.5 }.count
        strongPoints = points.filter { $0.mastery_level >= 3.5 }.count
        averageMastery = points.isEmpty ? 0 : points.map { $0.mastery_level }.reduce(0, +) / Double(points.count)
        categoriesCount = Set(points.map { $0.category }).count
        
        let today = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        needReviewToday = points.filter { point in
            guard let dateString = point.next_review_date,
                  let reviewDate = formatter.date(from: dateString) else { return false }
            return Calendar.current.isDate(reviewDate, inSameDayAs: today) || reviewDate < today
        }.count
    }
}

// 【重新設計】Claude 風格模式選擇器
struct ClaudeModeSelector: View {
    @Binding var selectedMode: ModernDashboardMode
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ModernDashboardMode.allCases) { mode in
                ClaudeModeButton(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    animation: animation
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMode = mode
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct ClaudeModeButton: View {
    let mode: ModernDashboardMode
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.appFootnote())
                
                Text(mode.rawValue)
                    .font(.appFootnote(for: mode.rawValue))
            }
            .foregroundStyle(isSelected ? .white : Color(.label))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange)
                        .matchedGeometryEffect(id: "selectedMode", in: animation)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// 【重新設計】概覽區域 - 簡約風格
struct OverviewSection: View {
    let stats: DashboardStats
    let points: [KnowledgePoint]
    
    var body: some View {
        VStack(spacing: 20) {
            // 簡約統計卡片
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ClaudeStatCard(title: "總知識點", value: "\(stats.totalPoints)")
                ClaudeStatCard(title: "平均熟練度", value: String(format: "%.1f", stats.averageMastery))
                ClaudeStatCard(title: "今日需複習", value: "\(stats.needReviewToday)")
                ClaudeStatCard(title: "分類數量", value: "\(stats.categoriesCount)")
            }
            
            // 簡約分布圖
            ClaudeMasteryCard(stats: stats)
            
            // 關注區域
            ClaudeFocusCard(points: points.filter { $0.mastery_level < 2.0 }.sorted { $0.mastery_level < $1.mastery_level }.prefix(5))
        }
    }
}

// 【重新設計】簡約統計卡片
struct ClaudeStatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.appTitle2(for: value))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.appCaption(for: title))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

// 【重新設計】簡約熟練度卡片
struct ClaudeMasteryCard: View {
    let stats: DashboardStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("熟練度分布")
                .font(.appHeadline(for: "熟練度分布"))
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                ClaudeMasteryBar(label: "需加強", count: stats.weakPoints, total: stats.totalPoints, color: Color(.systemRed))
                ClaudeMasteryBar(label: "中等程度", count: stats.mediumPoints, total: stats.totalPoints, color: Color(.systemOrange))
                ClaudeMasteryBar(label: "已掌握", count: stats.strongPoints, total: stats.totalPoints, color: Color(.systemGreen))
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

struct ClaudeMasteryBar: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        total == 0 ? 0 : Double(count) / Double(total)
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.appSubheadline(for: label))
                .foregroundStyle(.primary)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: percentage)
                }
            }
            .frame(height: 6)
            
            Text("\(count)")
                .font(.appCaption())
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// 【重新設計】簡約關注卡片
struct ClaudeFocusCard: View {
    let points: ArraySlice<KnowledgePoint>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("需要重點關注")
                    .font(.appHeadline(for: "需要重點關注"))
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            if points.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.appLargeTitle(for: "✅"))
                        .foregroundStyle(Color(.systemGreen))
                    Text("所有知識點都很穩固！")
                        .font(.appSubheadline(for: "所有知識點都很穩固！"))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                        NavigationLink(destination: KnowledgePointDetailView(point: point)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(point.key_point_summary ?? "核心觀念")
                                        .font(.appCallout(for: point.key_point_summary ?? "核心觀念"))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    
                                    Text(point.correct_phrase)
                                        .font(.appCaption(for: point.correct_phrase))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                MasteryBarView(masteryLevel: point.mastery_level)
                                    .frame(width: 40)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(index % 2 == 0 ? Color(.systemBackground) : Color(.systemGray6))
                        }
                        .buttonStyle(.plain)
                        
                        if index < points.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

// 【重新設計】分類區域
struct CategoriesSection: View {
    let points: [KnowledgePoint]
    
    private var categorizedPoints: [String: [KnowledgePoint]] {
        Dictionary(grouping: points) { $0.category }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(categorizedPoints.keys.sorted(), id: \.self) { category in
                if let categoryPoints = categorizedPoints[category] {
                    NavigationLink(destination: KnowledgePointGridView(points: categoryPoints, categoryTitle: category)) {
                        ClaudeCategoryCard(category: category, points: categoryPoints)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ClaudeCategoryCard: View {
    let category: String
    let points: [KnowledgePoint]
    
    private var averageMastery: Double {
        points.isEmpty ? 0 : points.map { $0.mastery_level }.reduce(0, +) / Double(points.count)
    }
    
    private var weakPointsCount: Int {
        points.filter { $0.mastery_level < 2.0 }.count
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(category)
                    .font(.appHeadline(for: category))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 16) {
                    Label("\(points.count)", systemImage: "book.closed")
                        .font(.appCaption())
                        .foregroundStyle(.secondary)
                    
                    if weakPointsCount > 0 {
                        Label("\(weakPointsCount) 需加強", systemImage: "exclamationmark.triangle")
                            .font(.appCaption())
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f", averageMastery))
                    .font(.appTitle3())
                    .foregroundStyle(.primary)
                
                Text("平均熟練度")
                    .font(.appCaption2(for: "平均熟練度"))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

// 【重新設計】進度區域
struct ProgressSection: View {
    let points: [KnowledgePoint]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(points.sorted { $0.mastery_level < $1.mastery_level }) { point in
                NavigationLink(destination: KnowledgePointDetailView(point: point)) {
                    ClaudeProgressCard(point: point)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ClaudeProgressCard: View {
    let point: KnowledgePoint
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(point.key_point_summary ?? "核心觀念")
                    .font(.appCallout(for: point.key_point_summary ?? "核心觀念"))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(point.correct_phrase)
                    .font(.appCaption(for: point.correct_phrase))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f", point.mastery_level))
                    .font(.appHeadline())
                    .foregroundStyle(.primary)
                
                MasteryBarView(masteryLevel: point.mastery_level)
                    .frame(width: 60)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

// 【重新設計】排程區域
struct ScheduleSection: View {
    let points: [KnowledgePoint]
    
    private var scheduledPoints: [KnowledgePoint] {
        points.filter { $0.next_review_date != nil }.sorted { $0.next_review_date! < $1.next_review_date! }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(scheduledPoints) { point in
                NavigationLink(destination: KnowledgePointDetailView(point: point)) {
                    ClaudeScheduleCard(point: point)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ClaudeScheduleCard: View {
    let point: KnowledgePoint
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "M月d日"
            return outputFormatter.string(from: date)
        }
        return dateString
    }
    
    private var isOverdue: Bool {
        guard let dateString = point.next_review_date else { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: dateString) else { return false }
        return date < Date()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(point.key_point_summary ?? "核心觀念")
                    .font(.appSubheadline(for: point.key_point_summary ?? "核心觀念"))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(point.correct_phrase)
                    .font(.appCaption(for: point.correct_phrase))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(point.next_review_date ?? ""))
                    .font(.appCaption())
                    .foregroundStyle(isOverdue ? Color(.systemRed) : .primary)
                
                Text(isOverdue ? "已逾期" : "待複習")
                    .font(.appCaption2(for: isOverdue ? "已逾期" : "待複習"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(isOverdue ? Color(.systemRed).opacity(0.1) : Color(.systemGray5))
                    .foregroundStyle(isOverdue ? Color(.systemRed) : .secondary)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isOverdue ? Color(.systemRed).opacity(0.2) : Color.clear, lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

// 【重新設計】狀態視圖
struct ClaudeLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.1)
                .tint(Color.orange)
            
            Text("正在載入數據...")
                .font(.appSubheadline(for: "正在載入數據..."))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ClaudeErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.appLargeTitle(for: "⚠️"))
                .foregroundStyle(Color(.systemOrange))
            
            Text("載入失敗")
                .font(.appTitle3(for: "載入失敗"))
                .foregroundStyle(.primary)
            
            Text(message)
                .font(.appSubheadline(for: message))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("重新載入", action: retry)
                .font(.appSubheadline(for: "重新載入"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.orange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ClaudeEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.appLargeTitle(for: "🧠"))
                .foregroundStyle(Color.orange)
            
            Text("開始您的學習之旅")
                .font(.appTitle3(for: "開始您的學習之旅"))
                .foregroundStyle(.primary)
            
            Text("完成幾道翻譯練習，\n系統就會為您建立個人化的知識分析！")
                .font(.appSubheadline(for: "完成幾道翻譯練習，\n系統就會為您建立個人化的知識分析！"))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}
