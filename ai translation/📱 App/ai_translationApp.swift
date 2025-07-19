// ai_translationApp.swift - 移除閱讀功能版本

import SwiftUI

@main
struct ai_translationApp: App {
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var authManager = AuthenticationManager()

    var body: some Scene {
        WindowGroup {
            // 恢復正常的認證流程
            switch authManager.authState {
            case .authenticated, .guest:
                MainContentView()
                    .environmentObject(sessionManager)
                    .environmentObject(authManager)
            case .unauthenticated:
                AuthenticationContainerView()
                    .environmentObject(authManager)
            }
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
                    Image(systemName: "book.closed.fill")
                    Text("單字庫")
                        .font(.appCaption())
                }
            
            // 學習區域 - 完全獨立
            LearningAreaView()
                .tabItem {
                    Image(systemName: "graduationcap.fill")
                    Text("學習")
                        .font(.appCaption())
                }
        }
        .accentColor(.modernAccent)
        .environmentObject(sessionManager)
    }
}

#Preview {
    MainContentView()
        .environmentObject(SessionManager())
        .environmentObject(AuthenticationManager())
}
