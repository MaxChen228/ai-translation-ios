// NetworkManager.swift - 統一的網路管理器，專門針對iOS模擬器優化

import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        
        // 檢測是否在iOS模擬器中運行
        let isSimulator = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
        
        // 基本配置
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        
        if isSimulator {
            print("🔧 NetworkManager: 檢測到iOS模擬器，應用模擬器專用網路配置")
            
            // 模擬器專用：完全禁用可能導致 SO_NOWAKEFROMSLEEP 錯誤的設定
            configuration.allowsCellularAccess = false
            configuration.waitsForConnectivity = false
            configuration.httpShouldUsePipelining = false
            configuration.httpShouldSetCookies = false
            configuration.httpCookieAcceptPolicy = .never
            configuration.httpMaximumConnectionsPerHost = 4
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            configuration.allowsConstrainedNetworkAccess = false
            configuration.allowsExpensiveNetworkAccess = false
            
            // 額外的模擬器優化：禁用背景任務和wake相關功能
            configuration.sessionSendsLaunchEvents = false
            configuration.isDiscretionary = false
        } else {
            print("📱 NetworkManager: 檢測到真實設備，應用標準網路配置")
            
            // 真實設備配置（保持原有功能）
            configuration.allowsCellularAccess = true
            configuration.waitsForConnectivity = true
            configuration.httpShouldUsePipelining = false
            configuration.httpShouldSetCookies = true
            configuration.httpCookieAcceptPolicy = .always
            configuration.httpMaximumConnectionsPerHost = 4
            configuration.requestCachePolicy = .useProtocolCachePolicy
        }
        
        // 設定URLSession
        self.session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }
    
    // MARK: - 公共API方法
    
    /// 執行GET請求
    func performGETRequest(url: URL, requireAuth: Bool = false) async throws -> (Data, URLResponse) {
        var request = createGETRequest(url: url)
        addAuthHeaderIfNeeded(to: &request, requireAuth: requireAuth)
        
        do {
            let result = try await session.data(for: request)
            print("✅ GET請求成功: \(url.absoluteString)")
            return result
        } catch {
            print("❌ GET請求失敗: \(url.absoluteString), 錯誤: \(error)")
            throw APIError.requestFailed(error)
        }
    }
    
    /// 執行POST請求
    func performPOSTRequest(url: URL, body: Data? = nil, requireAuth: Bool = false) async throws -> (Data, URLResponse) {
        var request = createPOSTRequest(url: url, body: body)
        addAuthHeaderIfNeeded(to: &request, requireAuth: requireAuth)
        
        do {
            let result = try await session.data(for: request)
            print("✅ POST請求成功: \(url.absoluteString)")
            return result
        } catch {
            print("❌ POST請求失敗: \(url.absoluteString), 錯誤: \(error)")
            throw APIError.requestFailed(error)
        }
    }
    
    /// 執行通用請求
    func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            let result = try await session.data(for: request)
            print("✅ 請求成功: \(request.url?.absoluteString ?? "未知URL")")
            return result
        } catch {
            print("❌ 請求失敗: \(request.url?.absoluteString ?? "未知URL"), 錯誤: \(error)")
            throw APIError.requestFailed(error)
        }
    }
    
    // MARK: - 私有輔助方法
    
    private func createGETRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30.0
        
        // 設定基本標頭，移除可能導致問題的設定
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        return request
    }
    
    private func createPOSTRequest(url: URL, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0
        
        // 設定基本標頭
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    private func addAuthHeaderIfNeeded(to request: inout URLRequest, requireAuth: Bool) {
        // 嘗試從Keychain獲取token作為備用方案
        if let token = KeychainManager().retrieve(.accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if requireAuth {
            // 如果需要認證但沒有token，使用訪客標識
            request.setValue("Guest", forHTTPHeaderField: "X-User-Type")
        }
    }
    
    // 新增非同步認證頭方法，供NetworkServiceProtocol使用
    func addAuthHeaderAsync(to request: inout URLRequest, requireAuth: Bool) async throws {
        if requireAuth {
            let authManager = await AuthenticationManager.shared
            if let token = await authManager.getAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                // 如果需要認證但沒有token，使用訪客標識
                request.setValue("Guest", forHTTPHeaderField: "X-User-Type")
            }
        }
    }
}

// MARK: - 回應處理輔助方法

extension NetworkManager {
    
    /// 處理HTTP回應並檢查狀態碼
    func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📊 HTTP狀態碼: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // 嘗試解析錯誤訊息
            if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorBody["error"] ?? errorBody["message"] {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "未知伺服器錯誤")
        }
    }
    
    /// 安全解碼JSON回應
    func safeDecodeJSON<T: Codable>(_ data: Data, as type: T.Type) throws -> T {
        do {
            let decoder = JSONDecoder()
            // 設定日期解碼策略
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            print("❌ JSON解析錯誤: \(error)")
            throw APIError.decodingError(error)
        }
    }
}