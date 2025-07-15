// KnowledgePointDetailView.swift

import SwiftUI

struct KnowledgePointDetailView: View {
    let point: KnowledgePoint
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // 區塊一：當時的錯誤情境
                if let sentence = point.user_context_sentence, !sentence.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("當時的作答情境")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // 呼叫最終修正版的螢光筆函式
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
    }
    
    // 【最終修正】移除 @ViewBuilder，因為函式內部包含變數宣告等非 View 邏輯
    private func highlightedText(for fullText: String, highlight target: String) -> Text {
        var attributedString = AttributedString(fullText)
        
        if !target.isEmpty, let range = attributedString.range(of: target, options: .caseInsensitive) {
            attributedString[range].backgroundColor = .yellow.opacity(0.5)
            attributedString[range].font = .body.bold()
        }
        
        return Text(attributedString)
    }
}
