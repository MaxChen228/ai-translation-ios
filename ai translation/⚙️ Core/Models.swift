// Models.swift

import Foundation

// 單一一題的結構
struct Question: Codable, Identifiable {
    let id = UUID()
    let new_sentence: String
    let type: String
    let hint_text: String?
    let knowledge_point_id: Int?
    let mastery_level: Double?

    private enum CodingKeys: String, CodingKey {
        case new_sentence, type, hint_text
        case knowledge_point_id, mastery_level
    }
}

// 整個 API 回應的結構
struct QuestionsResponse: Codable {
    let questions: [Question]
}

struct ErrorAnalysis: Codable, Identifiable {
    let id = UUID()
    let error_type: String
    let error_subtype: String
    let original_phrase: String
    let correction: String
    let explanation: String
    let severity: String

    private enum CodingKeys: String, CodingKey {
        case error_type, error_subtype, original_phrase, correction, explanation, severity
    }
}

// 用來定義整個 AI 點評回傳的結構
struct FeedbackResponse: Codable {
    let is_generally_correct: Bool
    let overall_suggestion: String
    let error_analysis: [ErrorAnalysis]
}

// 用來定義儀表板中，單一知識點的結構
struct KnowledgePoint: Codable, Identifiable {
    let identifiableId = UUID() // 用於 SwiftUI 的 Identifiable 協議
    let id: Int // 【新增】資料庫中的 Primary Key
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
    let is_archived: Bool? // 【新增】

    // 【修改】更新 CodingKeys 以對應新的欄位
    private enum CodingKeys: String, CodingKey {
        case id, category, subcategory, correct_phrase, explanation
        case user_context_sentence, incorrect_phrase_in_context
        case key_point_summary, mastery_level, mistake_count, correct_count
        case next_review_date, is_archived
    }
}

// 用來定義整個儀表板 API 回應的結構
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

// 用來定義整個單字卡 API 回應的結構
struct FlashcardsResponse: Codable {
    let flashcards: [Flashcard]
}

// 用於解析單日詳情 API 回應的結構
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
