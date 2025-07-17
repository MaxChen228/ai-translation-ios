// SettingsView.swift

import SwiftUI

struct SettingsView: View {
    // 從儲存中讀取數值，並讓 UI 可以與之綁定
    @State private var reviewCount: Int = SettingsManager.shared.reviewCount
    @State private var newCount: Int = SettingsManager.shared.newCount
    @State private var difficulty: Int = SettingsManager.shared.difficulty
    @State private var length: SettingsManager.SentenceLength = SettingsManager.shared.length
    @State private var dailyGoal: Int = SettingsManager.shared.dailyGoal
    // 【vNext 新增】綁定模型選擇的狀態
    @State private var generationModel: SettingsManager.AIModel = SettingsManager.shared.generationModel
    @State private var gradingModel: SettingsManager.AIModel = SettingsManager.shared.gradingModel


    var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("每輪學習題數設定")) {
                        Stepper("智慧複習題：\(reviewCount) 題", value: $reviewCount, in: 0...10)
                        Stepper("全新挑戰題：\(newCount) 題", value: $newCount, in: 0...10)
                    }
                    
                    Section(header: Text("新題目客製化設定")) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("題目難度：\(difficulty)")
                            Slider(value: Binding(get: { Double(difficulty) }, set: { difficulty = Int($0) }), in: 1...5, step: 1)
                        }
                        .padding(.vertical, 5)
                        
                        Picker("句子長度", selection: $length) {
                            ForEach(SettingsManager.SentenceLength.allCases) { len in
                                Text(len.displayName).tag(len)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // 【vNext 新增】AI 模型設定區塊
                    Section(header: Text("AI 模型設定"), footer: Text("更強的模型通常更準確，但回應速度可能較慢。")) {
                        Picker("出題模型", selection: $generationModel) {
                            ForEach(SettingsManager.AIModel.allCases) { model in
                                Text(model.displayName).tag(model)
                            }
                        }
                        
                        Picker("批改模型", selection: $gradingModel) {
                            ForEach(SettingsManager.AIModel.allCases) { model in
                                Text(model.displayName).tag(model)
                            }
                        }
                    }

                    Section(header: Text("學習目標設定")) {
                        Stepper("每日目標：\(dailyGoal) 題", value: $dailyGoal, in: 1...50)
                    }
                    
                    Section(footer: Text("設定將在下一次請求新題目時生效。")) {
                        EmptyView()
                    }
                }
                .navigationTitle("⚙️ 個人化設定")
                .onAppear {
                    // 當頁面出現時，從管理器同步一次最新的值
                    self.reviewCount = SettingsManager.shared.reviewCount
                    self.newCount = SettingsManager.shared.newCount
                    self.difficulty = SettingsManager.shared.difficulty
                    self.length = SettingsManager.shared.length
                    self.dailyGoal = SettingsManager.shared.dailyGoal
                    // 【vNext 新增】同步模型選擇
                    self.generationModel = SettingsManager.shared.generationModel
                    self.gradingModel = SettingsManager.shared.gradingModel
                }
                // onChange 事件綁定 (此處省略未變動部分)
                .onChange(of: reviewCount) { _, newValue in SettingsManager.shared.reviewCount = newValue }
                .onChange(of: newCount) { _, newValue in SettingsManager.shared.newCount = newValue }
                .onChange(of: difficulty) { _, newDifficulty in SettingsManager.shared.difficulty = newDifficulty }
                .onChange(of: length) { _, newLength in SettingsManager.shared.length = newLength }
                .onChange(of: dailyGoal) { _, newGoal in SettingsManager.shared.dailyGoal = newGoal }
                // 【vNext 新增】監聽並儲存模型的變更
                .onChange(of: generationModel) { _, newModel in
                    SettingsManager.shared.generationModel = newModel
                }
                .onChange(of: gradingModel) { _, newModel in
                    SettingsManager.shared.gradingModel = newModel
                }
            }
        }
}
