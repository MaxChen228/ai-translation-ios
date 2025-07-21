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
    
    // 現代化主題色
    var accentColor: Color {
        return Color.modernAccent
    }
}

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel(authManager: AuthenticationManager.shared)
    @State private var selectedMode: ModernDashboardMode = .overview
    @StateObject private var syncManager = KnowledgePointSyncManager.shared
    
    private var stats: DashboardStats {
        DashboardStats(from: viewModel.knowledgePoints)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: ModernSpacing.xs) {
                // 同步狀態視圖
                SyncStatusView()
                    .padding(.horizontal, ModernSpacing.lg)
                    .padding(.top, ModernSpacing.sm)
                
                // 【簡化】模式選擇器
                ModernModeSelector(selectedMode: $selectedMode)
                    .padding(.horizontal, ModernSpacing.lg)
                    .padding(.top, ModernSpacing.md)
                
                if viewModel.isLoading {
                    ModernLoadingView("正在載入知識點數據...", style: .fullscreen)
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let errorMessage = viewModel.errorMessage {
                    DashboardErrorView(message: errorMessage) {
                        Task { await viewModel.loadDashboard() }
                    }
                } else if viewModel.knowledgePoints.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: ModernSpacing.lg) {
                            switch selectedMode {
                            case .overview:
                                OverviewSection(stats: stats, points: viewModel.knowledgePoints)
                            case .categories:
                                CategoriesSection(points: viewModel.knowledgePoints)
                            case .progress:
                               ProgressSection(points: viewModel.knowledgePoints)
                            case .schedule:
                                ScheduleSection(points: viewModel.knowledgePoints)
                            }
                        }
                        .padding(ModernSpacing.lg)
                    }
                }
            }
            .background(Color.modernBackground)
            .navigationTitle("知識儀表板")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { 
                        Task { 
                            await viewModel.refresh()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.modernAccent)
                    }
                    
                    NavigationLink(destination: ArchivedPointsView()) {
                        Image(systemName: "archivebox")
                            .foregroundStyle(Color.modernAccent)
                    }
                }
            }
            .onAppear {
                Task { 
                    await viewModel.loadDashboard()
                    // 檢查並執行自動同步
                    await syncManager.checkAndPerformAutoSync()
                }
                
                #if DEBUG
                // 字體測試代碼
                print("=== 字體載入測試 ===")
                let testFonts = [
                    "SourceHanSerifTCVF-Regular",
                    "SourceHanSerifTCVF-Bold",
                    "SourceHanSerifTCVF-Light"
                ]

                for fontName in testFonts {
                    if UIFont(name: fontName, size: 16) != nil {
                        print("字體載入成功: \(fontName)")
                    } else {
                        print("字體載入失敗: \(fontName)")
                    }
                }
                #endif
            }
        }
    }
    
}

// MARK: - Claude 風格組件


// 【重新設計】Claude 風格模式選擇器
struct ModernModeSelector: View {
    @Binding var selectedMode: ModernDashboardMode
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: ModernSpacing.xs) {
            ForEach(ModernDashboardMode.allCases) { mode in
                ModernModeButton(
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
            RoundedRectangle(cornerRadius: ModernRadius.sm)
                .fill(Color.modernSurface)
        )
    }
}

struct ModernModeButton: View {
    let mode: ModernDashboardMode
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ModernSpacing.sm) {
                Image(systemName: mode.icon)
                    .font(.appFootnote())
                
                Text(mode.rawValue)
                    .font(.appFootnote(for: mode.rawValue))
            }
            .foregroundStyle(isSelected ? .white : Color.modernTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ModernSpacing.sm + 2)
            .padding(.horizontal, ModernSpacing.sm + 4)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: ModernRadius.sm)
                        .fill(Color.modernAccent)
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
        VStack(spacing: ModernSpacing.lg) {
            // 簡約統計卡片
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: ModernSpacing.md), count: 2), spacing: ModernSpacing.md) {
                ModernStatCard(title: "總知識點", value: "\(stats.totalPoints)")
                ModernStatCard(title: "平均熟練度", value: String(format: "%.1f", stats.averageMastery))
                ModernStatCard(title: "今日需複習", value: "\(stats.needReviewToday)")
                ModernStatCard(title: "分類數量", value: "\(stats.categoriesCount)")
            }
            
            // 簡約分布圖
            ModernMasteryCard(stats: stats)
            
            // 關注區域
            ModernFocusCard(points: points.filter { $0.mastery_level < 2.0 }.sorted { $0.mastery_level < $1.mastery_level }.prefix(5))
        }
    }
}

