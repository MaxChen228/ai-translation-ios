// SettingsView.swift

import SwiftUI

struct SettingsView: View {
    // 從儲存中讀取數值，並讓 UI 可以與之綁定
    @State private var reviewCount: Int = SettingsManager.shared.reviewCount
    @State private var newCount: Int = SettingsManager.shared.newCount

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("每輪學習題數設定")) {
                    // 使用 Stepper 讓使用者可以方便地增減數量
                    Stepper("智慧複習題：\(reviewCount) 題", value: $reviewCount, in: 0...10)
                    Stepper("全新挑戰題：\(newCount) 題", value: $newCount, in: 0...10)
                }
                
                Section(footer: Text("總題數為上方兩者相加。設定將在下一輪學習開始時生效。")) {
                    // 只是為了排版，沒有內容
                }
            }
            .navigationTitle("⚙️ 個人化設定")
            .onChange(of: reviewCount) { oldValue, newValue in
                // 當數值改變時，立刻儲存
                SettingsManager.shared.reviewCount = newValue
            }
            .onChange(of: newCount) { oldValue, newValue in
                // 當數值改變時，立刻儲存
                SettingsManager.shared.newCount = newValue
            }
        }
    }
}
