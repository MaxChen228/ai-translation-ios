// APIEndpoint.swift - 統一的API端點定義
// 這個文件替代了分散在多個服務類中的URL構建邏輯

import Foundation

/// HTTP請求方法
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

/// 統一的API端點定義
/// 替代原來分散在各個API服務類中的URL字串拼接
enum APIEndpoint {
    
    // MARK: - 認證相關端點
    case login(email: String, password: String)
    case register(RegisterRequest)
    case refreshToken(String)
    case logout
    case getCurrentUser
    case validateToken
    case upgradeAnonymousUser(username: String, email: String, password: String)
    
    // MARK: - 知識點管理端點
    case fetchKnowledgePoint(id: Int)
    case updateKnowledgePoint(id: Int, updates: [String: Any])
    case deleteKnowledgePoint(id: Int)
    case archiveKnowledgePoint(id: Int)
    case unarchiveKnowledgePoint(id: Int)
    case fetchArchivedKnowledgePoints
    case batchOperationKnowledgePoints(action: String, ids: [Int])
    case aiReviewKnowledgePoint(id: Int, modelName: String?)
    case mergeErrors(ErrorAnalysis, ErrorAnalysis)
    case finalizeKnowledgePoints([ErrorAnalysis], [String: Any?], String)
    
    // MARK: - 儀表板相關端點
    case getDashboard
    case getCalendarHeatmap(year: Int, month: Int)
    case getDailyDetails(date: String)
    case generateDailySummary(date: String)
    
    // MARK: - 訪客模式端點
    case getSampleQuestions(count: Int)
    case submitGuestAnswer([String: Any], String)
    case getSampleKnowledgePoints
    
    // MARK: - Helix語義系統端點
    case getRelatedKnowledgePoints(id: Int, includeDetails: Bool)
    
    // MARK: - 單字記憶庫端點 (暫時移除，避免編譯錯誤)
    // case getVocabularyStatistics
    // case getBuiltinVocabulary(category: String?, difficulty: String?)
    // case getVocabularyWords(category: String?, studyMode: String?)
    
    // MARK: - 端點配置
    var urlPath: String {
        let baseAPI = "/api"
        
        switch self {
        // 認證相關
        case .login: return "\(baseAPI)/auth/login"
        case .register: return "\(baseAPI)/auth/register"
        case .refreshToken: return "\(baseAPI)/auth/refresh"
        case .logout: return "\(baseAPI)/auth/logout"
        case .getCurrentUser: return "\(baseAPI)/auth/me"
        case .validateToken: return "\(baseAPI)/auth/validate"
        case .upgradeAnonymousUser: return "\(baseAPI)/auth/upgrade"
            
        // 知識點管理
        case .fetchKnowledgePoint(let id): return "\(baseAPI)/data/knowledge_point/\(id)"
        case .updateKnowledgePoint(let id, _): return "\(baseAPI)/data/knowledge_point/\(id)"
        case .deleteKnowledgePoint(let id): return "\(baseAPI)/data/knowledge_point/\(id)"
        case .archiveKnowledgePoint(let id): return "\(baseAPI)/data/knowledge_point/\(id)/archive"
        case .unarchiveKnowledgePoint(let id): return "\(baseAPI)/data/knowledge_point/\(id)/unarchive"
        case .fetchArchivedKnowledgePoints: return "\(baseAPI)/data/archived_knowledge_points"
        case .batchOperationKnowledgePoints: return "\(baseAPI)/data/knowledge_points/batch_action"
        case .aiReviewKnowledgePoint(let id, _): return "\(baseAPI)/data/knowledge_point/\(id)/ai_review"
        case .mergeErrors: return "\(baseAPI)/data/merge_errors"
        case .finalizeKnowledgePoints: return "\(baseAPI)/data/session/finalize"
            
        // 儀表板相關
        case .getDashboard: return "\(baseAPI)/data/get_dashboard"
        case .getCalendarHeatmap: return "\(baseAPI)/data/get_calendar_heatmap"
        case .getDailyDetails: return "\(baseAPI)/data/get_daily_details"
        case .generateDailySummary: return "\(baseAPI)/data/generate_daily_summary"
            
        // 訪客模式
        case .getSampleQuestions: return "\(baseAPI)/guest/sample_questions"
        case .submitGuestAnswer: return "\(baseAPI)/guest/submit_answer"
        case .getSampleKnowledgePoints: return "\(baseAPI)/guest/sample_knowledge_points"
            
        // Helix語義系統
        case .getRelatedKnowledgePoints(let id, _): return "\(baseAPI)/helix/point_connections/\(id)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .register, .refreshToken, .logout, .validateToken, .upgradeAnonymousUser,
             .archiveKnowledgePoint, .unarchiveKnowledgePoint, .batchOperationKnowledgePoints,
             .aiReviewKnowledgePoint, .mergeErrors, .finalizeKnowledgePoints,
             .generateDailySummary, .submitGuestAnswer:
            return .POST
            
        case .updateKnowledgePoint:
            return .PUT
            
        case .deleteKnowledgePoint:
            return .DELETE
            
        default:
            return .GET
        }
    }
    
