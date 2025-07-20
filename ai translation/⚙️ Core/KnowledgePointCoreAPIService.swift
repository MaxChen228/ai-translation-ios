// KnowledgePointCoreAPIService.swift - 核心知識點 API 服務

import Foundation

struct KnowledgePointCoreAPIService {
    private static let baseURL = "\(APIConfig.apiBaseURL)/api"
    
    // MARK: - 知識點核心 CRUD 操作
    
    /// 獲取單一知識點的詳細資料
    static func fetchKnowledgePoint(id: Int) async throws -> KnowledgePoint {
        let urlString = "\(baseURL)/knowledge_point/\(id)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = APIHelper.createGetRequest(url: url)
        APIHelper.addAuthHeader(to: &request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        do {
            let knowledgePoint = try JSONDecoder().decode(KnowledgePoint.self, from: data)
            return knowledgePoint
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// 更新知識點資料
    static func updateKnowledgePoint(id: Int, updates: [String: Any]) async throws {
        let urlString = "\(baseURL)/knowledge_point/\(id)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let bodyData = try APIHelper.jsonData(from: updates)
        var request = APIHelper.createPostRequest(url: url, body: bodyData)
        request.httpMethod = "PUT"
        APIHelper.addAuthHeader(to: &request)
        
        try await APIHelper.performRequest(request: request)
    }
    
    /// 永久刪除知識點
    static func deleteKnowledgePoint(id: Int) async throws {
        let urlString = "\(baseURL)/knowledge_point/\(id)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        APIHelper.addAuthHeader(to: &request)
        
        try await APIHelper.performRequest(request: request)
    }
    
    /// 歸檔知識點
    static func archiveKnowledgePoint(id: Int) async throws {
        let urlString = "\(baseURL)/knowledge_point/\(id)/archive"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = APIHelper.createPostRequest(url: url)
        APIHelper.addAuthHeader(to: &request)
        
        try await APIHelper.performRequest(request: request)
    }
    
    /// 取消歸檔知識點
    static func unarchiveKnowledgePoint(id: Int) async throws {
        let urlString = "\(baseURL)/knowledge_point/\(id)/unarchive"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = APIHelper.createPostRequest(url: url)
        APIHelper.addAuthHeader(to: &request)
        
        try await APIHelper.performRequest(request: request)
    }
    
    /// 獲取所有已歸檔的知識點
    static func fetchArchivedKnowledgePoints() async throws -> [KnowledgePoint] {
        let urlString = "\(baseURL)/archived_knowledge_points"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = APIHelper.createGetRequest(url: url)
        APIHelper.addAuthHeader(to: &request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
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
    
    /// 批次歸檔知識點
    static func batchArchiveKnowledgePoints(ids: [Int]) async throws {
        let urlString = "\(baseURL)/knowledge_points/batch_action"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let body: [String: Any] = [
            "action": "archive",
            "ids": ids
        ]
        
        let bodyData = try APIHelper.jsonData(from: body)
        var request = APIHelper.createPostRequest(url: url, body: bodyData)
        APIHelper.addAuthHeader(to: &request)
        
        try await APIHelper.performRequest(request: request)
    }
    
    // MARK: - AI 相關功能
    
    /// AI 重新審閱知識點
    static func aiReviewKnowledgePoint(id: Int, modelName: String? = nil) async throws -> AIReviewResult {
        let urlString = "\(baseURL)/knowledge_point/\(id)/ai_review"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var body: [String: Any] = [:]
        if let modelName = modelName {
            body["model_name"] = modelName
        }
        
        let bodyData = try APIHelper.jsonData(from: body)
        var request = APIHelper.createPostRequest(url: url, body: bodyData)
        APIHelper.addAuthHeader(to: &request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorBody["error"] {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "AI 審閱失敗")
        }
        
        struct AIReviewResponse: Decodable {
            let review_result: AIReviewResult
        }
        
        let reviewResponse = try JSONDecoder().decode(AIReviewResponse.self, from: data)
        return reviewResponse.review_result
    }
    
    /// 合併錯誤分析
    static func mergeErrors(error1: ErrorAnalysis, error2: ErrorAnalysis) async throws -> ErrorAnalysis {
        let urlString = "\(baseURL)/merge_errors"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let encoder = JSONEncoder()
        let error1Data = try encoder.encode(error1)
        let error2Data = try encoder.encode(error2)
        
        let error1Dict = try JSONSerialization.jsonObject(with: error1Data) as? [String: Any] ?? [:]
        let error2Dict = try JSONSerialization.jsonObject(with: error2Data) as? [String: Any] ?? [:]
        
        let body: [String: Any] = [
            "error1": error1Dict,
            "error2": error2Dict
        ]
        
        let bodyData = try APIHelper.jsonData(from: body)
        var request = APIHelper.createPostRequest(url: url, body: bodyData)
        APIHelper.addAuthHeader(to: &request)
        
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
        
        let bodyData = try APIHelper.jsonData(from: body)
        var request = APIHelper.createPostRequest(url: url, body: bodyData)
        APIHelper.addAuthHeader(to: &request)
        
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
        
        return errors.count
    }
}