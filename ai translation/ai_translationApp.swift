// ai_translationApp.swift

import SwiftUI

@main
struct ai_translationApp: App {
    // 建立一個 SessionManager，讓整個 App 共享
    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager) // 將 sessionManager 注入到環境中
        }
    }
}
