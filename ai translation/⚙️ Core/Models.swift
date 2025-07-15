// ContentView.swift (要被剪下的部分)
import Foundation
// 單一一題的結構
struct Question: Codable, Identifiable {
    let id = UUID() // 這個屬性讓 SwiftUI 的 List 可以辨識每一題
    let new_sentence: String
    let type: String

    // 我們需要自訂 CodingKeys 來告訴解碼器，JSON 中只有以下這些 key
    private enum CodingKeys: String, CodingKey {
        case new_sentence, type
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

    // 自訂 CodingKeys，因為 JSON key 跟我們的變數名一樣
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
    let id = UUID()
    let category: String
    let subcategory: String
    let correct_phrase: String
    let explanation: String?
    let user_context_sentence: String?
    let incorrect_phrase_in_context: String?
    let key_point_summary: String? // 新增
    let mastery_level: Double
    let mistake_count: Int
    let correct_count: Int
    
    private enum CodingKeys: String, CodingKey {
        case category, subcategory, correct_phrase, explanation
        case user_context_sentence, incorrect_phrase_in_context
        case key_point_summary // 新增
        case mastery_level, mistake_count, correct_count
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
    
    // 告訴解碼器 JSON 中的 key 和我們變數的對應關係
    private enum CodingKeys: String, CodingKey {
        case front, back_correction, back_explanation, category
    }
}

// 用來定義整個單字卡 API 回應的結構
struct FlashcardsResponse: Codable {
    let flashcards: [Flashcard]
}
