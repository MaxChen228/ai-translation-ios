// ai_translationApp.swift

import SwiftUI

@main
struct ai_translationApp: App {
    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            TabView {
                // 第一個分頁：學習
                ContentView()
                    .tabItem {
                        Image(systemName: "list.bullet.rectangle.portrait")
                        Text("學習")
                    }
                
                // 第二個分頁：儀表板
                DashboardView()
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                        Text("儀表板")
                    }
                
                // --- 新增開始 ---
                // 第三個分頁：新的單字卡功能
                DeckSelectionView()
                    .tabItem {
                        Image(systemName: "square.stack.3d.up.fill")
                        Text("單字卡")
                    }
                // 【新增】設定分頁
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("設定")
                    }
                // --- 新增結束 ---
            }
            .environmentObject(sessionManager)
        }
    }
}
