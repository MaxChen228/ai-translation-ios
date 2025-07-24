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
    case googleAuth(idToken: String)
    case appleAuth(identityToken: String)
    
    // MARK: - 知識點管理端點（支援複合ID）
    case fetchKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?)
    case updateKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?, updates: KnowledgePointUpdateRequest)
    case deleteKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?)
    case archiveKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?)
    case unarchiveKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?)
    case fetchArchivedKnowledgePoints
    case batchOperationKnowledgePoints(action: String, compositeIds: [CompositeKnowledgePointID]?, legacyIds: [Int]?)
    case aiReviewKnowledgePoint(compositeId: CompositeKnowledgePointID?, legacyId: Int?, modelName: String?)
    case mergeErrors(ErrorAnalysis, ErrorAnalysis)
    case finalizeKnowledgePoints(KnowledgePointFinalizationRequest)
    
    // MARK: - 儀表板相關端點
    case getDashboard
    case getCalendarHeatmap(year: Int, month: Int)
    case getDailyDetails(date: String)
    case generateDailySummary(date: String)
    
    // MARK: - 訪客模式端點
    case getSampleQuestions(count: Int)
    case submitGuestAnswer(GuestAnswerSubmissionRequest)
    case getSampleKnowledgePoints
    
    // MARK: - Helix語義系統端點
    case getRelatedKnowledgePoints(compositeId: CompositeKnowledgePointID?, legacyId: Int?, includeDetails: Bool)
    
    
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
        case .googleAuth: return "\(baseAPI)/auth/google"
        case .appleAuth: return "\(baseAPI)/auth/apple"
            
        // 知識點管理（支援複合ID）
        case .fetchKnowledgePoint(let compositeId, let legacyId):
            if let composite = compositeId {
                return "\(baseAPI)/v2/data/knowledge_point/\(composite.userId)/\(composite.sequenceId)"
            } else if let legacy = legacyId {
                return "\(baseAPI)/data/knowledge_point/\(legacy)"
            } else {
                return "\(baseAPI)/data/knowledge_point/invalid"
            }
        case .updateKnowledgePoint(let compositeId, let legacyId, _):
            if let composite = compositeId {
                return "\(baseAPI)/v2/data/knowledge_point/\(composite.userId)/\(composite.sequenceId)"
            } else if let legacy = legacyId {
                return "\(baseAPI)/data/knowledge_point/\(legacy)"
            } else {
                return "\(baseAPI)/data/knowledge_point/invalid"
            }
        case .deleteKnowledgePoint(let compositeId, let legacyId):
            if let composite = compositeId {
                return "\(baseAPI)/v2/data/knowledge_point/\(composite.userId)/\(composite.sequenceId)"
            } else if let legacy = legacyId {
                return "\(baseAPI)/data/knowledge_point/\(legacy)"
            } else {
                return "\(baseAPI)/data/knowledge_point/invalid"
            }
        case .archiveKnowledgePoint(let compositeId, let legacyId):
            if let composite = compositeId {
                return "\(baseAPI)/v2/data/knowledge_point/\(composite.userId)/\(composite.sequenceId)/archive"
            } else if let legacy = legacyId {
                return "\(baseAPI)/data/knowledge_point/\(legacy)/archive"
            } else {
                return "\(baseAPI)/data/knowledge_point/invalid/archive"
            }
        case .unarchiveKnowledgePoint(let compositeId, let legacyId):
            if let composite = compositeId {
                return "\(baseAPI)/v2/data/knowledge_point/\(composite.userId)/\(composite.sequenceId)/unarchive"
            } else if let legacy = legacyId {
                return "\(baseAPI)/data/knowledge_point/\(legacy)/unarchive"
            } else {
                return "\(baseAPI)/data/knowledge_point/invalid/unarchive"
            }
        case .fetchArchivedKnowledgePoints: return "\(baseAPI)/data/archived_knowledge_points"
        case .batchOperationKnowledgePoints(_, let compositeIds, _):
            if let _ = compositeIds {
                return "\(baseAPI)/v2/data/knowledge_points/batch_action"
            } else {
                return "\(baseAPI)/data/knowledge_points/batch_action"
            }
        case .aiReviewKnowledgePoint(let compositeId, let legacyId, _):
            if let composite = compositeId {
                return "\(baseAPI)/v2/data/knowledge_point/\(composite.userId)/\(composite.sequenceId)/ai_review"
            } else if let legacy = legacyId {
                return "\(baseAPI)/data/knowledge_point/\(legacy)/ai_review"
            } else {
                return "\(baseAPI)/data/knowledge_point/invalid/ai_review"
            }
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
        case .getRelatedKnowledgePoints(let compositeId, let legacyId, _):
            if let composite = compositeId {
                return "\(baseAPI)/v2/helix/point_connections/\(composite.userId)/\(composite.sequenceId)"
            } else if let legacy = legacyId {
                return "\(baseAPI)/helix/point_connections/\(legacy)"
            } else {
                return "\(baseAPI)/helix/point_connections/invalid"
            }
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .register, .refreshToken, .logout, .validateToken, .upgradeAnonymousUser, .googleAuth, .appleAuth,
             .archiveKnowledgePoint(_, _), .unarchiveKnowledgePoint(_, _), .batchOperationKnowledgePoints(_, _, _),
             .aiReviewKnowledgePoint(_, _, _), .mergeErrors, .finalizeKnowledgePoints,
             .generateDailySummary, .submitGuestAnswer:
            return .POST
            
        case .updateKnowledgePoint(_, _, _):
            return .PUT
            
        case .deleteKnowledgePoint(_, _):
            return .DELETE
            
        default:
            return .GET
        }
    }
    
    var requiresAuth: Bool {
        switch self {
        case .getSampleQuestions, .submitGuestAnswer, .getSampleKnowledgePoints:
            return false // 訪客模式端點不需要認證
        case .login, .register, .googleAuth, .appleAuth:
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
            
        case .getRelatedKnowledgePoints(_, _, let includeDetails):
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
            
        case .updateKnowledgePoint(_, _, let updates):
            return try JSONEncoder().encode(updates)
            
        case .batchOperationKnowledgePoints(let action, let compositeIds, let legacyIds):
            var body: [String: Any] = ["action": action]
            if let compositeIds = compositeIds {
                let compositeIdStrings = compositeIds.map { $0.stringRepresentation }
                body["composite_ids"] = compositeIdStrings
            }
            if let legacyIds = legacyIds {
                body["legacy_ids"] = legacyIds
            }
            return try JSONSerialization.data(withJSONObject: body)
            
        case .aiReviewKnowledgePoint(_, _, let modelName):
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
            
        case .finalizeKnowledgePoints(let request):
            return try JSONEncoder().encode(request)
            
        case .generateDailySummary(let date):
            let body: [String: Any] = ["date": date]
            return try JSONSerialization.data(withJSONObject: body)
            
        case .submitGuestAnswer(let request):
            return try JSONEncoder().encode(request)
            
        case .upgradeAnonymousUser(let username, let email, let password):
            let body: [String: Any] = [
                "username": username,
                "email": email,
                "password": password
            ]
            return try JSONSerialization.data(withJSONObject: body)
            
        case .googleAuth(let idToken):
            let body: [String: Any] = ["id_token": idToken]
            return try JSONSerialization.data(withJSONObject: body)
            
        case .appleAuth(let identityToken):
            let body: [String: Any] = ["identity_token": identityToken]
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
        case .login, .register, .refreshToken, .logout, .getCurrentUser, .validateToken, .upgradeAnonymousUser, .googleAuth, .appleAuth:
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