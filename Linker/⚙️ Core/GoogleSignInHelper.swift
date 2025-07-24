// GoogleSignInHelper.swift - Google Sign-In 協調器

import Foundation
import SwiftUI
import GoogleSignIn

/// Google Sign-In 錯誤類型
enum GoogleSignInError: LocalizedError {
    case userCancelled
    case missingViewController
    case configurationError
    case networkError
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "使用者取消了登入"
        case .missingViewController:
            return "無法取得視窗控制器"
        case .configurationError:
            return "Google Sign-In 配置錯誤"
        case .networkError:
            return "網路連線錯誤"
        case .unknownError(let message):
            return message
        }
    }
}

/// Google Sign-In 協調器
/// 負責處理 Google Sign-In SDK 的整合
@MainActor
class GoogleSignInHelper: ObservableObject {
    static let shared = GoogleSignInHelper()
    
    private init() {}
    
    /// 執行 Google 登入
    /// 返回 ID Token 用於後端驗證
    func signIn() async throws -> String {
        // 確保 SDK 已經配置
        if GIDSignIn.sharedInstance.configuration == nil {
            Logger.error("Google Sign-In SDK 配置為 nil，嘗試重新配置...", category: .authentication)
            GoogleSignInConfigurator.configure()
            
            guard GIDSignIn.sharedInstance.configuration != nil else {
                Logger.error("重新配置後 SDK 仍然為 nil", category: .authentication)
                throw GoogleSignInError.configurationError
            }
        }
        
        Logger.success("Google Sign-In SDK 配置已確認", category: .authentication)
        
        // 檢查是否有之前的登入狀態
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            Logger.info("發現之前的登入狀態，嘗試恢復...", category: .authentication)
            do {
                try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                if let user = GIDSignIn.sharedInstance.currentUser,
                   let idToken = user.idToken?.tokenString {
                    Logger.success("成功恢復之前的登入狀態", category: .authentication)
                    return idToken
                }
            } catch {
                Logger.warning("恢復之前登入失敗: \(error.localizedDescription)", category: .authentication)
                // 繼續進行新的登入流程
            }
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            Logger.error("無法獲取根視圖控制器", category: .authentication)
            throw GoogleSignInError.missingViewController
        }
        
        do {
            Logger.info("開始執行 Google Sign-In...", category: .authentication)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw GoogleSignInError.unknownError("無法獲取 ID Token")
            }
            
            Logger.success("Google Sign-In 成功，獲得 ID Token", category: .authentication)
            return idToken
            
        } catch {
            Logger.error("Google Sign-In 失敗", category: .authentication)
            
            if let gidError = error as? GIDSignInError {
                Logger.error("GIDSignInError 詳細資訊: 代碼=\(gidError.code.rawValue), 描述=\(gidError.localizedDescription)", category: .authentication)
                
                switch gidError.code {
                case .canceled:
                    Logger.info("使用者取消 Google Sign-In", category: .authentication)
                    throw GoogleSignInError.userCancelled
                case .hasNoAuthInKeychain:
                    Logger.info("無認證資訊（首次登入是正常的）", category: .authentication)
                    throw GoogleSignInError.unknownError("首次登入或需要重新認證: \(gidError.localizedDescription)")
                case .keychain:
                    Logger.error("Keychain 錯誤: \(gidError.localizedDescription)", category: .authentication)
                    throw GoogleSignInError.unknownError("Keychain 錯誤: \(gidError.localizedDescription)")
                case .unknown:
                    Logger.error("未知錯誤: \(gidError.localizedDescription)", category: .authentication)
                    throw GoogleSignInError.unknownError("未知錯誤: \(gidError.localizedDescription)")
                default:
                    Logger.error("其他錯誤: \(gidError.code) - \(gidError.localizedDescription)", category: .authentication)
                    throw GoogleSignInError.unknownError(gidError.localizedDescription)
                }
            } else {
                Logger.error("非 GIDSignInError: 類型=\(type(of: error)), 描述=\(error.localizedDescription)", category: .authentication)
                throw GoogleSignInError.unknownError(error.localizedDescription)
            }
        }
    }
    
    /// 登出 Google 帳號
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
    
    /// 恢復之前的登入狀態
    func restorePreviousSignIn() async throws {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            try await GIDSignIn.sharedInstance.restorePreviousSignIn()
        }
    }
}

/// Google Sign-In 按鈕視圖
struct GoogleSignInButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Google Logo
                Image(systemName: "g.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("使用 Google 登入")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                           pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}