// KnowledgePointGrid.swift - 知識點網格顯示組件

import SwiftUI

struct KnowledgePointGrid: View {
    let knowledgePoints: [KnowledgePoint]
    let columns: Int
    let onPointTapped: (KnowledgePoint) -> Void
    let onPointDeleted: (KnowledgePoint) -> Void
    let onPointArchived: (KnowledgePoint) -> Void
    
    init(
        knowledgePoints: [KnowledgePoint],
        columns: Int = 2,
        onPointTapped: @escaping (KnowledgePoint) -> Void = { _ in },
        onPointDeleted: @escaping (KnowledgePoint) -> Void = { _ in },
        onPointArchived: @escaping (KnowledgePoint) -> Void = { _ in }
    ) {
        self.knowledgePoints = knowledgePoints
        self.columns = columns
        self.onPointTapped = onPointTapped
        self.onPointDeleted = onPointDeleted
        self.onPointArchived = onPointArchived
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: ModernSpacing.md), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: ModernSpacing.md) {
            ForEach(knowledgePoints, id: \.id) { point in
                KnowledgePointCard(
                    point: point,
                    onTapped: { onPointTapped(point) },
                    onDeleted: { onPointDeleted(point) },
                    onArchived: { onPointArchived(point) }
                )
            }
        }
    }
}

struct KnowledgePointCard: View {
    let point: KnowledgePoint
    let onTapped: () -> Void
    let onDeleted: () -> Void
    let onArchived: () -> Void
    
    @State private var showingActionSheet = false
    
    var masteryColor: Color {
        switch point.mastery_level {
        case 0.8...1.0: return .modernSuccess
        case 0.5..<0.8: return .modernWarning
        default: return .modernError
        }
    }
    
    var masteryDescription: String {
        switch point.mastery_level {
        case 0.8...1.0: return "已熟練"
        case 0.5..<0.8: return "進展中"
        default: return "需加強"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.md) {
            // 標題與操作按鈕
            HStack {
                VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                    Text(point.displayTitle)
                        .font(.appCallout(for: "知識點標題"))
                        .foregroundStyle(Color.modernTextPrimary)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    Text(point.category)
                        .font(.appCaption2(for: "分類標籤"))
                        .foregroundStyle(Color.modernTextTertiary)
                        .padding(.horizontal, ModernSpacing.sm)
                        .padding(.vertical, ModernSpacing.xs)
                        .background(Color.modernAccentSoft)
                        .cornerRadius(ModernRadius.xs)
                }
                
                Spacer()
                
                Button(action: { showingActionSheet = true }) {
                    Image(systemName: "ellipsis")
                        .font(.appCallout())
                        .foregroundStyle(Color.modernTextSecondary)
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel("更多選項")
                .accessibilityHint("顯示知識點操作選單")
            }
            
            // 熟練度進度條
            VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                HStack {
                    Text("熟練度")
                        .font(.appCaption(for: "熟練度標籤"))
                        .foregroundStyle(Color.modernTextSecondary)
                    
                    Spacer()
                    
                    Text(masteryDescription)
                        .font(.appCaption(for: "熟練度描述"))
                        .foregroundStyle(masteryColor)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: point.mastery_level)
                    .progressViewStyle(ModernProgressViewStyle(color: masteryColor))
                    .accessibilityLabel("熟練度進度")
                    .accessibilityValue("\(Int(point.mastery_level * 100))%，\(masteryDescription)")
            }
            
            // 統計資訊
            HStack(spacing: ModernSpacing.md) {
                StatisticItem(
                    icon: "clock",
                    value: "\(point.studyCount)",
                    label: "學習次數"
                )
                
                StatisticItem(
                    icon: "calendar",
                    value: formatDate(point.lastStudiedAt),
                    label: "最後學習"
                )
            }
        }
        .padding(ModernSpacing.lg)
        .modernCard(.standard)
        .onTapGesture { onTapped() }
        .accessibleCard(
            label: "知識點：\(point.displayTitle)",
            hint: "輕點以查看詳細內容",
            value: "熟練度 \(Int(point.mastery_level * 100))%"
        )
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("知識點操作"),
                message: Text(point.displayTitle),
                buttons: [
                    .default(Text("編輯")) { onTapped() },
                    .default(Text("歸檔")) { onArchived() },
                    .destructive(Text("刪除")) { onDeleted() },
                    .cancel()
                ]
            )
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "未學習" }
        
        let calendar = Calendar.current
        _ = Date()
        
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
    }
}

