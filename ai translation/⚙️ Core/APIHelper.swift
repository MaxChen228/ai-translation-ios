// APIHelper.swift - API 通用輔助函式

import Foundation

struct APIHelper {
    
    // MARK: - 通用輔助函式
    
    /// 為請求添加認證標頭
    static func addAuthHeader(to request: inout URLRequest, requireAuth: Bool = true) {
        if let token = KeychainManager().retrieve(.accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if requireAuth {
            // 如果需要認證但沒有token，使用訪客標識
            request.setValue("Guest", forHTTPHeaderField: "X-User-Type")
        }
    }
    
    /// 檢查是否為訪客模式
    static func isGuestMode() -> Bool {
        return KeychainManager().retrieve(.accessToken) == nil
    }
    
    /// 執行通用請求並處理回應
    static func performRequest(request: URLRequest) async throws {
        let (data, response) = try await NetworkManager.shared.performRequest(request)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
    }
    
    /// 建立標準 POST 請求
    static func createPostRequest(url: URL, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.httpBody = body
        return request
    }
    
    /// 建立標準 GET 請求
    static func createGetRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        return request
    }
    
    /// 將字典轉換為 JSON 資料
    static func jsonData(from dictionary: [String: Any]) throws -> Data {
        return try JSONSerialization.data(withJSONObject: dictionary)
    }
}

// MARK: - KeychainManager 已在 AuthenticationManager.swift 中定義