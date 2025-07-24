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
    @State private var showingDeleteAlert = false
    @State private var pointToDelete: KnowledgePoint?
    @State private var refreshTrigger = false
    
    // 【新增】根據當前狀態，計算出要顯示的知識點
    private var filteredAndSortedPoints: [KnowledgePoint] {
        let filtered: [KnowledgePoint]
        
        // 1. 執行篩選
        switch filterOption {
        case .all:
            filtered = points
        case .weak:
            filtered = points.filter { $0.masteryLevel < 1.5 }
        case .medium:
            filtered = points.filter { $0.masteryLevel >= 1.5 && $0.masteryLevel < 3.5 }
        case .strong:
            filtered = points.filter { $0.masteryLevel >= 3.5 }
        }
        
        // 2. 執行排序
        switch sortOption {
        case .lowToHigh:
            return filtered.sorted { $0.masteryLevel < $1.masteryLevel }
        case .highToLow:
            return filtered.sorted { $0.masteryLevel > $1.masteryLevel }
        }
    }
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: ModernSpacing.md),
        GridItem(.flexible(), spacing: ModernSpacing.md)
    ]
    
    var body: some View {
        ScrollView {
            KnowledgePointGrid(
                knowledgePoints: filteredAndSortedPoints,
                columns: 2,
                onPointTapped: { point in
                    // 點擊操作將由 NavigationLink 處理
                },
                onPointDeleted: { point in
                    pointToDelete = point
                    showingDeleteAlert = true
                },
                onPointArchived: { point in
                    Task {
                        await archivePoint(point)
                    }
                }
            )
            .padding()
        }
            .navigationTitle(categoryTitle)
            .background(Color.modernBackground)
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
            .alert("確認刪除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("刪除", role: .destructive) {
                    if let pointToDelete = pointToDelete {
                        Task {
                            await deletePoint(pointToDelete)
                        }
                    }
                }
            } message: {
                Text("確定要刪除此知識點嗎？此操作無法復原。")
            }
    }
    
    // MARK: - Helper Methods
    
    private func archivePoint(_ point: KnowledgePoint) async {
        do {
            try await KnowledgePointRepository.shared.archiveKnowledgePoint(
                compositeId: point.compositeId,
                legacyId: point.numericId
            )
            refreshTrigger.toggle()
        } catch {
            print("歸檔知識點失敗: \(error)")
        }
    }
    
    private func deletePoint(_ point: KnowledgePoint) async {
        do {
            try await KnowledgePointRepository.shared.deleteKnowledgePoint(
                compositeId: point.compositeId,
                legacyId: point.numericId
            )
            refreshTrigger.toggle()
        } catch {
            print("刪除知識點失敗: \(error)")
        }
    }
}
