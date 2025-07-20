// KnowledgePointAPIService.swift

import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    case unknownError
}

struct KnowledgePointAPIService {
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
    
    // MARK: - 知識點相關 API

    /// 獲取單一知識點的詳細資料
    static func fetchKnowledgePoint(id: Int) async throws -> KnowledgePoint {
        let urlString = "\(baseURL)/knowledge_point/\(id)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        addAuthHeader(to: &request)
        
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
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(to: &request)
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: updates)
        
        try await performRequest(request: request)
    }

    /// AI 重新審閱知識點
    static func aiReviewKnowledgePoint(id: Int, modelName: String? = nil) async throws -> AIReviewResult {
        let urlString = "\(baseURL)/knowledge_point/\(id)/ai_review"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(to: &request)
        
        var body: [String: Any] = [:]
        if let modelName = modelName {
            body["model_name"] = modelName
        }
        
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
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "AI 審閱失敗")
        }
        
        struct AIReviewResponse: Decodable {
            let review_result: AIReviewResult
        }
        
        let reviewResponse = try JSONDecoder().decode(AIReviewResponse.self, from: data)
        return reviewResponse.review_result
    }

    /// 封存一個知識點
    static func archivePoint(id: Int) async throws {
        let urlString = "\(baseURL)/knowledge_point/\(id)/archive"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addAuthHeader(to: &request)
        
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
        addAuthHeader(to: &request)

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
        addAuthHeader(to: &request)

        try await performRequest(request: request)
    }
    
    /// 獲取所有已封存的知識點
    static func fetchArchivedPoints() async throws -> [KnowledgePoint] {
        let urlString = "\(baseURL)/archived_knowledge_points"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        addAuthHeader(to: &request)
        
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
    
    static func batchArchivePoints(ids: [Int]) async throws {
        let urlString = "\(baseURL)/knowledge_points/batch_action"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(to: &request)
        
        let body: [String: Any] = [
            "action": "archive",
            "ids": ids
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        try await performRequest(request: request)
    }
    
    /// 歸檔知識點
    static func archiveKnowledgePoint(id: Int) async throws {
        let urlString = "\(baseURL)/knowledge_point/\(id)/archive"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addAuthHeader(to: &request)
        
        try await performRequest(request: request)
    }
    
    /// 取消歸檔知識點
    static func unarchiveKnowledgePoint(id: Int) async throws {
        let urlString = "\(baseURL)/knowledge_point/\(id)/unarchive"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addAuthHeader(to: &request)
        
        try await performRequest(request: request)
    }
    
    /// 刪除知識點
    static func deleteKnowledgePoint(id: Int) async throws {
        let urlString = "\(baseURL)/knowledge_point/\(id)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        addAuthHeader(to: &request)
        
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
        addAuthHeader(to: &request)
        
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
        addAuthHeader(to: &request)
        
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
        
        return errors.count
    }

    // MARK: - 訪客模式 API
    
    /// 訪客模式獲取範例題目
    static func getGuestSampleQuestions(count: Int = 3) async throws -> QuestionsResponse {
        let urlString = "\(baseURL)/guest/sample_questions?count=\(count)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        addAuthHeader(to: &request, requireAuth: false)
        
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
    static func submitGuestAnswer(question: [String: Any], answer: String) async throws -> FeedbackResponse {
        let urlString = "\(baseURL)/guest/submit_answer"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(to: &request, requireAuth: false)
        
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
    static func getGuestSampleKnowledgePoints() async throws -> [KnowledgePoint] {
        let urlString = "\(baseURL)/guest/sample_knowledge_points"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        addAuthHeader(to: &request, requireAuth: false)
        
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
    
    /// 統一的儀表板數據獲取 (支援認證和訪客模式)
    static func getDashboard() async throws -> DashboardResponse {
        let urlString = "\(baseURL)/data/get_dashboard"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        addAuthHeader(to: &request, requireAuth: false) // 支援訪客模式
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorBody["error"] ?? errorBody["message"] {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "無法獲取儀表板數據")
        }
        
        do {
            let dashboardResponse = try JSONDecoder().decode(DashboardResponse.self, from: data)
            return dashboardResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// 獲取學習日曆熱力圖數據 (支援認證和訪客模式)
    static func getCalendarHeatmap(year: Int, month: Int) async throws -> HeatmapResponse {
        guard var urlComponents = URLComponents(string: "\(baseURL)/data/get_calendar_heatmap") else {
            throw APIError.invalidURL
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "year", value: String(year)),
            URLQueryItem(name: "month", value: String(month))
        ]
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        addAuthHeader(to: &request, requireAuth: false) // 支援訪客模式
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorBody["error"] ?? errorBody["message"] {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "無法獲取日曆數據")
        }
        
        do {
            let heatmapResponse = try JSONDecoder().decode(HeatmapResponse.self, from: data)
            return heatmapResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - 內部輔助函式
    
    // 為請求添加認證標頭
    private static func addAuthHeader(to request: inout URLRequest, requireAuth: Bool = true) {
        if let token = KeychainManager().retrieve(.accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if requireAuth {
            // 如果需要認證但沒有token，使用訪客標識
            request.setValue("Guest", forHTTPHeaderField: "X-User-Type")
        }
    }
    
    // 檢查是否為訪客模式
    private static func isGuestMode() -> Bool {
        // 可以通過 AuthenticationManager 或其他方式檢查
        return KeychainManager().retrieve(.accessToken) == nil
    }
    
    private static func performRequest(request: URLRequest) async throws {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorBody["error"] ?? errorBody["message"] {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "未知伺服器錯誤")
        }
    }
}
