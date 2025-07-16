// KnowledgePointDetailView.swift

import SwiftUI

struct KnowledgePointDetailView: View {
    let point: KnowledgePoint
    
    // 【新增】用於控制 Alert 的狀態
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
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
        // 【新增】工具列項目
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        // TODO: 實作編輯功能
                        alertTitle = "尚未開放"
                        alertMessage = "編輯功能將在未來版本中提供。"
                        showingAlert = true
                    }) {
                        Label("編輯內容", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        // TODO: 實作封存功能
                        alertTitle = "尚未開放"
                        alertMessage = "封存功能將在未來版本中提供。"
                        showingAlert = true
                    }) {
                        Label("封存此點", systemImage: "archivebox")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        // TODO: 實作刪除功能
                        alertTitle = "尚未開放"
                        alertMessage = "刪除功能將在未來版本中提供。"
                        showingAlert = true
                    }) {
                        Label("永久刪除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("好")))
        }
    }
    
    private func highlightedText(for fullText: String, highlight target: String) -> Text {
        var attributedString = AttributedString(fullText)
        
        if !target.isEmpty, let range = attributedString.range(of: target, options: .caseInsensitive) {
            attributedString[range].backgroundColor = .yellow.opacity(0.5)
            attributedString[range].font = .body.bold()
        }
        
        return Text(attributedString)
    }
}
