// AppDelegate+GoogleSignIn.swift - Google Sign-In 應用程式配置

import Foundation
import SwiftUI
import GoogleSignIn

/// Google Sign-In URL 處理
extension Scene {
    func handleGoogleSignInURL(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

/// Google Sign-In 配置助手
struct GoogleSignInConfigurator {
    static func configure() {
        Logger.info("[GoogleSignInConfigurator] 開始載入 Google Sign-In 配置...", category: .authentication)
        
        // 檢查 bundle 中的所有 .plist 檔案
        let bundlePath = Bundle.main.bundlePath
        Logger.debug("[GoogleSignInConfigurator] Bundle 路徑: \(bundlePath)", category: .authentication)
        
        // 列出 bundle 中的檔案
        if let bundleContents = try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath) {
            let plistFiles = bundleContents.filter { $0.hasSuffix(".plist") }
            Logger.debug("[GoogleSignInConfigurator] Bundle 中的 .plist 檔案: \(plistFiles)", category: .authentication)
        }
        
        // 檢查配置檔案是否存在
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            Logger.error("[GoogleSignInConfigurator] 找不到 GoogleService-Info.plist 檔案", category: .authentication)
            Logger.error("   請確認檔案已正確加入到 Xcode 專案的 Target 中", category: .authentication)
            
            // 嘗試使用硬編碼的 Client ID 作為備用方案
            let fallbackClientId = GoogleSignInConfig.clientID
            if GoogleSignInConfig.isConfigured {
                Logger.warning("[GoogleSignInConfigurator] 使用硬編碼的 Client ID 作為備用方案", category: .authentication)
                let config = GIDConfiguration(clientID: fallbackClientId)
                GIDSignIn.sharedInstance.configuration = config
                Logger.success("[GoogleSignInConfigurator] Google Sign-In SDK 已使用備用配置完成", category: .authentication)
            } else {
                Logger.error("[GoogleSignInConfigurator] 備用配置也無效", category: .authentication)
            }
            return
        }
        
        Logger.info("[GoogleSignInConfigurator] 找到 GoogleService-Info.plist: \(path)", category: .authentication)
        
        guard let plist = NSDictionary(contentsOfFile: path) else {
            Logger.error("[GoogleSignInConfigurator] 無法讀取 GoogleService-Info.plist 內容", category: .authentication)
            return
        }
        
        Logger.debug("[GoogleSignInConfigurator] .plist 內容: \(plist)", category: .authentication)
        
        guard let clientId = plist["CLIENT_ID"] as? String else {
            Logger.error("[GoogleSignInConfigurator] .plist 中找不到 CLIENT_ID", category: .authentication)
            return
        }
        
        Logger.success("[GoogleSignInConfigurator] Google Sign-In 配置已載入", category: .authentication)
        Logger.info("   Client ID: \(clientId)", category: .authentication)
        Logger.info("   Bundle ID: \(Bundle.main.bundleIdentifier ?? "未知")", category: .authentication)
        
        // 檢查 Bundle ID 是否匹配
        if let bundleId = plist["BUNDLE_ID"] as? String {
            let currentBundleId = Bundle.main.bundleIdentifier ?? ""
            if bundleId != currentBundleId {
                Logger.warning("[GoogleSignInConfigurator] Bundle ID 不匹配!", category: .authentication)
                Logger.warning("   GoogleService-Info.plist: \(bundleId)", category: .authentication)
                Logger.warning("   當前專案: \(currentBundleId)", category: .authentication)
            } else {
                Logger.success("[GoogleSignInConfigurator] Bundle ID 匹配", category: .authentication)
            }
        }
        
        // 配置 Google Sign-In
        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config
        Logger.success("[GoogleSignInConfigurator] Google Sign-In SDK 已配置完成", category: .authentication)
        
        // 額外驗證配置是否成功
        if GIDSignIn.sharedInstance.configuration?.clientID == clientId {
            Logger.success("[GoogleSignInConfigurator] SDK 配置驗證成功", category: .authentication)
            Logger.debug("[GoogleSignInConfigurator] 配置詳情:", category: .authentication)
            Logger.debug("   客戶端ID: \(GIDSignIn.sharedInstance.configuration?.clientID ?? "無")", category: .authentication)
            Logger.debug("   Server客戶端ID: \(GIDSignIn.sharedInstance.configuration?.serverClientID ?? "無")", category: .authentication)
            Logger.debug("   Hosted Domain: \(GIDSignIn.sharedInstance.configuration?.hostedDomain ?? "無")", category: .authentication)
        } else {
            Logger.error("[GoogleSignInConfigurator] SDK 配置驗證失敗", category: .authentication)
            Logger.error("   預期的客戶端ID: \(clientId)", category: .authentication)
            Logger.error("   實際的客戶端ID: \(GIDSignIn.sharedInstance.configuration?.clientID ?? "無")", category: .authentication)
        }
    }
}