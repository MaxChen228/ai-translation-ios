// AppleSignInHelper.swift - Apple Sign-In 協調器

import Foundation
import SwiftUI
import AuthenticationServices

/// Apple Sign-In 錯誤類型
enum AppleSignInError: LocalizedError {
    case userCancelled
    case missingViewController
    case configurationError
    case networkError
    case missingCredentials
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "使用者取消了登入"
        case .missingViewController:
            return "無法取得視窗控制器"
        case .configurationError:
            return "Apple Sign-In 配置錯誤"
        case .networkError:
            return "網路連線錯誤"
        case .missingCredentials:
            return "無法獲取 Apple ID 憑證"
        case .unknownError(let message):
            return message
        }
    }
}

/// Apple Sign-In 協調器
/// 負責處理 Apple Sign-In AuthenticationServices 的整合
@MainActor
class AppleSignInHelper: NSObject, ObservableObject {
    static let shared = AppleSignInHelper()
    
    private var continuation: CheckedContinuation<String, Error>?
    
    private override init() {
        super.init()
    }
    
    /// 執行 Apple 登入
    /// 返回 Identity Token 用於後端驗證
    func signIn() async throws -> String {
        Logger.info("開始執行 Apple Sign-In...", category: .authentication)
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authController = ASAuthorizationController(authorizationRequests: [request])
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
        }
    }
    
    /// 檢查 Apple ID 憑證狀態
    func checkCredentialState(for userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userID) { state, error in
                if let error = error {
                    Logger.error("檢查憑證狀態錯誤: \(error.localizedDescription)", category: .authentication)
                }
                continuation.resume(returning: state)
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInHelper: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Logger.success("Apple Sign-In 授權成功", category: .authentication)
        
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            Logger.error("無法獲取 Apple ID 憑證", category: .authentication)
            continuation?.resume(throwing: AppleSignInError.missingCredentials)
            return
        }
        
        guard let identityToken = credential.identityToken,
              let identityTokenString = String(data: identityToken, encoding: .utf8) else {
            Logger.error("無法獲取 Identity Token", category: .authentication)
            continuation?.resume(throwing: AppleSignInError.missingCredentials)
            return
        }
        
        Logger.success("成功獲取 Apple Identity Token", category: .authentication)
        Logger.info("User ID: \(credential.user)", category: .authentication)
        
        // 記錄用戶信息（僅在首次登入時提供）
        if let fullName = credential.fullName {
            Logger.info("Full Name: \(fullName)", category: .authentication)
        }
        if let email = credential.email {
            Logger.info("Email: \(email)", category: .authentication)
        }
        
        continuation?.resume(returning: identityTokenString)
        continuation = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Logger.error("Apple Sign-In 失敗: \(error.localizedDescription)", category: .authentication)
        
        let appleSignInError: AppleSignInError
        
        if let authError = error as? ASAuthorizationError {
            let errorCode = authError.code
            switch errorCode {
            case .canceled:
                Logger.info("使用者取消 Apple Sign-In", category: .authentication)
                appleSignInError = .userCancelled
            case .failed:
                Logger.error("授權失敗: \(authError.localizedDescription)", category: .authentication)
                appleSignInError = .unknownError("授權失敗: \(authError.localizedDescription)")
            case .invalidResponse:
                Logger.error("無效回應: \(authError.localizedDescription)", category: .authentication)
                appleSignInError = .unknownError("無效回應: \(authError.localizedDescription)")
            case .notHandled:
                Logger.error("未處理: \(authError.localizedDescription)", category: .authentication)
                appleSignInError = .unknownError("未處理: \(authError.localizedDescription)")
            case .unknown:
                Logger.error("未知錯誤: \(authError.localizedDescription)", category: .authentication)
                appleSignInError = .unknownError("未知錯誤: \(authError.localizedDescription)")
            case .notInteractive:
                Logger.error("非互動式錯誤: \(authError.localizedDescription)", category: .authentication)
                appleSignInError = .unknownError("非互動式錯誤: \(authError.localizedDescription)")
            case .matchedExcludedCredential:
                Logger.error("匹配到排除的憑證: \(authError.localizedDescription)", category: .authentication)
                appleSignInError = .unknownError("匹配到排除的憑證: \(authError.localizedDescription)")
            case .credentialImport:
                Logger.error("憑證導入錯誤: \(authError.localizedDescription)", category: .authentication)
                appleSignInError = .unknownError("憑證導入錯誤: \(authError.localizedDescription)")
            case .credentialExport:
                Logger.error("憑證導出錯誤: \(authError.localizedDescription)", category: .authentication)
                appleSignInError = .unknownError("憑證導出錯誤: \(authError.localizedDescription)")
            @unknown default:
                Logger.error("其他錯誤: \(errorCode.rawValue) - \(authError.localizedDescription)", category: .authentication)
                appleSignInError = .unknownError(authError.localizedDescription)
            }
        } else {
            appleSignInError = .unknownError(error.localizedDescription)
        }
        
        continuation?.resume(throwing: appleSignInError)
        continuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInHelper: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("無法獲取主視窗")
        }
        return window
    }
}

/// Apple Sign-In 按鈕視圖
struct AppleSignInButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Apple Logo
                Image(systemName: "applelogo")
                    .font(.title2)
                    .foregroundColor(.primary)
                
                Text("使用 Apple 登入")
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