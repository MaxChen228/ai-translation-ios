// AuthenticationAPIService.swift - 認證相關 API 服務

import Foundation

struct AuthenticationAPIService {
    private static let baseURL = "\(APIConfig.apiBaseURL)/api"
    
    // MARK: - 認證相關 API
    
    /// 使用者登入
    static func login(email: String, password: String) async throws -> AuthResponse {
        let urlString = "\(baseURL)/auth/login"
        guard let url = URL(string: urlString) else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginRequest = LoginRequest(email: email, password: password)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(loginRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200:
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                return authResponse
            case 401:
                throw AuthError.invalidCredentials
            case 500...599:
                throw AuthError.serverError("伺服器內部錯誤")
            default:
                if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorBody["error"] ?? errorBody["message"] {
                    throw AuthError.serverError(message)
                }
                throw AuthError.unknown
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError
        }
    }
    
    /// 使用者註冊
    static func register(request: RegisterRequest) async throws -> AuthResponse {
        let urlString = "\(baseURL)/auth/register"
        guard let url = URL(string: urlString) else {
            throw AuthError.networkError
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            switch httpResponse.statusCode {
            case 201:
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                return authResponse
            case 409:
                throw AuthError.userAlreadyExists
            case 500...599:
                throw AuthError.serverError("伺服器內部錯誤")
            default:
                if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorBody["error"] ?? errorBody["message"] {
                    throw AuthError.serverError(message)
                }
                throw AuthError.unknown
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError
        }
    }
    
    /// 刷新 Access Token
    static func refreshToken(refreshToken: String) async throws -> AuthResponse {
        let urlString = "\(baseURL)/auth/refresh"
        guard let url = URL(string: urlString) else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(refreshRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200:
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                return authResponse
            case 401:
                throw AuthError.tokenExpired
            default:
                throw AuthError.unknown
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError
        }
    }
    
    /// 登出
    static func logout() async throws {
        let urlString = "\(baseURL)/auth/logout"
        guard let url = URL(string: urlString) else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 加入認證標頭（如果有的話）
        if let token = KeychainManager().retrieve(.accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.networkError
        }
    }
    
    /// 取得目前使用者資訊
    static func getCurrentUser() async throws -> User {
        let urlString = "\(baseURL)/auth/me"
        guard let url = URL(string: urlString) else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 加入認證標頭
        guard let token = KeychainManager().retrieve(.accessToken) else {
            throw AuthError.invalidToken
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200:
                let user = try JSONDecoder().decode(User.self, from: data)
                return user
            case 401:
                throw AuthError.tokenExpired
            default:
                throw AuthError.unknown
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError
        }
    }
}