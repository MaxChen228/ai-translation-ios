// Models.swift

import Foundation
import SwiftUI

// 單一一題的結構
struct Question: Codable, Identifiable {
    let id = UUID()
    let newSentence: String
    let type: String
    let hintText: String?
    
    // 支援複合ID系統
    let knowledgePointCompositeId: CompositeKnowledgePointID?
    let knowledgePointId: Int? // 舊系統相容
    
    let masteryLevel: Double?

    private enum CodingKeys: String, CodingKey {
        case newSentence = "new_sentence"
        case type
        case hintText = "hint_text"
        case knowledgePointCompositeId = "knowledge_point_composite_id"
        case knowledgePointId = "knowledge_point_id"
        case masteryLevel = "mastery_level"
    }
    
    // 便利方法：獲取有效的知識點ID
    var effectiveKnowledgePointId: String? {
        if let composite = knowledgePointCompositeId {
            return composite.stringRepresentation
        } else if let legacyId = knowledgePointId {
            return String(legacyId)
        } else {
            return nil
        }
    }
}

// 整個 API 回應的結構
struct QuestionsResponse: Codable {
    let questions: [Question]
}

// 錯誤分析結構
struct ErrorAnalysis: Codable, Identifiable {
    let id = UUID()
    let errorTypeCode: String
    let keyPointSummary: String
    let originalPhrase: String
    let correction: String
    let explanation: String
    let severity: String

    private enum CodingKeys: String, CodingKey {
        case errorTypeCode = "error_type_code"
        case keyPointSummary = "key_point_summary"
        case originalPhrase = "original_phrase"
        case correction
        case explanation
        case severity
    }

    var categoryName: String {
        switch errorTypeCode {
        case "A": return "詞彙與片語錯誤"
        case "B": return "語法結構錯誤"
        case "C": return "語意與語用錯誤"
        case "D": return "拼寫與格式錯誤"
        case "E": return "系統錯誤"
        default: return "未知錯誤類型"
        }
    }
    
    var categoryIcon: String {
        switch errorTypeCode {
        case "A": return "text.book.closed.fill"
        case "B": return "flowchart.fill"
        case "C": return "bubble.left.and.bubble.right.fill"
        case "D": return "textformat"
        default: return "exclamationmark.triangle.fill"
        }
    }
    
    var categoryColor: Color {
        switch errorTypeCode {
        case "A": return Color.modernSpecial
        case "B": return Color.modernWarning
        case "C": return Color.modernAccent
        case "D": return Color.modernTextSecondary
        default: return Color.modernError
        }
    }
}

// AI 點評回傳的結構
struct FeedbackResponse: Codable {
    let isGenerallyCorrect: Bool
    let overallSuggestion: String
    let errorAnalysis: [ErrorAnalysis]
    let didMasterReviewConcept: Bool? // 複習題才會有
    
    private enum CodingKeys: String, CodingKey {
        case isGenerallyCorrect = "is_generally_correct"
        case overallSuggestion = "overall_suggestion"
        case errorAnalysis = "error_analysis"
        case didMasterReviewConcept = "did_master_review_concept"
    }
}

// 複合ID結構用於知識點
struct CompositeKnowledgePointID: Codable, Hashable {
    let userId: Int
    let sequenceId: Int
    
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sequenceId = "sequence_id"
    }
    
    // 為了向後相容，提供字串表示
    var stringRepresentation: String {
        return "\(userId):\(sequenceId)"
    }
    
    // 從舊的全域ID創建（僅用於遷移期間）
    static func fromLegacyGlobalId(_ globalId: Int) -> CompositeKnowledgePointID {
        // 遷移期間，假設所有現有知識點都屬於user_id=1
        return CompositeKnowledgePointID(userId: 1, sequenceId: globalId)
    }
}

// 知識點結構 - 支援複合ID系統
struct KnowledgePoint: Codable, Identifiable {
    // 新的複合ID系統
    let compositeId: CompositeKnowledgePointID?
    
    // 舊的全域ID（保留用於向後相容）
    let legacyId: Int?
    
    // 臨時字段：用於讀取舊API返回的id字段
    let oldId: Int?
    
    let category: String
    let subcategory: String
    let correctPhrase: String
    let explanation: String?
    let userContextSentence: String?
    let incorrectPhraseInContext: String?
    let keyPointSummary: String?
    let masteryLevel: Double
    let mistakeCount: Int
    let correctCount: Int
    let nextReviewDate: String?
    let isArchived: Bool?
    let aiReviewNotes: String?
    let lastAiReviewDate: String?

