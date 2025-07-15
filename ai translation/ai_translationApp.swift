// ai_translationApp.swift

import SwiftUI

@main
struct ai_translationApp: App {
    // 建立一個 SessionManager，讓整個 App 共享
    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            // 使用 TabView 來建立分頁介面
            TabView {
                // 第一個分頁：題目列表
                ContentView()
                    .tabItem {
                        Image(systemName: "list.bullet.rectangle.portrait")
                        Text("學習")
                    }
                
                // 第二個分頁：新的儀表板
                DashboardView()
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                        Text("儀表板")
                    }
            }
            // 將 sessionManager 注入到所有分頁的環境中
            .environmentObject(sessionManager)
        }
    }
}
