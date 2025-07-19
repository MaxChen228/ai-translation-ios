// ai_translationApp.swift - 移除閱讀功能版本

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
            // 單字記憶庫 - 替換原本的閱讀功能
            VocabularyHomeView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("單字庫")
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