    var requiresAuth: Bool {
        switch self {
        case .getSampleQuestions, .submitGuestAnswer, .getSampleKnowledgePoints:
            return false // 訪客模式端點不需要認證
        case .login, .register:
            return false // 認證端點本身不需要預先認證
        default:
            return true // 其他端點都需要認證
        }
    }
    
    /// 構建完整的URL
    func buildURL(baseURL: String) -> URL? {
        var urlComponents = URLComponents(string: baseURL + urlPath)
        
        // 為需要查詢參數的端點添加參數
        switch self {
        case .getSampleQuestions(let count):
            urlComponents?.queryItems = [URLQueryItem(name: "count", value: String(count))]
            
        case .getCalendarHeatmap(let year, let month):
            urlComponents?.queryItems = [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "month", value: String(month))
            ]
            
        case .getDailyDetails(let date):
            urlComponents?.queryItems = [URLQueryItem(name: "date", value: date)]
            
        case .getRelatedKnowledgePoints(_, let includeDetails):
            if includeDetails {
                urlComponents?.queryItems = [URLQueryItem(name: "include_details", value: "true")]
            }
            
        default:
            break // 其他端點不需要查詢參數
        }
        
        return urlComponents?.url
    }
    
    /// 構建請求體
    func buildRequestBody() throws -> Data? {
        switch self {
        case .login(let email, let password):
            let loginRequest = LoginRequest(email: email, password: password)
            return try JSONEncoder().encode(loginRequest)
            
        case .register(let request):
            return try JSONEncoder().encode(request)
            
        case .refreshToken(let token):
            let refreshRequest = RefreshTokenRequest(refreshToken: token)
            return try JSONEncoder().encode(refreshRequest)
            
        case .updateKnowledgePoint(_, let updates):
            return try JSONSerialization.data(withJSONObject: updates)
            
        case .batchOperationKnowledgePoints(let action, let ids):
            let body: [String: Any] = ["action": action, "ids": ids]
            return try JSONSerialization.data(withJSONObject: body)
            
        case .aiReviewKnowledgePoint(_, let modelName):
            var body: [String: Any] = [:]
            if let modelName = modelName {
                body["model_name"] = modelName
            }
            return try JSONSerialization.data(withJSONObject: body)
            
        case .mergeErrors(let error1, let error2):
            let encoder = JSONEncoder()
            let error1Data = try encoder.encode(error1)
            let error2Data = try encoder.encode(error2)
            
            let error1Dict = try JSONSerialization.jsonObject(with: error1Data) as? [String: Any] ?? [:]
            let error2Dict = try JSONSerialization.jsonObject(with: error2Data) as? [String: Any] ?? [:]
            
            let body: [String: Any] = [
                "error1": error1Dict,
                "error2": error2Dict
            ]
            return try JSONSerialization.data(withJSONObject: body)
            
        case .finalizeKnowledgePoints(let errors, let questionData, let userAnswer):
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
            return try JSONSerialization.data(withJSONObject: body)
            
        case .generateDailySummary(let date):
            let body: [String: Any] = ["date": date]
            return try JSONSerialization.data(withJSONObject: body)
            
        case .submitGuestAnswer(let question, let answer):
            let body: [String: Any] = [
                "question": question,
                "answer": answer
            ]
            return try JSONSerialization.data(withJSONObject: body)
            
        case .upgradeAnonymousUser(let username, let email, let password):
            let body: [String: Any] = [
                "username": username,
                "email": email,
                "password": password
            ]
            return try JSONSerialization.data(withJSONObject: body)
            
        default:
            return nil // GET請求和其他不需要請求體的請求
        }
    }
}

// MARK: - 端點分類輔助方法
extension APIEndpoint {
    
    /// 是否為認證相關端點
    var isAuthEndpoint: Bool {
        switch self {
        case .login, .register, .refreshToken, .logout, .getCurrentUser, .validateToken, .upgradeAnonymousUser:
            return true
        default:
            return false
        }
    }
    
    /// 是否為訪客模式端點
    var isGuestEndpoint: Bool {
        switch self {
        case .getSampleQuestions, .submitGuestAnswer, .getSampleKnowledgePoints:
            return true
        default:
            return false
        }
    }
    
    /// 是否需要延長超時時間的端點
    var needsExtendedTimeout: Bool {
        switch self {
        case .finalizeKnowledgePoints, .aiReviewKnowledgePoint, .generateDailySummary:
            return true // AI相關操作需要更長時間
        default:
            return false
        }
    }
    
    /// 獲取超時時間
    var timeoutInterval: TimeInterval {
        return needsExtendedTimeout ? 120.0 : 30.0
    }
}