// ai_translationApp.swift

import SwiftUI

@main
struct ai_translationApp: App {
    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            TabView {
                // 學習日曆分頁（改為第一個）
                LearningCalendarView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("日曆")
                    }
                
                // 學習分頁（改為第二個）
                ContentView()
                    .tabItem {
                        Image(systemName: "list.bullet.rectangle.portrait")
                        Text("學習")
                    }
                
                // 🆕 新增閱讀分頁
                ReaderLibraryView()
                    .tabItem {
                        Image(systemName: "book.fill")
                        Text("閱讀")
                    }
                
                // 儀表板分頁
                DashboardView()
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                        Text("儀表板")
                    }
                
                // 設定分頁
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("設定")
                    }
            }
            .environmentObject(sessionManager)
        }
    }
}
