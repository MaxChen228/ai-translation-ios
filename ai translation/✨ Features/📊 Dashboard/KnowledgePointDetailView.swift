//  KnowledgePointDetailView.swift

import SwiftUI

struct KnowledgePointDetailView: View {
    let point: KnowledgePoint
    
    // 用於返回上一頁
    @Environment(\.presentationMode) var presentationMode
    
    // 用於控制 Alert 的狀態
    @State private var showingConfirmationAlert = false
    @State private var alertConfig: AlertConfig?
    
    struct AlertConfig {
        let title: String
        let message: String
        let primaryAction: () -> Void
    }
    
    var body: some View {
        Form {
            // --- 第一區塊：學習狀態 (維持不變) ---
            Section(header: Text("學習狀態")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("熟練度")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    MasteryBarView(masteryLevel: point.mastery_level)
                }
                .padding(.vertical, 8)
                
                HStack {
                    Label("錯誤次數", systemImage: "xmark.circle")
                    Spacer()
                    Text("\(point.mistake_count) 次")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("答對次數", systemImage: "checkmark.circle")
                    Spacer()
                    Text("\(point.correct_count) 次")
                        .foregroundColor(.secondary)
                }
                
                if let nextReviewDateString = point.next_review_date,
                   let nextReviewDate = ISO8601DateFormatter().date(from: nextReviewDateString) {
                    HStack {
                        Label("下次複習", systemImage: "calendar.badge.clock")
                        Spacer()
                        Text(nextReviewDate, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // --- 第二區塊：錯誤上下文 (【核心修改】) ---
            if let sentence = point.user_context_sentence, !sentence.isEmpty, let incorrectPhrase = point.incorrect_phrase_in_context {
                Section(header: Text("錯誤上下文")) {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // 【新的引言卡片樣式】
                        HStack(spacing: 0) {
                            // 左側的裝飾色塊
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: 4)
                                .padding(.trailing, 12)
                            
                            // 引言內容
                            VStack(alignment: .leading, spacing: 4) {
                                Label("你翻譯的句子", systemImage: "text.quote")
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                                
                                Text(sentence)
                                    .font(.system(.body, design: .serif)) // 使用襯線字體增加設計感
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.05))
                        .cornerRadius(8)
                        
                        // 【保留的錯誤片語樣式】
                        VStack(alignment: .leading, spacing: 5) {
                            Text("你的錯誤片語：")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(incorrectPhrase)
                                .font(.system(.body, design: .monospaced).bold())
                                .foregroundStyle(.red)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // --- 第三區塊：核心知識點 (維持不變) ---
            Section(header: Text("核心知識點")) {
                VStack(alignment: .leading, spacing: 15) {
                    Label {
                        Text("正確用法")
                    } icon: {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                    .font(.headline)
                    
                    Text(point.correct_phrase)
                        .font(.system(.title3, design: .monospaced).bold())
                        .foregroundColor(.green)
                        .padding(.leading, 34)
                    
                    if let explanation = point.explanation, !explanation.isEmpty {
                        Divider().padding(.vertical, 5)
                        
                        Label {
                            Text("用法解析")
                        } icon: {
                            Image(systemName: "sparkles")
                                .foregroundColor(.accentColor)
                        }
                        .font(.headline)
                        
                        Text(explanation)
                            .font(.body)
                            .padding(.leading, 34)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(point.key_point_summary ?? "知識點詳情")
        .navigationBarTitleDisplayMode(.inline)
        // Toolbar 和後續邏輯維持不變
        .toolbar {
             ToolbarItem(placement: .navigationBarTrailing) {
                 Menu {
                     Button(action: {
                         // TODO: 實作編輯功能
                     }) {
                         Label("編輯內容", systemImage: "pencil")
                     }
                     
                     Button(action: {
                         self.alertConfig = AlertConfig(
                             title: "確認封存",
                             message: "您確定要封存「\(point.correct_phrase)」嗎？您之後可以在封存區找到它。",
                             primaryAction: {
                                 archivePoint()
                             }
                         )
                         self.showingConfirmationAlert = true
                     }) {
                         Label("封存此點", systemImage: "archivebox")
                     }
                     
                     Divider()
                     
                     Button(role: .destructive, action: {
                         self.alertConfig = AlertConfig(
                             title: "確認刪除",
                             message: "您確定要永久刪除「\(point.correct_phrase)」嗎？此操作無法復原。",
                             primaryAction: {
                                 deletePoint()
                             }
                         )
                         self.showingConfirmationAlert = true
                     }) {
                         Label("永久刪除", systemImage: "trash")
                     }
                 } label: {
                     Image(systemName: "ellipsis.circle")
                 }
             }
         }
         .alert(isPresented: $showingConfirmationAlert) {
             Alert(
                 title: Text(alertConfig?.title ?? "確認"),
                 message: Text(alertConfig?.message ?? ""),
                 primaryButton: .destructive(Text("確定")) {
                     alertConfig?.primaryAction()
                 },
                 secondaryButton: .cancel(Text("取消"))
             )
         }
    }
    
    private func archivePoint() {
        Task {
            do {
                try await KnowledgePointAPIService.archivePoint(id: point.id)
                await MainActor.run {
                    self.presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("封存失敗: \(error)")
            }
        }
    }

    private func deletePoint() {
        Task {
            do {
                try await KnowledgePointAPIService.deletePoint(id: point.id)
                await MainActor.run {
                    self.presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("刪除失敗: \(error)")
            }
        }
    }
}

#Preview {
    // 預覽用的假資料
    let samplePoint = KnowledgePoint(
        id: 1,
        category: "文法結構錯誤",
        subcategory: "動詞時態",
        correct_phrase: "has been studying",
        explanation: "當描述一個從過去持續到現在的動作時，應該使用現在完成進行式，以強調動作的持續性。",
        user_context_sentence: "He is studying English for three years.",
        incorrect_phrase_in_context: "is studying",
        key_point_summary: "現在完成進行式",
        mastery_level: 0.35,
        mistake_count: 3,
        correct_count: 1,
        next_review_date: "2025-07-20T10:00:00Z",
        is_archived: false
    )
    
    return NavigationView {
        KnowledgePointDetailView(point: samplePoint)
    }
}
