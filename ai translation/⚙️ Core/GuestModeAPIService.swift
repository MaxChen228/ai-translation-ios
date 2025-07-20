// GuestModeAPIService.swift - 訪客模式 API 服務

import Foundation

struct GuestModeAPIService {
    private static let baseURL = "\(APIConfig.apiBaseURL)/api"
    
    // MARK: - 訪客模式 API
    
    /// 訪客模式獲取範例題目
    static func getSampleQuestions(count: Int = 3) async throws -> QuestionsResponse {
        let urlString = "\(baseURL)/guest/sample_questions?count=\(count)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        APIHelper.addAuthHeader(to: &request, requireAuth: false)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        do {
            let questionsResponse = try JSONDecoder().decode(QuestionsResponse.self, from: data)
            return questionsResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// 訪客模式提交答案（僅返回基本分析）
    static func submitAnswer(question: [String: Any], answer: String) async throws -> FeedbackResponse {
        let urlString = "\(baseURL)/guest/submit_answer"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        APIHelper.addAuthHeader(to: &request, requireAuth: false)
        
        let body: [String: Any] = [
            "question": question,
            "answer": answer
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorBody["error"] {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "提交失敗")
        }
        
        let feedbackResponse = try JSONDecoder().decode(FeedbackResponse.self, from: data)
        return feedbackResponse
    }
    
    /// 訪客模式獲取範例知識點
    static func getSampleKnowledgePoints() async throws -> [KnowledgePoint] {
        let urlString = "\(baseURL)/guest/sample_knowledge_points"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        APIHelper.addAuthHeader(to: &request, requireAuth: false)
        
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
}