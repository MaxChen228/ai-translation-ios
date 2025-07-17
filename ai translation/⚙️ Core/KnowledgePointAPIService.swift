// KnowledgePointAPIService.swift

import Foundation

// 定義一個錯誤類型，方便處理 API 錯誤
enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    case unknownError
}

struct KnowledgePointAPIService {
    // 您的後端 API 基礎 URL
    // 請根據您在 Render 或本地運行的位址修改
    private static let baseURL = "\(APIConfig.apiBaseURL)/api"

    /// 封存一個知識點
    static func archivePoint(id: Int) async throws {
        let urlString = "\(baseURL)/knowledge_point/\(id)/archive"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        try await performRequest(request: request)
    }
    
    /// 取消封存一個知識點
    static func unarchivePoint(id: Int) async throws {
        let urlString = "\(baseURL)/knowledge_point/\(id)/unarchive"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        try await performRequest(request: request)
    }

    /// 永久刪除一個知識點
    static func deletePoint(id: Int) async throws {
        let urlString = "\(baseURL)/knowledge_point/\(id)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        try await performRequest(request: request)
    }
    
    /// 獲取所有已封存的知識點
    static func fetchArchivedPoints() async throws -> [KnowledgePoint] {
        let urlString = "\(baseURL)/archived_knowledge_points"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        do {
            let dashboardResponse = try JSONDecoder().decode(DashboardResponse.self, from: data)
            return dashboardResponse.knowledge_points
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    static func batchArchivePoints(ids: [Int]) async throws {
        // 【修改】移除此處多餘的 /api，因為 baseURL 中已經包含了
        let urlString = "\(baseURL)/knowledge_points/batch_action"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "action": "archive",
            "ids": ids
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        try await performRequest(request: request)
    }


    // 內部輔助函式，用於執行不需要回傳資料的請求 (如 POST, DELETE)
    private static func performRequest(request: URLRequest) async throws {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // 檢查狀態碼是否在成功範圍內
        guard (200...299).contains(httpResponse.statusCode) else {
            // 嘗試解析後端回傳的錯誤訊息
            if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorBody["error"] ?? errorBody["message"] {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "未知伺服器錯誤")
        }
    }
}
