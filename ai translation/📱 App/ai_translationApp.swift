// ai_translationApp.swift - 完整重寫版本

import SwiftUI

@main
struct ai_translationApp: App {
    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environmentObject(sessionManager)
        }
    }
}

// MARK: - 主要內容視圖

struct MainContentView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        TabView {
            // 閱讀區域 - 完全獨立
            ReadingAreaView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("閱讀")
                }
            
            // 學習區域 - 完全獨立
            LearningAreaView()
                .tabItem {
                    Image(systemName: "graduationcap.fill")
                    Text("學習")
                }
        }
        .environmentObject(sessionManager)
    }
}

#Preview {
    MainContentView()
        .environmentObject(SessionManager())
}
