// KnowledgePointGridView.swift

import SwiftUI

// 【新增】定義排序選項的枚舉
enum SortOption: String, CaseIterable, Identifiable {
    case lowToHigh = "熟練度由低到高"
    case highToLow = "熟練度由高到低"
    var id: Self { self }
}

// 【新增】定義篩選選項的枚舉
enum FilterOption: String, CaseIterable, Identifiable {
    case all = "全部顯示"
    case weak = "僅顯示弱點 (紅色)"
    case medium = "僅顯示中等 (橘色)"
    case strong = "僅顯示強項 (綠色)"
    var id: Self { self }
}


struct KnowledgePointGridView: View {
    let points: [KnowledgePoint]
    let categoryTitle: String
    
    // 【新增】用來儲存當前排序與篩選狀態的變數
    @State private var sortOption: SortOption = .lowToHigh
    @State private var filterOption: FilterOption = .all
    
    // 【新增】根據當前狀態，計算出要顯示的知識點
    private var filteredAndSortedPoints: [KnowledgePoint] {
        let filtered: [KnowledgePoint]
        
        // 1. 執行篩選
        switch filterOption {
        case .all:
            filtered = points
        case .weak:
            filtered = points.filter { $0.mastery_level < 1.5 }
        case .medium:
            filtered = points.filter { $0.mastery_level >= 1.5 && $0.mastery_level < 3.5 }
        case .strong:
            filtered = points.filter { $0.mastery_level >= 3.5 }
        }
        
        // 2. 執行排序
        switch sortOption {
        case .lowToHigh:
            return filtered.sorted { $0.mastery_level < $1.mastery_level }
        case .highToLow:
            return filtered.sorted { $0.mastery_level > $1.mastery_level }
        }
    }
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredAndSortedPoints) { point in
                        NavigationLink(destination: KnowledgePointDetailView(point: point)) {
                            VStack(alignment: .leading, spacing: 10) {
                                // 【核心修改】: 主要標題改為顯示 AI 生成的要點標題
                                Text(point.key_point_summary ?? "核心觀念")
                                    .font(.appHeadline(for: point.key_point_summary ?? "核心觀念"))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2) // 限制為兩行
                                    .minimumScaleFactor(0.8) // 如果文字太長，允許縮小
                                    .frame(height: 45, alignment: .top) // 固定文字區塊高度
                                
                                // 將原本的正確用法作為補充說明，放在下方
                                Text(point.correct_phrase)
                                    .font(.appCaption(for: point.correct_phrase))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Spacer(minLength: 0)
                                
                                MasteryBarView(masteryLevel: point.mastery_level)
                            }
                            .padding()
                            .frame(minHeight: 120)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(categoryTitle)
            .background(Color(UIColor.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("排序方式", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        
                        Picker("篩選熟練度", selection: $filterOption) {
                            ForEach(FilterOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }

                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
}
