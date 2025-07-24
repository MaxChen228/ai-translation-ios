// AuthenticationManager.swift

import Foundation
import SwiftUI

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var authState: UserAuthState = .unauthenticated
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let keychain = KeychainManager()
    
    // 便利屬性
    var isAuthenticated: Bool { authState.isAuthenticated }
    var currentUser: User? { authState.currentUser }
    
    init() {
        // 初始化時檢查是否已有有效的 token
        Task {
            await checkAuthenticationStatus()
        }
    }
    
    // MARK: - 登入
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        Logger.info("開始登入，email: \(email)", category: .authentication)
        
        do {
            // 使用新的統一API服務
            let authResponse = try await UnifiedAPIService.shared.login(email: email, password: password)
            
            // 儲存 tokens 到 Keychain
            try keychain.save(authResponse.accessToken, for: .accessToken)
            try keychain.save(authResponse.refreshToken, for: .refreshToken)
            
            Logger.success("登入成功，用戶ID: \(authResponse.user.id)，用戶名: \(authResponse.user.username)", category: .authentication)
            Logger.info("Token已儲存到Keychain", category: .authentication)
            
            // 更新狀態
            authState = .authenticated(authResponse.user)
            Logger.success("認證狀態已更新為: 已認證", category: .authentication)
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            Logger.error("登入錯誤 (AuthError): \(error)", category: .authentication)
        } catch let error as APIError {
            switch error {
            case .invalidURL:
                errorMessage = "API 網址錯誤"
            case .requestFailed(let underlyingError):
                errorMessage = "網路請求失敗：\(underlyingError.localizedDescription)"
            case .invalidResponse:
                errorMessage = "伺服器回應無效"
            case .serverError(let statusCode, let message):
                errorMessage = "伺服器錯誤 (\(statusCode))：\(message)"
            case .decodingError(let underlyingError):
                errorMessage = "數據解析錯誤：\(underlyingError.localizedDescription)"
            case .unknownError:
                errorMessage = "未知的API錯誤"
            }
            Logger.error("登入錯誤 (APIError): \(error)", category: .authentication)
        } catch {
            errorMessage = "登入時發生未知錯誤：\(error.localizedDescription)"
            Logger.error("登入錯誤 (其他): \(error)", category: .authentication)
        }
        
        isLoading = false
    }
    
    // MARK: - 正式用戶註冊
    func register(
        username: String,
        email: String,
        password: String,
        displayName: String? = nil,
        nativeLanguage: String? = nil,
        targetLanguage: String? = nil,
        learningLevel: String? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let registerRequest = RegisterRequest(
                username: username,
                email: email,
                password: password,
                displayName: displayName,
                nativeLanguage: nativeLanguage,
                targetLanguage: targetLanguage,
                learningLevel: learningLevel
            )
            
            // 調用API進行註冊
            do {
                let authResponse = try await UnifiedAPIService.shared.register(request: registerRequest)
                
                // 儲存 tokens 到 Keychain
                try keychain.save(authResponse.accessToken, for: .accessToken)
                try keychain.save(authResponse.refreshToken, for: .refreshToken)
                
                // 更新狀態
                authState = .authenticated(authResponse.user)
                Logger.success("真實API註冊成功", category: .authentication)
                
            } catch {
                // 如果 API 失敗，拋出錯誤而不是使用假數據
                Logger.error("API 註冊失敗: \(error)", category: .authentication)
                throw AuthError.registrationFailed("註冊服務暫時無法使用，請稍後再試")
            }
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            Logger.error("註冊錯誤 (AuthError): \(error)", category: .authentication)
        } catch let error as APIError {
            switch error {
            case .invalidURL:
                errorMessage = "API 網址錯誤"
            case .requestFailed(let underlyingError):
                errorMessage = "網路請求失敗：\(underlyingError.localizedDescription)"
            case .invalidResponse:
                errorMessage = "伺服器回應無效"
            case .serverError(let statusCode, let message):
                errorMessage = "伺服器錯誤 (\(statusCode))：\(message)"
            case .decodingError(let underlyingError):
                errorMessage = "數據解析錯誤：\(underlyingError.localizedDescription)"
            case .unknownError:
                errorMessage = "未知的API錯誤"
            }
            Logger.error("註冊錯誤 (APIError): \(error)", category: .authentication)
        } catch {
            errorMessage = "註冊時發生未知錯誤：\(error.localizedDescription)"
            Logger.error("註冊錯誤 (其他): \(error)", category: .authentication)
        }
        
        isLoading = false
    }
    
    
    // MARK: - 登出
    func logout() async {
        isLoading = true
        
        do {
            // 通知伺服器登出
            try await UnifiedAPIService.shared.logout()
        } catch {
            // 即使伺服器登出失敗，也要清除本地資料
            Logger.warning("伺服器登出失敗，但仍清除本地資料", category: .authentication)
        }
        
        // 清除本地資料
        keychain.delete(.accessToken)
        keychain.delete(.refreshToken)
        
        // 清除知識點快取
        KnowledgePointRepository.shared.clearCache()
        
        authState = .unauthenticated
        isLoading = false
    }
    
    // MARK: - 檢查認證狀態
    private func checkAuthenticationStatus() async {
        Logger.info("檢查認證狀態...", category: .authentication)
        
        guard keychain.retrieve(.accessToken) != nil else {
            Logger.warning("未找到access token，設定為未認證", category: .authentication)
            authState = .unauthenticated
            return
        }
        
        Logger.info("找到access token，驗證中...", category: .authentication)
        
        // 檢查 token 是否有效
        do {
            let user = try await UnifiedAPIService.shared.getCurrentUser()
            authState = .authenticated(user)
            Logger.success("Token有效，用戶ID: \(user.id)，用戶名: \(user.username)", category: .authentication)
        } catch {
            Logger.error("Token驗證失敗: \(error)，嘗試刷新...", category: .authentication)
            // Token 無效，嘗試刷新
            await refreshTokenIfNeeded()
        }
    }
    
    // MARK: - 刷新 Token
    func refreshTokenIfNeeded() async {
        guard let refreshToken = keychain.retrieve(.refreshToken) else {
            await logout()
            return
        }
        
        do {
            let authResponse = try await UnifiedAPIService.shared.refreshToken(refreshToken)
            
            // 更新 tokens
            try keychain.save(authResponse.accessToken, for: .accessToken)
            try keychain.save(authResponse.refreshToken, for: .refreshToken)
            
            authState = .authenticated(authResponse.user)
            
        } catch {
            // 刷新失敗，登出使用者
            await logout()
        }
    }
    
    // MARK: - 取得 Access Token
    func getAccessToken() -> String? {
        return keychain.retrieve(.accessToken)
    }
    
    
    // MARK: - Google 登入
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        Logger.info("開始 Google 登入流程", category: .authentication)
        
        // 執行詳細的診斷
        GoogleSignInTestHelper.shared.performDiagnostics()
        
        do {
            // 檢查是否已配置 Google Sign-In
            guard GoogleSignInConfig.isConfigured else {
                Logger.error("Google Sign-In 配置檢查失敗", category: .authentication)
                errorMessage = "Google 登入尚未配置，請先設定 Client ID"
                isLoading = false
                return
            }
            
            Logger.success("Google Sign-In 配置檢查通過", category: .authentication)
            
            // 使用 GoogleSignInHelper 進行登入
            Logger.info("呼叫 GoogleSignInHelper.signIn()", category: .authentication)
            let idToken = try await GoogleSignInHelper.shared.signIn()
            
            Logger.success("獲得 Google ID Token", category: .authentication)
            
            // 將 ID Token 傳送到後端進行驗證
            Logger.info("傳送 Google ID Token 到後端驗證...", category: .authentication)
            let authResponse = try await UnifiedAPIService.shared.loginWithGoogle(idToken: idToken)
            
            // 儲存 tokens 到 Keychain
            try keychain.save(authResponse.accessToken, for: .accessToken)
            try keychain.save(authResponse.refreshToken, for: .refreshToken)
            
            Logger.success("Google 登入成功，用戶ID: \(authResponse.user.id)，用戶名: \(authResponse.user.username)", category: .authentication)
            
            // 更新狀態
            authState = .authenticated(authResponse.user)
            
        } catch let error as GoogleSignInError {
            switch error {
            case .userCancelled:
                errorMessage = "使用者取消了 Google 登入"
            case .missingViewController:
                errorMessage = "無法取得視窗控制器"
            case .configurationError:
                errorMessage = "Google Sign-In 配置錯誤"
            case .networkError:
                errorMessage = "網路連線錯誤"
            case .unknownError(let message):
                errorMessage = "Google 登入錯誤：\(message)"
            }
            Logger.error("Google 登入錯誤: \(error)", category: .authentication)
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            Logger.error("Google API 錯誤: \(error)", category: .authentication)
        } catch {
            errorMessage = "Google 登入時發生未知錯誤"
            Logger.error("Google 未知錯誤: \(error)", category: .authentication)
        }
        
        isLoading = false
    }
    
    // MARK: - Apple 登入
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        Logger.info("開始 Apple 登入流程", category: .authentication)
        
        do {
            // 使用 AppleSignInHelper 進行登入
            Logger.info("呼叫 AppleSignInHelper.signIn()", category: .authentication)
            let identityToken = try await AppleSignInHelper.shared.signIn()
            
            Logger.success("獲得 Apple Identity Token", category: .authentication)
            
            // 將 Identity Token 傳送到後端進行驗證
            Logger.info("傳送 Apple Identity Token 到後端驗證...", category: .authentication)
            let authResponse = try await UnifiedAPIService.shared.loginWithApple(identityToken: identityToken)
            
            // 儲存 tokens 到 Keychain
            try keychain.save(authResponse.accessToken, for: .accessToken)
            try keychain.save(authResponse.refreshToken, for: .refreshToken)
            
            Logger.success("Apple 登入成功，用戶ID: \(authResponse.user.id)，用戶名: \(authResponse.user.username)", category: .authentication)
            
            // 更新狀態
            authState = .authenticated(authResponse.user)
            
        } catch let error as AppleSignInError {
            switch error {
            case .userCancelled:
                errorMessage = "使用者取消了 Apple 登入"
            case .missingViewController:
                errorMessage = "無法取得視窗控制器"
            case .configurationError:
                errorMessage = "Apple Sign-In 配置錯誤"
            case .networkError:
                errorMessage = "網路連線錯誤"
            case .missingCredentials:
                errorMessage = "無法獲取 Apple ID 憑證"
            case .unknownError(let message):
                errorMessage = "Apple 登入錯誤：\(message)"
            }
            Logger.error("Apple 登入錯誤: \(error)", category: .authentication)
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            Logger.error("Apple API 錯誤: \(error)", category: .authentication)
        } catch {
            errorMessage = "Apple 登入時發生未知錯誤"
            Logger.error("Apple 未知錯誤: \(error)", category: .authentication)
        }
        
        isLoading = false
    }
    
    // MARK: - 清除錯誤訊息
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Keychain 管理器
class KeychainManager {
    enum KeychainKey: String {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
    
    func save(_ value: String, for key: KeychainKey) throws {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data
        ]
        
        // 先刪除舊的
        SecItemDelete(query as CFDictionary)
        
        // 新增新的
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw AuthError.unknown
        }
    }
    
    func retrieve(_ key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }
        
        return nil
    }
    
    func delete(_ key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}