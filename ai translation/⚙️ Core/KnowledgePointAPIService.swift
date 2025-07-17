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
    
    static func mergeErrors(error1: ErrorAnalysis, error2: ErrorAnalysis) async throws -> ErrorAnalysis {
        let urlString = "\(baseURL)/merge_errors"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 將 ErrorAnalysis 轉換為字典
        let encoder = JSONEncoder()
        let error1Data = try encoder.encode(error1)
        let error2Data = try encoder.encode(error2)
        
        let error1Dict = try JSONSerialization.jsonObject(with: error1Data) as? [String: Any] ?? [:]
        let error2Dict = try JSONSerialization.jsonObject(with: error2Data) as? [String: Any] ?? [:]
        
        let body: [String: Any] = [
            "error1": error1Dict,
            "error2": error2Dict
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorBody["error"] {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "合併失敗")
        }
        
        // 解析回應
        struct MergeResponse: Decodable {
            let merged_error: ErrorAnalysis
        }
        
        let mergeResponse = try JSONDecoder().decode(MergeResponse.self, from: data)
        return mergeResponse.merged_error
    }

    /// 將最終確認的錯誤列表儲存為知識點
    static func finalizeKnowledgePoints(errors: [ErrorAnalysis], questionData: [String: Any?], userAnswer: String) async throws -> Int {
        let urlString = "\(baseURL)/knowledge_points/finalize"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 將 ErrorAnalysis 陣列轉換為字典陣列
        let encoder = JSONEncoder()
        var errorDicts: [[String: Any]] = []
        
        for error in errors {
            let errorData = try encoder.encode(error)
            if let errorDict = try JSONSerialization.jsonObject(with: errorData) as? [String: Any] {
                errorDicts.append(errorDict)
            }
        }
        
        let body: [String: Any] = [
            "errors": errorDicts,
            "question_data": questionData,
            "user_answer": userAnswer
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorBody["error"] {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "儲存失敗")
        }
        
        // 回傳儲存的數量
        return errors.count
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