struct StatisticItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: ModernSpacing.xs) {
            Image(systemName: icon)
                .font(.appCaption())
                .foregroundStyle(Color.modernTextTertiary)
                .frame(width: 12)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.appCaption(for: "統計數值"))
                    .foregroundStyle(Color.modernTextPrimary)
                    .fontWeight(.medium)
                
                Text(label)
                    .font(.appCaption2(for: "統計標籤"))
                    .foregroundStyle(Color.modernTextTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label)：\(value)")
    }
}

// MARK: - 自定義進度條樣式
struct ModernProgressViewStyle: ProgressViewStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景軌道
                RoundedRectangle(cornerRadius: ModernRadius.xs)
                    .fill(color.opacity(0.1))
                    .frame(height: 4)
                
                // 進度條
                RoundedRectangle(cornerRadius: ModernRadius.xs)
                    .fill(color)
                    .frame(
                        width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0),
                        height: 4
                    )
                    .animation(.easeInOut(duration: 0.5), value: configuration.fractionCompleted)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - 網格佈局選項
enum GridLayout: String, CaseIterable, Identifiable {
    case compact = "緊湊"
    case comfortable = "舒適"
    case spacious = "寬鬆"
    
    var id: String { rawValue }
    
    var columns: Int {
        switch self {
        case .compact: return 3
        case .comfortable: return 2
        case .spacious: return 1
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .compact: return ModernSpacing.sm
        case .comfortable: return ModernSpacing.md
        case .spacious: return ModernSpacing.lg
        }
    }
}

// MARK: - 空狀態視圖
struct EmptyKnowledgePointsView: View {
    let onCreateFirst: () -> Void
    
    var body: some View {
        VStack(spacing: ModernSpacing.xl) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(Color.modernTextTertiary)
                .accessibilityHidden(true)
            
            VStack(spacing: ModernSpacing.md) {
                Text("還沒有知識點")
                    .font(.appTitle2(for: "空狀態標題"))
                    .foregroundStyle(Color.modernTextPrimary)
                    .fontWeight(.semibold)
                
                Text("開始您的學習之旅，創建第一個知識點")
                    .font(.appBody(for: "空狀態描述"))
                    .foregroundStyle(Color.modernTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            ModernButton("創建知識點", icon: "plus", action: onCreateFirst)
                .frame(maxWidth: 200)
        }
        .padding(ModernSpacing.xxl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("沒有知識點，輕點創建知識點按鈕開始學習")
    }
}

// MARK: - 預覽
#Preview("知識點網格") {
    let samplePoints = [
        KnowledgePoint.example(
            id: 1,
            title: "什麼是 SwiftUI？",
            category: "iOS 開發",
            masteryLevel: 0.85
        ),
        KnowledgePoint.example(
            id: 2,
            title: "如何使用 @State？",
            category: "SwiftUI",
            masteryLevel: 0.45
        )
    ]
    
    NavigationView {
        ScrollView {
            VStack(spacing: ModernSpacing.lg) {
                KnowledgePointGrid(knowledgePoints: samplePoints)
                
                EmptyKnowledgePointsView(onCreateFirst: {})
            }
            .padding()
        }
        .background(Color.modernBackground)
        .navigationTitle("知識點網格預覽")
    }
}

// MARK: - 知識點數據模型擴展
extension KnowledgePoint {
    // 顯示用的標題
    var displayTitle: String {
        return key_point_summary ?? correct_phrase
    }
    
    // 學習次數（基於錯誤和正確次數）
    var studyCount: Int {
        return mistake_count + correct_count
    }
    
    // 最後學習時間（從 API 格式轉換）
    var lastStudiedAt: Date? {
        guard let dateString = last_ai_review_date else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    // 用於快速創建範例數據的便利初始化器
    static func example(
        id: Int,
        title: String,
        category: String,
        masteryLevel: Double
    ) -> KnowledgePoint {
        return KnowledgePoint(
            id: id,
            category: category,
            subcategory: "",
            correct_phrase: title,
            explanation: "範例解釋",
            user_context_sentence: nil,
            incorrect_phrase_in_context: nil,
            key_point_summary: title,
            mastery_level: masteryLevel,
            mistake_count: Int.random(in: 0...5),
            correct_count: Int.random(in: 1...10),
            next_review_date: nil,
            is_archived: false,
            ai_review_notes: nil,
            last_ai_review_date: ISO8601DateFormatter().string(from: Date())
        )
    }
}