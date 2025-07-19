// AuthenticationManager.swift

import Foundation
import SwiftUI

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let keychain = KeychainManager()
    
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
            let authResponse = try await KnowledgePointAPIService.login(email: email, password: password)
            
            // 儲存 tokens 到 Keychain
            try keychain.save(authResponse.accessToken, for: .accessToken)
            try keychain.save(authResponse.refreshToken, for: .refreshToken)
            
            // 更新狀態
            currentUser = authResponse.user
            isAuthenticated = true
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "登入時發生未知錯誤"
        }
        
        isLoading = false
    }
    
    // MARK: - 註冊
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
            
            let authResponse = try await KnowledgePointAPIService.register(request: registerRequest)
            
            // 儲存 tokens 到 Keychain
            try keychain.save(authResponse.accessToken, for: .accessToken)
            try keychain.save(authResponse.refreshToken, for: .refreshToken)
            
            // 更新狀態
            currentUser = authResponse.user
            isAuthenticated = true
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "註冊時發生未知錯誤"
        }
        
        isLoading = false
    }
    
    // MARK: - 登出
    func logout() async {
        isLoading = true
        
        do {
            // 通知伺服器登出
            try await KnowledgePointAPIService.logout()
        } catch {
            // 即使伺服器登出失敗，也要清除本地資料
            print("伺服器登出失敗，但仍清除本地資料")
        }
        
        // 清除本地資料
        keychain.delete(.accessToken)
        keychain.delete(.refreshToken)
        
        currentUser = nil
        isAuthenticated = false
        isLoading = false
    }
    
    // MARK: - 檢查認證狀態
    private func checkAuthenticationStatus() async {
        guard let accessToken = keychain.retrieve(.accessToken) else {
            isAuthenticated = false
            return
        }
        
        // 檢查 token 是否有效
        do {
            let user = try await KnowledgePointAPIService.getCurrentUser()
            currentUser = user
            isAuthenticated = true
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
            let authResponse = try await KnowledgePointAPIService.refreshToken(refreshToken: refreshToken)
            
            // 更新 tokens
            try keychain.save(authResponse.accessToken, for: .accessToken)
            try keychain.save(authResponse.refreshToken, for: .refreshToken)
            
            currentUser = authResponse.user
            isAuthenticated = true
            
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