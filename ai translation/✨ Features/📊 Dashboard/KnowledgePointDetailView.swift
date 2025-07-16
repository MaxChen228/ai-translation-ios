// KnowledgePointDetailView.swift

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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ... (VStack 內部內容不變)
                // 區塊一：當時的錯誤情境
                if let sentence = point.user_context_sentence, !sentence.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("當時的作答情境")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        highlightedText(for: sentence, highlight: point.incorrect_phrase_in_context ?? "")
                            .font(.system(.title3, design: .serif))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                
                // 區塊二：正確用法
                VStack(alignment: .leading, spacing: 5) {
                    Text("正確用法")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(point.correct_phrase)
                        .font(.title2.bold())
                        .foregroundColor(.green)
                }
                
                Divider()

                // 區塊三：核心觀念
                VStack(alignment: .leading, spacing: 5) {
                    Text("核心觀念")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(point.explanation ?? "暫無詳細說明。")
                        .font(.body)
                }
                
                Divider()

                // 區塊四：學習統計
                VStack(alignment: .leading, spacing: 12) {
                    Text("學習統計")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    MasteryBarView(masteryLevel: point.mastery_level)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(point.mistake_count)")
                                .font(.headline)
                            Text("錯誤次數")
                                .font(.caption)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(point.correct_count)")
                                .font(.headline)
                            Text("答對次數")
                                .font(.caption)
                        }
                    }
                    .padding(.top, 5)
                }
            }
            .padding()
        }
        .navigationTitle("知識點詳情")
        .navigationBarTitleDisplayMode(.inline)
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
                // 操作成功後返回上一頁
                DispatchQueue.main.async {
                    self.presentationMode.wrappedValue.dismiss()
                }
            } catch {
                // TODO: 顯示錯誤給使用者
                print("封存失敗: \(error)")
            }
        }
    }

    private func deletePoint() {
        Task {
            do {
                try await KnowledgePointAPIService.deletePoint(id: point.id)
                // 操作成功後返回上一頁
                DispatchQueue.main.async {
                    self.presentationMode.wrappedValue.dismiss()
                }
            } catch {
                // TODO: 顯示錯誤給使用者
                print("刪除失敗: \(error)")
            }
        }
    }
    
    private func highlightedText(for fullText: String, highlight target: String) -> Text {
        // ... (這個輔助函式不變)
        var attributedString = AttributedString(fullText)
        if !target.isEmpty, let range = attributedString.range(of: target, options: .caseInsensitive) {
            attributedString[range].backgroundColor = .yellow.opacity(0.5)
            attributedString[range].font = .body.bold()
        }
        return Text(attributedString)
    }
}
