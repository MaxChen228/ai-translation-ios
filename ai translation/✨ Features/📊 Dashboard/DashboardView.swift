//  DashboardView.swift - Claude 風格現代化設計

import SwiftUI

// 【新增】現代化的檢視模式
enum ModernDashboardMode: String, CaseIterable, Identifiable {
    case overview = "概覽"
    case categories = "分類"
    case progress = "進度"
    case schedule = "排程"
    
    var id: Self { self }
    
    var icon: String {
        switch self {
        case .overview: return "chart.pie.fill"
        case .categories: return "folder.fill"
        case .progress: return "chart.bar.fill"
        case .schedule: return "calendar.circle.fill"
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .overview:
            return LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .categories:
            return LinearGradient(colors: [Color.green, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .progress:
            return LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .schedule:
            return LinearGradient(colors: [Color.indigo, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct DashboardView: View {
    @State private var knowledgePoints: [KnowledgePoint] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedMode: ModernDashboardMode = .overview
    
    // 【新增】計算統計數據
    private var stats: DashboardStats {
        DashboardStats(from: knowledgePoints)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 【新增】現代化的模式選擇器
                ModernModeSelector(selectedMode: $selectedMode)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                if isLoading {
                    ModernLoadingView()
                } else if let errorMessage = errorMessage {
                    ModernErrorView(message: errorMessage) {
                        Task { await fetchDashboardData() }
                    }
                } else if knowledgePoints.isEmpty {
                    ModernEmptyStateView()
                } else {
                    // 【新增】根據模式顯示不同的現代化內容
                    ScrollView {
                        LazyVStack(spacing: 20) {
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
                        .padding()
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("🧠 知識儀表板")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { Task { await fetchDashboardData() } }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundStyle(selectedMode.gradient)
                    }
                    
                    NavigationLink(destination: ArchivedPointsView()) {
                        Image(systemName: "archivebox.fill")
                            .font(.title3)
                            .foregroundStyle(selectedMode.gradient)
                    }
                }
            }
            .onAppear {
                Task { await fetchDashboardData() }
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
            withAnimation(.spring()) {
                self.knowledgePoints = decodedResponse.knowledge_points
            }
        } catch {
            self.errorMessage = "無法獲取數據，請稍後再試。\n(\(error.localizedDescription))"
            print("獲取儀表板數據時發生錯誤: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - 現代化組件

// 【新增】統計數據結構
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

// 【新增】現代化模式選擇器
struct ModernModeSelector: View {
    @Binding var selectedMode: ModernDashboardMode
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(ModernDashboardMode.allCases) { mode in
                ModeButton(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    animation: animation
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedMode = mode
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

// 【新增】模式按鈕組件
struct ModeButton: View {
    let mode: ModernDashboardMode
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Text(mode.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(mode.gradient)
                        .matchedGeometryEffect(id: "selectedMode", in: animation)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// 【新增】概覽區域
struct OverviewSection: View {
    let stats: DashboardStats
    let points: [KnowledgePoint]
    
    var body: some View {
        VStack(spacing: 20) {
            // 統計卡片網格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                StatCard(
                    title: "總知識點",
                    value: "\(stats.totalPoints)",
                    icon: "brain.head.profile",
                    gradient: LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                
                StatCard(
                    title: "平均熟練度",
                    value: String(format: "%.1f", stats.averageMastery),
                    icon: "chart.line.uptrend.xyaxis",
                    gradient: LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                
                StatCard(
                    title: "今日需複習",
                    value: "\(stats.needReviewToday)",
                    icon: "calendar.badge.exclamationmark",
                    gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                
                StatCard(
                    title: "分類數量",
                    value: "\(stats.categoriesCount)",
                    icon: "folder.badge.plus",
                    gradient: LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
            
            // 熟練度分布
            MasteryDistributionCard(stats: stats)
            
            // 最需要關注的知識點
            FocusAreaCard(points: points.filter { $0.mastery_level < 2.0 }.sorted { $0.mastery_level < $1.mastery_level }.prefix(5))
        }
    }
}

// 【新增】統計卡片
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(gradient)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// 【新增】熟練度分布卡片
struct MasteryDistributionCard: View {
    let stats: DashboardStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(.purple)
                Text("熟練度分布")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                MasteryBar(label: "需加強", count: stats.weakPoints, total: stats.totalPoints, color: .red)
                MasteryBar(label: "中等程度", count: stats.mediumPoints, total: stats.totalPoints, color: .orange)
                MasteryBar(label: "已掌握", count: stats.strongPoints, total: stats.totalPoints, color: .green)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        }
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// 【新增】熟練度條
struct MasteryBar: View {
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
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .animation(.spring(), value: percentage)
                }
            }
            .frame(height: 8)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// 【新增】重點關注區域
struct FocusAreaCard: View {
    let points: ArraySlice<KnowledgePoint>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("需要重點關注")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if points.isEmpty {
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                        Text("所有知識點都很穩固！")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(points)) { point in
                        NavigationLink(destination: KnowledgePointDetailView(point: point)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(point.key_point_summary ?? "核心觀念")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    
                                    Text(point.correct_phrase)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                MasteryIndicator(level: point.mastery_level)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        }
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// 【新增】熟練度指示器
struct MasteryIndicator: View {
    let level: Double
    
    private var color: Color {
        if level < 1.5 { return .red }
        else if level < 3.5 { return .orange }
        else { return .green }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(Double(index) < level ? color : Color(.systemGray5))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// 【新增】分類區域
struct CategoriesSection: View {
    let points: [KnowledgePoint]
    
    private var groupedPoints: [String: [KnowledgePoint]] {
        Dictionary(grouping: points, by: { $0.category })
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
            ForEach(groupedPoints.keys.sorted(), id: \.self) { category in
                NavigationLink(destination: KnowledgePointGridView(points: groupedPoints[category]!, categoryTitle: category)) {
                    ModernCategoryCard(
                        title: category,
                        count: groupedPoints[category]!.count,
                        averageMastery: groupedPoints[category]!.map { $0.mastery_level }.reduce(0, +) / Double(groupedPoints[category]!.count)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// 【新增】現代化分類卡片
struct ModernCategoryCard: View {
    let title: String
    let count: Int
    let averageMastery: Double
    
    private var gradient: LinearGradient {
        let hue = abs(title.hashValue) % 360
        return LinearGradient(
            colors: [
                Color(hue: Double(hue) / 360.0, saturation: 0.8, brightness: 0.9),
                Color(hue: Double(hue) / 360.0, saturation: 0.6, brightness: 0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: categoryIcon(for: title))
                    .font(.title2)
                    .foregroundStyle(.white)
                Spacer()
                
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                HStack {
                    Text("平均熟練度")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(String(format: "%.1f", averageMastery))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(gradient)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "詞彙與片語錯誤": return "textformat.abc"
        case "語法結構錯誤": return "textformat.123"
        case "語意與語用錯誤": return "bubble.left.and.bubble.right.fill"
        case "拼寫與格式錯誤": return "textformat"
        default: return "folder.fill"
        }
    }
}

// 【新增】進度區域
struct ProgressSection: View {
    let points: [KnowledgePoint]
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(points.sorted { $0.mastery_level < $1.mastery_level }) { point in
                NavigationLink(destination: KnowledgePointDetailView(point: point)) {
                    ModernProgressCard(point: point)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// 【新增】現代化進度卡片
struct ModernProgressCard: View {
    let point: KnowledgePoint
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(point.key_point_summary ?? "核心觀念")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(point.correct_phrase)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label("\(point.mistake_count)", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    
                    Label("\(point.correct_count)", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                CircularProgressView(progress: point.mastery_level / 5.0)
                
                Text(String(format: "%.1f", point.mastery_level))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        }
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// 【新增】圓形進度視圖
struct CircularProgressView: View {
    let progress: Double
    
    private var color: Color {
        if progress < 0.3 { return .red }
        else if progress < 0.7 { return .orange }
        else { return .green }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 3)
                .frame(width: 40, height: 40)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: progress)
        }
    }
}

// 【新增】排程區域
struct ScheduleSection: View {
    let points: [KnowledgePoint]
    
    private var scheduledPoints: [KnowledgePoint] {
        points.filter { $0.next_review_date != nil }
              .sorted { $0.next_review_date! < $1.next_review_date! }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(scheduledPoints) { point in
                NavigationLink(destination: KnowledgePointDetailView(point: point)) {
                    ModernScheduleCard(point: point)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// 【新增】現代化排程卡片
struct ModernScheduleCard: View {
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
            VStack(alignment: .leading, spacing: 6) {
                Text(point.key_point_summary ?? "核心觀念")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(point.correct_phrase)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(point.next_review_date ?? ""))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isOverdue ? .red : .blue)
                
                if isOverdue {
                    Text("已逾期")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                } else {
                    Text("待複習")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isOverdue ? .red.opacity(0.3) : .clear, lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// 【新增】現代化加載視圖
struct ModernLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            
            Text("AI 正在分析您的學習數據...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 【新增】現代化錯誤視圖
struct ModernErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            
            Text("載入失敗")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("重新載入", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 【新增】現代化空狀態視圖
struct ModernEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("開始您的學習之旅")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("完成幾道翻譯練習，\n系統就會為您建立個人化的知識分析！")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
