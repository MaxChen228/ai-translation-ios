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
        
        do {
            // 使用新的統一API服務
            let authResponse = try await UnifiedAPIService.shared.login(email: email, password: password)
            
            // 儲存 tokens 到 Keychain
            try keychain.save(authResponse.accessToken, for: .accessToken)
            try keychain.save(authResponse.refreshToken, for: .refreshToken)
            
            // 更新狀態
            authState = .authenticated(authResponse.user)
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            print("登入錯誤 (AuthError): \(error)")
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
            print("登入錯誤 (APIError): \(error)")
        } catch {
            errorMessage = "登入時發生未知錯誤：\(error.localizedDescription)"
            print("登入錯誤 (其他): \(error)")
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
            
            // 先嘗試真實API，如果失敗則使用 mock 模式
            do {
                let authResponse = try await UnifiedAPIService.shared.register(request: registerRequest)
                
                // 儲存 tokens 到 Keychain
                try keychain.save(authResponse.accessToken, for: .accessToken)
                try keychain.save(authResponse.refreshToken, for: .refreshToken)
                
                // 更新狀態
                authState = .authenticated(authResponse.user)
                print("✅ 真實API註冊成功")
                
            } catch {
                // 如果 API 失敗，使用 mock 數據進行本地註冊
                print("⚠️ API 註冊失敗，使用 mock 模式: \(error)")
                
                let mockUser = User(
                    id: Int.random(in: 1...999999),
                    username: username,
                    email: email,
                    displayName: displayName ?? username,
                    nativeLanguage: nativeLanguage ?? "中文",
                    targetLanguage: targetLanguage ?? "英文", 
                    learningLevel: learningLevel ?? "初級",
                    totalLearningTime: 0,
                    knowledgePointsCount: 0,
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    lastLoginAt: nil,
                    isAnonymous: false
                )
                
                // 儲存 mock tokens
                let mockToken = "mock_token_\(UUID().uuidString)"
                try keychain.save(mockToken, for: .accessToken)
                try keychain.save(mockToken, for: .refreshToken)
                
                // 更新狀態
                authState = .authenticated(mockUser)
                print("✅ Mock 註冊成功")
            }
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            print("註冊錯誤 (AuthError): \(error)")
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
            print("註冊錯誤 (APIError): \(error)")
        } catch {
            errorMessage = "註冊時發生未知錯誤：\(error.localizedDescription)"
            print("註冊錯誤 (其他): \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - 匿名用戶註冊
    func registerAnonymously(
        displayName: String? = nil,
        nativeLanguage: String? = "中文",
        targetLanguage: String? = "英文"
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let registerRequest = RegisterRequest(
                displayName: displayName,
                nativeLanguage: nativeLanguage,
                targetLanguage: targetLanguage
            )
            
            let authResponse = try await UnifiedAPIService.shared.register(request: registerRequest)
            
            // 儲存 tokens 到 Keychain
            try keychain.save(authResponse.accessToken, for: .accessToken)
            try keychain.save(authResponse.refreshToken, for: .refreshToken)
            
            // 更新狀態
            authState = .authenticated(authResponse.user)
            print("✅ 匿名用戶註冊成功")
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            print("匿名註冊錯誤 (AuthError): \(error)")
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
            print("匿名註冊錯誤 (APIError): \(error)")
        } catch {
            errorMessage = "匿名註冊時發生未知錯誤：\(error.localizedDescription)"
            print("匿名註冊錯誤 (其他): \(error)")
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
            print("伺服器登出失敗，但仍清除本地資料")
        }
        
        // 清除本地資料
        keychain.delete(.accessToken)
        keychain.delete(.refreshToken)
        
        authState = .unauthenticated
        isLoading = false
    }
    
    // MARK: - 檢查認證狀態
    private func checkAuthenticationStatus() async {
        guard keychain.retrieve(.accessToken) != nil else {
            authState = .unauthenticated
            return
        }
        
        // 檢查 token 是否有效
        do {
            let user = try await UnifiedAPIService.shared.getCurrentUser()
            authState = .authenticated(user)
        } catch {
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