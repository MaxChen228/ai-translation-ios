// GoogleSignInConfig.swift - Google Sign-In 配置

import Foundation

/// Google Sign-In 配置
struct GoogleSignInConfig {
    /// Google OAuth Client ID
    /// 請將此值替換為您從 Google Cloud Console 獲得的實際 Client ID
    /// 範例格式：123456789012-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com
    static let clientID = "314710416095-s9394e27uapb0c1upfc36evl87knhdnt.apps.googleusercontent.com"
    
    /// 提示：獲取 Client ID 的步驟
    /// 1. 前往 https://console.cloud.google.com/
    /// 2. 選擇或創建專案
    /// 3. 前往 APIs & Services > Credentials
    /// 4. 創建 OAuth 2.0 Client ID (iOS 類型)
    /// 5. 下載 GoogleService-Info.plist
    
    /// 是否已配置 Google Sign-In
    static var isConfigured: Bool {
        return clientID != "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
    }
}