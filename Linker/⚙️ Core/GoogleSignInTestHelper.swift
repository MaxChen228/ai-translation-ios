// GoogleSignInTestHelper.swift - Google Sign-In 測試協助工具

import Foundation
import SwiftUI
import GoogleSignIn

/// Google Sign-In 測試輔助工具
/// 用於診斷和修復配置問題
class GoogleSignInTestHelper: ObservableObject {
    static let shared = GoogleSignInTestHelper()
    
    private init() {}
    
    /// 執行 Google Sign-In 診斷
    func performDiagnostics() {
        Logger.info("開始 Google Sign-In 診斷...", category: .authentication)
        
        // 1. 檢查 SDK 配置
        if let config = GIDSignIn.sharedInstance.configuration {
            Logger.success("SDK 已配置，客戶端ID: \(config.clientID)", category: .authentication)
            if let serverClientID = config.serverClientID {
                Logger.info("伺服器客戶端ID: \(serverClientID)", category: .authentication)
            }
            if let hostedDomain = config.hostedDomain {
                Logger.info("Hosted Domain: \(hostedDomain)", category: .authentication)
            }
        } else {
            Logger.error("SDK 未配置", category: .authentication)
            return
        }
        
        // 2. 檢查 Bundle ID
        let currentBundleID = Bundle.main.bundleIdentifier ?? ""
        Logger.info("應用程式 Bundle ID: \(currentBundleID)", category: .authentication)
        
        // 3. 檢查 URL Schemes
        if let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] {
            Logger.info("URL Schemes: \(urlTypes.compactMap { $0["CFBundleURLSchemes"] as? [String] }.flatMap { $0 }.joined(separator: ", "))", category: .authentication)
        }
        
        // 4. 檢查是否有之前的登入
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            Logger.info("發現之前的登入狀態", category: .authentication)
            if let currentUser = GIDSignIn.sharedInstance.currentUser {
                Logger.info("使用者ID: \(currentUser.userID ?? "無"), 電子郵件: \(currentUser.profile?.email ?? "無")", category: .authentication)
            }
        } else {
            Logger.info("無之前的登入狀態", category: .authentication)
        }
        
        Logger.success("Google Sign-In 診斷完成", category: .authentication)
    }
    
    /// 清除所有 Google Sign-In 狀態
    func clearAllSignInState() {
        Logger.info("清除所有 Google Sign-In 狀態...", category: .authentication)
        GIDSignIn.sharedInstance.signOut()
        
        // 清除 Keychain 中的認證資訊
        if let bundleID = Bundle.main.bundleIdentifier {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: bundleID
            ]
            SecItemDelete(query as CFDictionary)
        }
        
        Logger.success("狀態已清除", category: .authentication)
    }
    
    /// 測試基本的 Google Sign-In 流程（不包含 UI）
    func testBasicConfiguration() async {
        Logger.info("測試基本配置...", category: .authentication)
        
        // 確保配置存在
        guard GIDSignIn.sharedInstance.configuration != nil else {
            Logger.error("配置不存在", category: .authentication)
            return
        }
        
        Logger.success("基本配置測試通過", category: .authentication)
    }
}