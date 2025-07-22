// AllKnowledgePointsListView.swift

import SwiftUI

struct AllKnowledgePointsListView: View {
    let points: [KnowledgePoint]
    let onDataNeedsRefresh: () -> Void // 用於通知 DashboardView 刷新
    
    // @Environment 用於讀取系統環境值，例如 editMode
    @Environment(\.editMode) private var editMode
    
    // @State 用於儲存視圖的內部狀態
    @State private var selection = Set<Int>() // 追蹤被選中的項目 ID
    
    var body: some View {
        VStack {
            // 使用 List 來顯示列表，並綁定 selection
            List(selection: $selection) {
                ForEach(points) { point in
                    NavigationLink(destination: KnowledgePointDetailView(point: point)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(point.keyPointSummary ?? "核心觀念")
                                .font(.appHeadline(for: point.keyPointSummary ?? "核心觀念"))
                                .lineLimit(1)
                            Text(point.correctPhrase)
                                .font(.appCaption(for: point.correctPhrase))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, ModernSpacing.sm)
                    }
                    // 讓每個項目可以用它的資料庫 ID 來標識
                    .tag(point.id)
                }
            }
            .listStyle(.insetGrouped)
            // 將 editMode 的狀態綁定到我們的 @Environment 變數上
            .environment(\.editMode, editMode)
            // 導覽列標題和按鈕
            .navigationTitle("全部知識點 (\(points.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // 這個按鈕會切換編輯模式
                    EditButton()
                }
            }
            
            // 如果在編輯模式下，且有選中項目，就顯示底部的操作欄
            if editMode?.wrappedValue.isEditing == true && !selection.isEmpty {
                BottomActionBar(
                    selectionCount: selection.count,
                    onArchiveAction: {
                        Task {
                            await batchArchiveAction()
                        }
                    }
                )
                .transition(.move(edge: .bottom))
            }
        }
    }
    
    // 批次封存的執行函式
    private func batchArchiveAction() async {
        let selectedIDs = Array(selection)
        
        do {
            try await UnifiedAPIService.shared.batchArchiveKnowledgePoints(ids: selectedIDs)
            // 清空選中項目
            selection.removeAll()
            // 退出編輯模式
            editMode?.wrappedValue = .inactive
            // 通知主視圖刷新資料
            onDataNeedsRefresh()
        } catch {
            // 在此可以加入錯誤處理的 Alert
            print("批次封存失敗: \(error)")
        }
    }
}

// 為了保持程式碼整潔，將底部操作欄拆分成一個子視圖
struct BottomActionBar: View {
    let selectionCount: Int
    let onArchiveAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text("已選取 \(selectionCount) 個項目")
                    .font(.appSubheadline(for: "已選取項目"))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: onArchiveAction) {
                    Text("封存")
                        .font(.appHeadline(for: "封存"))
                        .foregroundStyle(Color.modernAccent)
                }
            }
            .padding()
            .background(.bar) // 使用系統的模糊背景
        }
    }
}
