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
        print("🔍 [GoogleSignInConfigurator] 開始載入 Google Sign-In 配置...")
        
        // 檢查 bundle 中的所有 .plist 檔案
        let bundlePath = Bundle.main.bundlePath
        print("📁 [GoogleSignInConfigurator] Bundle 路徑: \(bundlePath)")
        
        // 列出 bundle 中的檔案
        if let bundleContents = try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath) {
            let plistFiles = bundleContents.filter { $0.hasSuffix(".plist") }
            print("📋 [GoogleSignInConfigurator] Bundle 中的 .plist 檔案: \(plistFiles)")
        }
        
        // 檢查配置檔案是否存在
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            print("❌ [GoogleSignInConfigurator] 找不到 GoogleService-Info.plist 檔案")
            print("   請確認檔案已正確加入到 Xcode 專案的 Target 中")
            
            // 嘗試使用硬編碼的 Client ID 作為備用方案
            let fallbackClientId = GoogleSignInConfig.clientID
            if GoogleSignInConfig.isConfigured {
                print("🔄 [GoogleSignInConfigurator] 使用硬編碼的 Client ID 作為備用方案")
                let config = GIDConfiguration(clientID: fallbackClientId)
                GIDSignIn.sharedInstance.configuration = config
                print("✅ [GoogleSignInConfigurator] Google Sign-In SDK 已使用備用配置完成")
            } else {
                print("❌ [GoogleSignInConfigurator] 備用配置也無效")
            }
            return
        }
        
        print("✅ [GoogleSignInConfigurator] 找到 GoogleService-Info.plist: \(path)")
        
        guard let plist = NSDictionary(contentsOfFile: path) else {
            print("❌ [GoogleSignInConfigurator] 無法讀取 GoogleService-Info.plist 內容")
            return
        }
        
        print("📄 [GoogleSignInConfigurator] .plist 內容: \(plist)")
        
        guard let clientId = plist["CLIENT_ID"] as? String else {
            print("❌ [GoogleSignInConfigurator] .plist 中找不到 CLIENT_ID")
            return
        }
        
        print("✅ [GoogleSignInConfigurator] Google Sign-In 配置已載入")
        print("   Client ID: \(clientId)")
        print("   Bundle ID: \(Bundle.main.bundleIdentifier ?? "未知")")
        
        // 檢查 Bundle ID 是否匹配
        if let bundleId = plist["BUNDLE_ID"] as? String {
            let currentBundleId = Bundle.main.bundleIdentifier ?? ""
            if bundleId != currentBundleId {
                print("⚠️ [GoogleSignInConfigurator] Bundle ID 不匹配!")
                print("   GoogleService-Info.plist: \(bundleId)")
                print("   當前專案: \(currentBundleId)")
            } else {
                print("✅ [GoogleSignInConfigurator] Bundle ID 匹配")
            }
        }
        
        // 配置 Google Sign-In
        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config
        print("✅ [GoogleSignInConfigurator] Google Sign-In SDK 已配置完成")
        
        // 額外驗證配置是否成功
        if GIDSignIn.sharedInstance.configuration?.clientID == clientId {
            print("🔥 [GoogleSignInConfigurator] SDK 配置驗證成功")
            print("🔍 [GoogleSignInConfigurator] 配置詳情:")
            print("   客戶端ID: \(GIDSignIn.sharedInstance.configuration?.clientID ?? "無")")
            print("   Server客戶端ID: \(GIDSignIn.sharedInstance.configuration?.serverClientID ?? "無")")
            print("   Hosted Domain: \(GIDSignIn.sharedInstance.configuration?.hostedDomain ?? "無")")
        } else {
            print("❌ [GoogleSignInConfigurator] SDK 配置驗證失敗")
            print("   預期的客戶端ID: \(clientId)")
            print("   實際的客戶端ID: \(GIDSignIn.sharedInstance.configuration?.clientID ?? "無")")
        }
    }
}