    private enum CodingKeys: String, CodingKey {
        case compositeId = "composite_id"
        case legacyId = "legacy_id"
        case oldId = "id"  // 向後兼容舊API
        case category
        case subcategory
        case correctPhrase = "correct_phrase"
        case explanation
        case userContextSentence = "user_context_sentence"
        case incorrectPhraseInContext = "incorrect_phrase_in_context"
        case keyPointSummary = "key_point_summary"
        case masteryLevel = "mastery_level"
        case mistakeCount = "mistake_count"
        case correctCount = "correct_count"
        case nextReviewDate = "next_review_date"
        case isArchived = "is_archived"
        case aiReviewNotes = "ai_review_notes"
        case lastAiReviewDate = "last_ai_review_date"
    }
    
    
    // Identifiable協議要求的id屬性
    var id: String {
        return effectiveId
    }
    
    // 便利方法：獲取有效的ID（優先使用複合ID，否則使用舊ID）
    var effectiveId: String {
        if let composite = compositeId {
            return composite.stringRepresentation
        } else if let legacy = legacyId {
            return String(legacy)
        } else if let old = oldId {
            return String(old)
        } else {
            // 使用correctPhrase的hash作為唯一標識符，確保不會重複
            return "fallback_\(correctPhrase.hashValue)"
        }
    }
    
    // 便利方法：獲取數字ID用於API調用（向後相容）
    var numericId: Int? {
        return compositeId?.sequenceId ?? legacyId ?? oldId
    }
    
    // 便利方法：檢查是否使用新ID系統
    var usesCompositeId: Bool {
        return compositeId != nil
    }
}

// AI 審閱結果結構
struct AIReviewResult: Codable {
    let overallAssessment: String
    let accuracyScore: Int
    let clarityScore: Int
    let teachingEffectiveness: Int
    let improvementSuggestions: [String]
    let potentialConfusions: [String]
    let recommendedCategory: String
    let additionalExamples: [String]
    
    private enum CodingKeys: String, CodingKey {
        case overallAssessment = "overall_assessment"
        case accuracyScore = "accuracy_score"
        case clarityScore = "clarity_score"
        case teachingEffectiveness = "teaching_effectiveness"
        case improvementSuggestions = "improvement_suggestions"
        case potentialConfusions = "potential_confusions"
        case recommendedCategory = "recommended_category"
        case additionalExamples = "additional_examples"
    }
}

// 其他結構
struct DashboardResponse: Codable {
    let knowledgePoints: [KnowledgePoint]
    
    private enum CodingKeys: String, CodingKey {
        case knowledgePoints = "knowledge_points"
    }
}

struct Flashcard: Codable, Identifiable {
    let id = UUID()
    let front: String
    let backCorrection: String
    let backExplanation: String
    let category: String
    
    private enum CodingKeys: String, CodingKey {
        case front
        case backCorrection = "back_correction"
        case backExplanation = "back_explanation"
        case category
    }
}

struct FlashcardsResponse: Codable {
    let flashcards: [Flashcard]
}

struct DailyDetailResponse: Codable {
    let totalLearningTimeSeconds: Int
    let reviewedKnowledgePoints: [LearnedPoint]
    let newKnowledgePoints: [LearnedPoint]
    
    private enum CodingKeys: String, CodingKey {
        case totalLearningTimeSeconds = "total_learning_time_seconds"
        case reviewedKnowledgePoints = "reviewed_knowledge_points"
        case newKnowledgePoints = "new_knowledge_points"
    }
}

struct LearnedPoint: Codable, Identifiable {
    let id = UUID()
    let summary: String
    let count: Int
    
    private enum CodingKeys: String, CodingKey {
        case summary, count
    }
}

struct SmartHintResponse: Codable {
    let smartHint: String
    let thinkingQuestions: [String]
    let encouragement: String
    
    private enum CodingKeys: String, CodingKey {
        case smartHint = "smart_hint"
        case thinkingQuestions = "thinking_questions"
        case encouragement
    }
}

// MARK: - 認證相關資料結構

// 認證狀態枚舉 - 簡化為二元狀態
enum UserAuthState: Equatable {
    case authenticated(User)            // 已登入用戶（包含匿名用戶）
    case unauthenticated               // 未登入
    
    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
    
