// Models.swift

import Foundation
import SwiftUI

// 單一一題的結構
struct Question: Codable, Identifiable {
    let id = UUID()
    let new_sentence: String
    let type: String
    let hint_text: String?
    let knowledge_point_id: Int?
    let mastery_level: Double?

    private enum CodingKeys: String, CodingKey {
        case new_sentence, type, hint_text, knowledge_point_id, mastery_level
    }
}

// 整個 API 回應的結構
struct QuestionsResponse: Codable {
    let questions: [Question]
}

// 錯誤分析結構
struct ErrorAnalysis: Codable, Identifiable {
    let id = UUID()
    let error_type_code: String
    let key_point_summary: String
    let original_phrase: String
    let correction: String
    let explanation: String
    let severity: String

    private enum CodingKeys: String, CodingKey {
        case error_type_code, key_point_summary, original_phrase, correction, explanation, severity
    }

    var categoryName: String {
        switch error_type_code {
        case "A": return "詞彙與片語錯誤"
        case "B": return "語法結構錯誤"
        case "C": return "語意與語用錯誤"
        case "D": return "拼寫與格式錯誤"
        case "E": return "系統錯誤"
        default: return "未知錯誤類型"
        }
    }
    
    var categoryIcon: String {
        switch error_type_code {
        case "A": return "text.book.closed.fill"
        case "B": return "sitemap.fill"
        case "C": return "bubble.left.and.bubble.right.fill"
        case "D": return "textformat"
        default: return "exclamationmark.triangle.fill"
        }
    }
    
    var categoryColor: Color {
        switch error_type_code {
        case "A": return .blue
        case "B": return .orange
        case "C": return .purple
        case "D": return .gray
        default: return .red
        }
    }
}

// AI 點評回傳的結構
struct FeedbackResponse: Codable {
    let is_generally_correct: Bool
    let overall_suggestion: String
    let error_analysis: [ErrorAnalysis]
    let did_master_review_concept: Bool? // 複習題才會有
}

// 知識點結構
struct KnowledgePoint: Codable, Identifiable {
    let identifiableId = UUID()
    let id: Int
    let category: String
    let subcategory: String
    let correct_phrase: String
    let explanation: String?
    let user_context_sentence: String?
    let incorrect_phrase_in_context: String?
    let key_point_summary: String?
    let mastery_level: Double
    let mistake_count: Int
    let correct_count: Int
    let next_review_date: String?
    let is_archived: Bool?
    let ai_review_notes: String?
    let last_ai_review_date: String?

    private enum CodingKeys: String, CodingKey {
        case id, category, subcategory, correct_phrase, explanation, user_context_sentence, incorrect_phrase_in_context, key_point_summary, mastery_level, mistake_count, correct_count, next_review_date, is_archived, ai_review_notes, last_ai_review_date
    }
}

// AI 審閱結果結構
struct AIReviewResult: Codable {
    let overall_assessment: String
    let accuracy_score: Int
    let clarity_score: Int
    let teaching_effectiveness: Int
    let improvement_suggestions: [String]
    let potential_confusions: [String]
    let recommended_category: String
    let additional_examples: [String]
}

// 其他結構
struct DashboardResponse: Codable {
    let knowledge_points: [KnowledgePoint]
}

struct Flashcard: Codable, Identifiable {
    let id = UUID()
    let front: String
    let back_correction: String
    let back_explanation: String
    let category: String
    
    private enum CodingKeys: String, CodingKey {
        case front, back_correction, back_explanation, category
    }
}

struct FlashcardsResponse: Codable {
    let flashcards: [Flashcard]
}

struct DailyDetailResponse: Codable {
    let total_learning_time_seconds: Int
    let reviewed_knowledge_points: [LearnedPoint]
    let new_knowledge_points: [LearnedPoint]
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
    let smart_hint: String
    let thinking_questions: [String]
    let encouragement: String
}

// MARK: - 認證相關資料結構

// 認證狀態枚舉
enum UserAuthState: Equatable {
    case guest                          // 訪客模式
    case authenticated(User)            // 已登入用戶
    case unauthenticated               // 未登入（首次啟動）
    
    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
    
    var isGuest: Bool {
        if case .guest = self { return true }
        return false
    }
    
    var currentUser: User? {
        if case .authenticated(let user) = self { return user }
        return nil
    }
}

// 訪客使用者資料
struct GuestUser: Codable {
    let id: String
    let username: String
    let displayName: String
    let createdAt: Date
    var totalLearningTime: Int
    var knowledgePointsCount: Int
    var sessionsCompleted: Int
    
    init() {
        self.id = "guest_\(UUID().uuidString)"
        self.username = "訪客用戶"
        self.displayName = "訪客模式"
        self.createdAt = Date()
        self.totalLearningTime = 0
        self.knowledgePointsCount = 0
        self.sessionsCompleted = 0
    }
    
    // 轉換為展示用的 User 格式
    var asDisplayUser: User {
        return User(
            id: 0,
            username: username,
            email: "guest@example.com",
            displayName: displayName,
            nativeLanguage: "中文",
            targetLanguage: "英文",
            learningLevel: "體驗中",
            totalLearningTime: totalLearningTime,
            knowledgePointsCount: knowledgePointsCount,
            createdAt: ISO8601DateFormatter().string(from: createdAt),
            lastLoginAt: nil
        )
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
        case .unknown:
            return "未知錯誤"
        }
    }
}
