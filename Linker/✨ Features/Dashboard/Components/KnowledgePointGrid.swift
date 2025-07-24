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
            ForEach(knowledgePoints, id: \.effectiveId) { point in
                NavigationLink(destination: KnowledgePointDetailView(point: point)) {
                    KnowledgePointCard(
                        point: point,
                        onTapped: { onPointTapped(point) },
                        onDeleted: { onPointDeleted(point) },
                        onArchived: { onPointArchived(point) }
                    )
                }
                .buttonStyle(.plain)
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
        switch point.masteryLevel {
        case 0.8...1.0: return .modernSuccess
        case 0.5..<0.8: return .modernWarning
        default: return .modernError
        }
    }
    
    var masteryDescription: String {
        switch point.masteryLevel {
        case 0.8...1.0: return "已熟練"
        case 0.5..<0.8: return "進展中"
        default: return "需加強"
        }
    }
    
    // 簡約的分類標籤
    var categoryLabel: String {
        switch point.subcategory {
        case "A": return "A"
        case "B": return "B"
        case "C": return "C" 
        case "D": return "D"
        default: return "?"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.lg) {
            // 頂部：分類標籤和操作按鈕
            HStack {
                // 簡約分類標籤
                Text(categoryLabel)
                    .font(.appCaption2(for: "分類"))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.modernTextPrimary)
                    .padding(.horizontal, ModernSpacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.modernAccent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: ModernRadius.xs))
                
                Spacer()
                
                Button(action: { showingActionSheet = true }) {
                    Image(systemName: "ellipsis")
                        .font(.appCaption())
                        .foregroundStyle(Color.modernTextTertiary)
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel("更多選項")
            }
            
            // 主要內容：標題和錯誤提示
            VStack(alignment: .leading, spacing: ModernSpacing.sm) {
                Text(point.displayTitle)
                    .font(.appSubheadline(for: "知識點標題"))
                    .foregroundStyle(Color.modernTextPrimary)
                    .fontWeight(.medium)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                if let incorrectPhrase = point.incorrectPhraseInContext, !incorrectPhrase.isEmpty {
                    Text("錯誤：\(incorrectPhrase)")
                        .font(.appCaption(for: "錯誤內容"))
                        .foregroundStyle(Color.modernTextSecondary)
                        .lineLimit(1)
                }
            }
            
            // 底部：簡潔的熟練度顯示
            HStack(alignment: .center) {
                Text("熟練度")
                    .font(.appCaption(for: "熟練度"))
                    .foregroundStyle(Color.modernTextSecondary)
                
                Spacer()
                
                HStack(spacing: ModernSpacing.xs) {
                    // 簡潔進度條
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.modernBorder.opacity(0.3))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(masteryColor)
                                .frame(
                                    width: geometry.size.width * CGFloat(point.masteryLevel),
                                    height: 4
                                )
                                .animation(.easeOut(duration: 0.4), value: point.masteryLevel)
                        }
                    }
                    .frame(width: 60, height: 4)
                    
                    Text("\(Int(point.masteryLevel * 100))%")
                        .font(.appCaption(for: "百分比"))
                        .foregroundStyle(masteryColor)
                        .fontWeight(.medium)
                        .frame(width: 35, alignment: .trailing)
                }
            }
        }
        .padding(ModernSpacing.lg)
        .background(Color.modernSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: ModernRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .stroke(Color.modernBorder.opacity(0.08), lineWidth: 1)
        )
        .modernShadow(ModernShadow.subtle)
        .accessibleCard(
            label: "知識點：\(point.displayTitle)",
            hint: "輕點以查看詳細內容",
            value: "熟練度 \(Int(point.masteryLevel * 100))%"
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




// MARK: - 空狀態視圖
struct EmptyKnowledgePointsView: View {
    let onCreateFirst: () -> Void
    
    var body: some View {
        VStack(spacing: ModernSpacing.xl) {
            // 簡約圖示
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.modernAccent)
                .accessibilityHidden(true)
            
            VStack(spacing: ModernSpacing.md) {
                Text("開始學習之旅")
                    .font(.appTitle3(for: "空狀態標題"))
                    .foregroundStyle(Color.modernTextPrimary)
                    .fontWeight(.medium)
                
                Text("完成練習後，系統會為您建立\n個人化的知識點分析")
                    .font(.appBody(for: "空狀態說明"))
                    .foregroundStyle(Color.modernTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Button(action: onCreateFirst) {
                Text("開始練習")
                    .font(.appSubheadline(for: "開始練習"))
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.vertical, ModernSpacing.md)
                    .padding(.horizontal, ModernSpacing.xl)
                    .background(Color.modernAccent)
                    .clipShape(RoundedRectangle(cornerRadius: ModernRadius.md))
            }
            .buttonStyle(.plain)
        }
        .padding(ModernSpacing.xxl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("沒有知識點，輕點開始練習按鈕開始學習")
    }
}

// MARK: - 預覽
#Preview("知識點網格") {
    let samplePoints = [
        KnowledgePoint.example(
            id: 1,
            title: "不定冠詞 'a' 後接的形容詞 'extensive' 是...",
            category: "詞彙與片語錯誤",
            subcategory: "A",
            masteryLevel: 0.85,
            studyCount: 15,
            incorrectPhrase: "an extensive"
        ),
        KnowledgePoint.example(
            id: 2,
            title: "主詞與動詞之間不應使用逗號",
            category: "語法結構錯誤", 
            subcategory: "B",
            masteryLevel: 0.65,
            studyCount: 8,
            incorrectPhrase: "challenges are"
        ),
        KnowledgePoint.example(
            id: 3,
            title: "不定冠詞 'a/an' 的使用錯誤",
            category: "拼寫與格式錯誤",
            subcategory: "D", 
            masteryLevel: 0.25,
            studyCount: 3,
            incorrectPhrase: "an advantageous"
        ),
        KnowledgePoint.example(
            id: 4,
            title: "語意表達需要改進",
            category: "語意與語用錯誤",
            subcategory: "C",
            masteryLevel: 0.92,
            studyCount: 22,
            incorrectPhrase: "meaning clarity"
        )
    ]
    
    NavigationView {
        ScrollView {
            LazyVStack(spacing: ModernSpacing.lg) {
                // 標題區域
                VStack(alignment: .leading, spacing: ModernSpacing.md) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("拼字與格式錯誤")
                                .font(.appTitle(for: "頁面標題"))
                                .foregroundStyle(Color.modernTextPrimary)
                                .fontWeight(.bold)
                            
                            Text("共 \(samplePoints.count) 個知識點")
                                .font(.appCallout(for: "統計資訊"))
                                .foregroundStyle(Color.modernTextSecondary)
                        }
                        
                        Spacer()
                        
                        // 格式選擇器
                        ModernSegmentedControl(
                            selection: .constant("網格"),
                            options: [
                                (value: "網格", label: "網格", icon: "square.grid.2x2"),
                                (value: "列表", label: "列表", icon: "list.bullet")
                            ]
                        )
                    }
                    
                    // 簡約分類統計
                    HStack(spacing: ModernSpacing.sm) {
                        CategoryBadge(category: "A", count: 1)
                        CategoryBadge(category: "B", count: 1) 
                        CategoryBadge(category: "C", count: 1)
                        CategoryBadge(category: "D", count: 1)
                        
                        Spacer()
                    }
                }
                
                // 知識點網格
                KnowledgePointGrid(knowledgePoints: samplePoints, columns: 2)
                
                // 分隔線
                ModernDivider()
                
                // 空狀態展示
                EmptyKnowledgePointsView(onCreateFirst: {})
            }
            .padding()
        }
        .background(Color.modernBackground)
        .navigationTitle("知識點展示")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 簡約分類徽章組件