    var currentUser: User? {
        if case .authenticated(let user) = self { return user }
        return nil
    }
}


// 使用者資料模型
struct User: Codable, Identifiable, Equatable {
    let id: Int
    let username: String
    let email: String
    let displayName: String?
    let nativeLanguage: String?
    let targetLanguage: String?
    let learningLevel: String?
    let totalLearningTime: Int
    let knowledgePointsCount: Int
    let createdAt: String
    let lastLoginAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, username, email
        case displayName = "display_name"
        case nativeLanguage = "native_language"
        case targetLanguage = "target_language"
        case learningLevel = "learning_level"
        case totalLearningTime = "total_learning_time"
        case knowledgePointsCount = "knowledge_points_count"
        case createdAt = "created_at"
        case lastLoginAt = "last_login_at"
    }
}

// 登入請求
struct LoginRequest: Codable {
    let email: String
    let password: String
}

// 註冊請求
struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
    let displayName: String?
    let nativeLanguage: String?
    let targetLanguage: String?
    let learningLevel: String?
    
    init(username: String, email: String, password: String, displayName: String? = nil, nativeLanguage: String? = "中文", targetLanguage: String? = "英文", learningLevel: String? = "初級") {
        self.username = username
        self.email = email
        self.password = password
        self.displayName = displayName
        self.nativeLanguage = nativeLanguage
        self.targetLanguage = targetLanguage
        self.learningLevel = learningLevel
    }
    
    private enum CodingKeys: String, CodingKey {
        case username, email, password
        case displayName = "display_name"
        case nativeLanguage = "native_language"
        case targetLanguage = "target_language"
        case learningLevel = "learning_level"
    }
}

// 認證回應
struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    
    private enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

// Token 刷新請求
struct RefreshTokenRequest: Codable {
    let refreshToken: String
    
    private enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

// 認證錯誤
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case userAlreadyExists
    case networkError
    case tokenExpired
    case invalidToken
    case serverError(String)
    case registrationFailed(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "帳號或密碼錯誤"
        case .userAlreadyExists:
            return "使用者已存在"
        case .networkError:
            return "網路連線錯誤"
        case .tokenExpired:
            return "登入已過期，請重新登入"
        case .invalidToken:
            return "無效的認證憑證"
        case .serverError(let message):
            return "伺服器錯誤：\(message)"
        case .registrationFailed(let message):
            return message
        case .unknown:
            return "未知錯誤"
        }
    }
}

// MARK: - API 錯誤類型
enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無效的 URL"
        case .requestFailed(let error):
            return "請求失敗：\(error.localizedDescription)"
        case .invalidResponse:
            return "無效的伺服器回應"
        case .serverError(let statusCode, let message):
            return "伺服器錯誤 (\(statusCode))：\(message)"
        case .decodingError(let error):
            return "數據解析錯誤：\(error.localizedDescription)"
        case .unknownError:
            return "未知的 API 錯誤"
        }
    }
}

// MARK: - 額外的回應類型
struct DailyDetailsResponse: Codable {
    let date: String
    let knowledgePoints: [KnowledgePoint]
    let totalStudyTime: Int
    let correctAnswers: Int
    let totalAnswers: Int
    
    private enum CodingKeys: String, CodingKey {
        case date
        case knowledgePoints = "knowledge_points"
        case totalStudyTime = "total_study_time"
        case correctAnswers = "correct_answers"
        case totalAnswers = "total_answers"
    }
}

// DailySummaryResponse is defined in DailyDetailView.swift

struct HelixConnectionResponse: Codable {
    let data: HelixConnectionData
    
    struct HelixConnectionData: Codable {
        let connections: [HelixConnection]
    }
    
    struct HelixConnection: Codable {
        let connectedPointId: Int
        let connectionStrength: Double
        let connectedPointDetails: ConnectedPointDetails?
        
        private enum CodingKeys: String, CodingKey {
            case connectedPointId = "connected_point_id"
            case connectionStrength = "connection_strength"
            case connectedPointDetails = "connected_point_details"
        }
        
        struct ConnectedPointDetails: Codable {
            let category: String
            let subcategory: String
            let correctPhrase: String
            let keyPointSummary: String
            let masteryLevel: Double
            
            private enum CodingKeys: String, CodingKey {
                case category
                case subcategory
                case correctPhrase = "correct_phrase"
                case keyPointSummary = "key_point_summary"
                case masteryLevel = "mastery_level"
            }
        }
    }
}
