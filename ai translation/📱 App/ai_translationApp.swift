// ai_translationApp.swift - 移除閱讀功能版本

import SwiftUI

@main
struct ai_translationApp: App {
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var authManager = AuthenticationManager()
    
    init() {
        configureGlobalFonts()
    }

    var body: some Scene {
        WindowGroup {
            ModernNavigationContainer {
                // 恢復正常的認證流程
                ZStack {
                    switch authManager.authState {
                    case .authenticated:
                        MainContentView()
                            .environmentObject(sessionManager)
                            .environmentObject(authManager)
                            .transition(TransitionEffects.gentleAppear)
                    case .unauthenticated:
                        AuthenticationContainerView()
                            .environmentObject(authManager)
                            .transition(TransitionEffects.gentleAppear)
                    }
                }
                .animation(AnimationCurves.gentleSpring, value: authManager.authState)
            }
        }
    }
    
    // MARK: - 全局字體配置
    private func configureGlobalFonts() {
        // 設置導航欄字體
        if let customFont = UIFont(name: "SourceHanSerifTCVF-Regular", size: 17) {
            UINavigationBar.appearance().titleTextAttributes = [
                NSAttributedString.Key.font: customFont,
                NSAttributedString.Key.foregroundColor: UIColor(Color.modernTextPrimary)
            ]
        }
        
        if let largeTitleFont = UIFont(name: "SourceHanSerifTCVF-Bold", size: 34) {
            UINavigationBar.appearance().largeTitleTextAttributes = [
                NSAttributedString.Key.font: largeTitleFont,
                NSAttributedString.Key.foregroundColor: UIColor(Color.modernTextPrimary)
            ]
        }
        
        // 設置標籤欄字體
        if let tabFont = UIFont(name: "SourceHanSerifTCVF-Regular", size: 10) {
            UITabBarItem.appearance().setTitleTextAttributes([
                NSAttributedString.Key.font: tabFont
            ], for: .normal)
            
            UITabBarItem.appearance().setTitleTextAttributes([
                NSAttributedString.Key.font: tabFont
            ], for: .selected)
        }
        
        // 設置導航欄按鈕字體
        if let navButtonFont = UIFont(name: "SourceHanSerifTCVF-Medium", size: 17) {
            UIBarButtonItem.appearance().setTitleTextAttributes([
                NSAttributedString.Key.font: navButtonFont
            ], for: .normal)
        }
        
        // 設置 Alert 和 ActionSheet 字體
        if let alertTitleFont = UIFont(name: "SourceHanSerifTCVF-Bold", size: 17) {
            UILabel.appearance(whenContainedInInstancesOf: [UIAlertController.self]).font = alertTitleFont
        }
        
        // 設置搜尋欄字體
        if let searchFont = UIFont(name: "SourceHanSerifTCVF-Regular", size: 16) {
            UISearchBar.appearance().searchTextField.font = searchFont
        }
        
        // 設置分段控制器字體
        if let segmentFont = UIFont(name: "SourceHanSerifTCVF-Regular", size: 13) {
            UISegmentedControl.appearance().setTitleTextAttributes([
                NSAttributedString.Key.font: segmentFont
            ], for: .normal)
        }
        
        // 設置表格視圖字體
        if let tableFont = UIFont(name: "SourceHanSerifTCVF-Regular", size: 17) {
            UILabel.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).font = tableFont
        }
    }
}

// MARK: - 主要內容視圖

struct MainContentView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        TabView {
            // 單字記憶庫 - 包含多分類系統
            VocabularyAreaView()
                .tabItem {
                    Image(systemName: "book.closed.fill")
                    Text("單字庫")
                        .font(.appCaption(for: "單字庫"))
                }
            
            // 學習區域 - 完全獨立
            LearningAreaView()
                .tabItem {
                    Image(systemName: "graduationcap.fill")
                    Text("學習")
                        .font(.appCaption(for: "學習"))
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