// 【重新設計】簡約統計卡片
struct ModernStatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: ModernSpacing.sm) {
            Text(value)
                .font(.appTitle2(for: value))
                .foregroundStyle(Color.modernTextPrimary)
            
            Text(title)
                .font(.appCaption(for: title))
                .foregroundStyle(Color.modernTextSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
                .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
        }
    }
}

// 【重新設計】簡約熟練度卡片
struct ModernMasteryCard: View {
    let stats: DashboardStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.md) {
            Text("熟練度分布")
                .font(.appHeadline(for: "熟練度分布"))
                .foregroundStyle(Color.modernTextPrimary)
            
            VStack(spacing: 12) {
                ModernMasteryBar(label: "需加強", count: stats.weakPoints, total: stats.totalPoints, color: Color.modernError)
                ModernMasteryBar(label: "中等程度", count: stats.mediumPoints, total: stats.totalPoints, color: Color.modernWarning)
                ModernMasteryBar(label: "已掌握", count: stats.strongPoints, total: stats.totalPoints, color: Color.modernSuccess)
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
                .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
        }
    }
}

struct ModernMasteryBar: View {
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
                .foregroundStyle(Color.modernTextPrimary)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: ModernRadius.xs)
                        .fill(Color.modernDivider)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: ModernRadius.xs)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: percentage)
                }
            }
            .frame(height: 6)
            
            Text("\(count)")
                .font(.appCaption())
                .foregroundStyle(Color.modernTextSecondary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// 【重新設計】簡約關注卡片
struct ModernFocusCard: View {
    let points: ArraySlice<KnowledgePoint>
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.md) {
            HStack {
                Text("需要重點關注")
                    .font(.appHeadline(for: "需要重點關注"))
                    .foregroundStyle(Color.modernTextPrimary)
                Spacer()
            }
            
            if points.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.appLargeTitle())
                        .foregroundStyle(Color.modernSuccess)
                    Text("所有知識點都很穩固！")
                        .font(.appSubheadline(for: "所有知識點都很穩固！"))
                        .foregroundStyle(Color.modernTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: ModernSpacing.xs) {
                    ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                        NavigationLink(destination: KnowledgePointDetailView(point: point)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(point.key_point_summary ?? "核心觀念")
                                            .font(.appCallout(for: point.key_point_summary ?? "核心觀念"))
                                            .foregroundStyle(Color.modernTextPrimary)
                                            .lineLimit(1)
                                        
                                        // 本地知識點標識
                                        if point.ai_review_notes == "本地儲存" {
                                            Image(systemName: "internaldrive")
                                                .font(.appCaption())
                                                .foregroundStyle(Color.modernWarning)
                                        }
                                    }
                                    
                                    Text(point.correct_phrase)
                                        .font(.appCaption(for: point.correct_phrase))
                                        .foregroundStyle(Color.modernTextSecondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                MasteryBarView(masteryLevel: point.mastery_level)
                                    .frame(width: 40)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(index % 2 == 0 ? Color.modernSurface : Color.modernSurface.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        
                        if index < points.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color.modernSurface)
                .clipShape(RoundedRectangle(cornerRadius: ModernRadius.md))
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
                .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
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
                        ModernCategoryCard(category: category, points: categoryPoints)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ModernCategoryCard: View {
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
                    .foregroundStyle(Color.modernTextPrimary)
                
                HStack(spacing: 16) {
                    Label("\(points.count)", systemImage: "book.closed")
                        .font(.appCaption())
                        .foregroundStyle(Color.modernTextSecondary)
                    
                    if weakPointsCount > 0 {
                        Label("\(weakPointsCount) 需加強", systemImage: "exclamationmark.triangle")
                            .font(.appCaption())
                            .foregroundStyle(Color.modernWarning)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f", averageMastery))
                    .font(.appTitle3())
                    .foregroundStyle(Color.modernTextPrimary)
                
                Text("平均熟練度")
                    .font(.appCaption2(for: "平均熟練度"))
                    .foregroundStyle(Color.modernTextSecondary)
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
                .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
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
                    KnowledgePointProgressCard(point: point)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct KnowledgePointProgressCard: View {
    let point: KnowledgePoint
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(point.key_point_summary ?? "核心觀念")
                        .font(.appCallout(for: point.key_point_summary ?? "核心觀念"))
                        .foregroundStyle(Color.modernTextPrimary)
                        .lineLimit(1)
                    
                    // 本地知識點標識
                    if point.ai_review_notes == "本地儲存" {
                        Image(systemName: "internaldrive")
                            .font(.appCaption())
                            .foregroundStyle(Color.modernWarning)
                    }
                }
                
                Text(point.correct_phrase)
                    .font(.appCaption(for: point.correct_phrase))
                    .foregroundStyle(Color.modernTextSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f", point.mastery_level))
                    .font(.appHeadline())
                    .foregroundStyle(Color.modernTextPrimary)
                
                MasteryBarView(masteryLevel: point.mastery_level)
                    .frame(width: 60)
            }
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
                .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
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
                    ModernScheduleCard(point: point)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

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
            VStack(alignment: .leading, spacing: 4) {
                Text(point.key_point_summary ?? "核心觀念")
                    .font(.appSubheadline(for: point.key_point_summary ?? "核心觀念"))
                    .foregroundStyle(Color.modernTextPrimary)
                    .lineLimit(1)
                
                Text(point.correct_phrase)
                    .font(.appCaption(for: point.correct_phrase))
                    .foregroundStyle(Color.modernTextSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(point.next_review_date ?? ""))
                    .font(.appCaption())
                    .foregroundStyle(isOverdue ? Color.modernError : .primary)
                
                Text(isOverdue ? "已逾期" : "待複習")
                    .font(.appCaption2(for: isOverdue ? "已逾期" : "待複習"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(isOverdue ? Color.modernError.opacity(0.1) : Color.modernDivider)
                    .foregroundStyle(isOverdue ? Color.modernError : .secondary)
                    .clipShape(Capsule())
            }
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: ModernRadius.md)
                        .stroke(isOverdue ? Color.modernError.opacity(0.2) : Color.clear, lineWidth: 1)
                }
                .modernShadow()
        }
    }
}

// ModernLoadingView 已移除，直接使用 ModernLoadingView

struct DashboardErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.appLargeTitle())
                .foregroundStyle(Color.modernWarning)
            
            Text("載入失敗")
                .font(.appTitle3(for: "載入失敗"))
                .foregroundStyle(Color.modernTextPrimary)
            
            Text(message)
                .font(.appSubheadline(for: message))
                .foregroundStyle(Color.modernTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("重新載入", action: retry)
                .font(.appSubheadline(for: "重新載入"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.modernAccent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: ModernRadius.sm))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.appLargeTitle())
                .foregroundStyle(Color.modernAccent)
            
            VStack(spacing: 12) {
                Text("開始您的學習之旅")
                    .font(.appTitle3(for: "開始您的學習之旅"))
                    .foregroundStyle(Color.modernTextPrimary)
                
                Text(authManager.isAuthenticated ? 
                     "完成翻譯練習後，系統會為您建立\n個人化的知識點分析！" :
                     "完成訪客模式翻譯練習，\n或註冊以獲得完整學習體驗！")
                    .font(.appSubheadline(for: "完成翻譯練習後..."))
                    .foregroundStyle(Color.modernTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            VStack(spacing: 12) {
                // AI 家教按鈕
                NavigationLink(destination: AITutorView()) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.appBody())
                        Text("開始 AI 翻譯練習")
                            .font(.appSubheadline(for: "開始 AI 翻譯練習"))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.modernAccent)
                    .clipShape(RoundedRectangle(cornerRadius: ModernRadius.md))
                }
                .buttonStyle(.plain)
                
                // 如果未認證，顯示註冊提示
                if !authManager.isAuthenticated {
                    NavigationLink(destination: RegisterView()) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .font(.appBody())
                            Text("註冊獲得完整功能")
                                .font(.appSubheadline(for: "註冊獲得完整功能"))
                        }
                        .foregroundStyle(Color.modernAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.modernAccent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: ModernRadius.md))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}
