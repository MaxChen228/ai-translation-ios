// NetworkManager.swift - 統一的網路管理器，專門針對iOS模擬器優化

import Foundation

// 添加協議定義以避免循環依賴
protocol NetworkManagerProtocol {
    func performRequest<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T
}

class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager()
    
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        
        // 檢測是否在iOS模擬器中運行
        let isSimulator = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
        
        // 基本配置 - 針對 AI 生成題目增加超時時間
        configuration.timeoutIntervalForRequest = 60.0  // 單個請求超時：60秒
        configuration.timeoutIntervalForResource = 120.0 // 整體資源超時：2分鐘
        
        // 完全禁用快取
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        Logger.info("已完全禁用HTTP快取", category: .network)
        
        if isSimulator {
            Logger.info("檢測到iOS模擬器，應用模擬器專用網路配置", category: .network)
            
            // 模擬器專用：完全禁用可能導致 SO_NOWAKEFROMSLEEP 錯誤的設定
            configuration.allowsCellularAccess = false
            configuration.waitsForConnectivity = false
            configuration.httpShouldUsePipelining = false
            configuration.httpShouldSetCookies = false
            configuration.httpCookieAcceptPolicy = .never
            configuration.httpMaximumConnectionsPerHost = 4
            // 模擬器也禁用快取
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            configuration.allowsConstrainedNetworkAccess = false
            configuration.allowsExpensiveNetworkAccess = false
            
            // 額外的模擬器優化：禁用背景任務和wake相關功能
            configuration.sessionSendsLaunchEvents = false
            configuration.isDiscretionary = false
        } else {
            Logger.info("檢測到真實設備，應用標準網路配置", category: .network)
            
            // 真實設備配置（保持原有功能）
            configuration.allowsCellularAccess = true
            configuration.waitsForConnectivity = true
            configuration.httpShouldUsePipelining = false
            configuration.httpShouldSetCookies = true
            configuration.httpCookieAcceptPolicy = .always
            configuration.httpMaximumConnectionsPerHost = 4
            // 真實設備也禁用快取
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
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
            Logger.success("GET請求成功: \(url.absoluteString)", category: .network)
            return result
        } catch {
            Logger.error("GET請求失敗: \(url.absoluteString), 錯誤: \(error)", category: .network)
            throw APIError.requestFailed(error)
        }
    }
    
    /// 執行POST請求
    func performPOSTRequest(url: URL, body: Data? = nil, requireAuth: Bool = false) async throws -> (Data, URLResponse) {
        var request = createPOSTRequest(url: url, body: body)
        addAuthHeaderIfNeeded(to: &request, requireAuth: requireAuth)
        
        do {
            let result = try await session.data(for: request)
            Logger.success("POST請求成功: \(url.absoluteString)", category: .network)
            return result
        } catch {
            Logger.error("POST請求失敗: \(url.absoluteString), 錯誤: \(error)", category: .network)
            throw APIError.requestFailed(error)
        }
    }
    
    /// 執行通用請求
    func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            let result = try await session.data(for: request)
            Logger.success("請求成功: \(request.url?.absoluteString ?? "未知URL")", category: .network)
            return result
        } catch {
            Logger.error("請求失敗: \(request.url?.absoluteString ?? "未知URL"), 錯誤: \(error)", category: .network)
            throw APIError.requestFailed(error)
        }
    }
    
    // MARK: - 私有輔助方法
    
    private func createGETRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60.0  // 針對 AI 生成增加超時時間
        
        // 設定基本標頭，移除可能導致問題的設定
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache, no-store, must-revalidate", forHTTPHeaderField: "Cache-Control") // 禁用緩存
        
        return request
    }
    
    private func createPOSTRequest(url: URL, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60.0  // 針對 AI 生成增加超時時間
        
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
            // 如果需要認證但沒有token，拋出錯誤而不是發送訪客請求
            Logger.warning("需要認證但沒有token，將在API調用時失敗", category: .network)
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
    
    // MARK: - NetworkManagerProtocol Implementation
    
    /// 執行 API 請求並解碼回應
    func performRequest<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        // 建立 URL
        guard let url = endpoint.buildURL(baseURL: APIConfig.apiBaseURL) else {
            throw APIError.invalidURL
        }
        
        var request: URLRequest
        
        switch endpoint.method {
        case .GET:
            request = createGETRequest(url: url)
        case .POST:
            let requestBody = try endpoint.buildRequestBody()
            request = createPOSTRequest(url: url, body: requestBody)
        default:
            request = URLRequest(url: url)
            request.httpMethod = endpoint.method.rawValue
            let requestBody = try endpoint.buildRequestBody()
            request.httpBody = requestBody
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
        }
        
        // 添加認證標頭
        if endpoint.requiresAuth {
            try await addAuthHeaderAsync(to: &request, requireAuth: true)
        }
        
        // 執行請求
        let (data, response) = try await performRequest(request)
        
        // 驗證回應
        try validateHTTPResponse(response, data: data)
        
        // 解碼回應
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(responseType, from: data)
    }
}

// MARK: - 回應處理輔助方法

extension NetworkManager {
    
    /// 處理HTTP回應並檢查狀態碼
    func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        Logger.debug("HTTP狀態碼: \(httpResponse.statusCode)", category: .network)
        
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
            Logger.error("JSON解析錯誤: \(error)", category: .network)
            throw APIError.decodingError(error)
        }
    }
}