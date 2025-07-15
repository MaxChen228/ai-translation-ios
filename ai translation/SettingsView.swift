// SettingsView.swift

import SwiftUI

struct SettingsView: View {
    // 從儲存中讀取數值，並讓 UI 可以與之綁定
    @State private var reviewCount: Int = SettingsManager.shared.reviewCount
    @State private var newCount: Int = SettingsManager.shared.newCount
    @State private var difficulty: Int = SettingsManager.shared.difficulty
    @State private var length: SettingsManager.SentenceLength = SettingsManager.shared.length

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("每輪學習題數設定")) {
                    // 使用 Stepper 讓使用者可以方便地增減數量
                    Stepper("智慧複習題：\(reviewCount) 題", value: $reviewCount, in: 0...10)
                    Stepper("全新挑戰題：\(newCount) 題", value: $newCount, in: 0...10)
                }
                
                // 【新增】新的設定區塊
                Section(header: Text("新題目客製化設定")) {
                    // 難度滑桿
                    VStack(alignment: .leading, spacing: 4) {
                        Text("題目難度：\(difficulty)")
                        Slider(value: Binding(get: { Double(difficulty) }, set: { difficulty = Int($0) }), in: 1...5, step: 1)
                    }
                    .padding(.vertical, 5)
                    
                    // 長度選擇器
                    Picker("句子長度", selection: $length) {
                        ForEach(SettingsManager.SentenceLength.allCases) { len in
                            Text(len.rawValue).tag(len)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(footer: Text("設定將在下一次請求新題目時生效。")) {
                    EmptyView()
                }
            }
            .navigationTitle("⚙️ 個人化設定")
            .onChange(of: reviewCount) { _, newValue in
                SettingsManager.shared.reviewCount = newValue
            }
            .onChange(of: newCount) { _, newValue in
                SettingsManager.shared.newCount = newValue
            }
            .onChange(of: difficulty) { _, newDifficulty in
                SettingsManager.shared.difficulty = newDifficulty
            }
            .onChange(of: length) { _, newLength in
                SettingsManager.shared.length = newLength
            }
        }
    }
}