struct CategoryBadge: View {
    let category: String
    let count: Int
    
    var body: some View {
        HStack(spacing: ModernSpacing.xs) {
            Text(category)
                .font(.appCaption2(for: "分類標籤"))
                .fontWeight(.medium)
                .foregroundStyle(Color.modernTextPrimary)
            
            Text("\(count)")
                .font(.appCaption2(for: "分類數量"))
                .foregroundStyle(Color.modernTextSecondary)
        }
        .padding(.horizontal, ModernSpacing.sm)
        .padding(.vertical, ModernSpacing.xs)
        .background(Color.modernAccent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: ModernRadius.xs))
    }
}

// MARK: - 知識點數據模型擴展
extension KnowledgePoint {
    // 顯示用的標題
    var displayTitle: String {
        return keyPointSummary ?? correctPhrase
    }
    
    // 學習次數（基於錯誤和正確次數）
    var studyCount: Int {
        return mistakeCount + correctCount
    }
    
    // 最後學習時間（從 API 格式轉換）
    var lastStudiedAt: Date? {
        guard let dateString = lastAiReviewDate else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    // 用於快速創建範例數據的便利初始化器
    static func example(
        id: Int,
        title: String,
        category: String,
        subcategory: String = "",
        masteryLevel: Double,
        studyCount: Int = 0,
        incorrectPhrase: String? = nil
    ) -> KnowledgePoint {
        let mistakeCount = studyCount > 0 ? Int.random(in: 1...max(1, studyCount/3)) : 0
        let correctCount = max(0, studyCount - mistakeCount)
        
        return KnowledgePoint(
            compositeId: nil,
            legacyId: id,
            oldId: nil,
            category: category,
            subcategory: subcategory,
            correctPhrase: title,
            explanation: "這是一個關於 \(category) 的知識點範例解釋。",
            userContextSentence: incorrectPhrase != nil ? "使用者在句子中寫了：\(incorrectPhrase!)" : nil,
            incorrectPhraseInContext: incorrectPhrase,
            keyPointSummary: title,
            masteryLevel: masteryLevel,
            mistakeCount: mistakeCount,
            correctCount: correctCount,
            nextReviewDate: nil,
            isArchived: false,
            aiReviewNotes: masteryLevel > 0.8 ? "表現優秀！" : masteryLevel > 0.5 ? "需要多練習。" : "建議重新學習基礎概念。",
            lastAiReviewDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-Double.random(in: 0...86400*7)))
        )
    }
}