// Models.swift

import Foundation
import SwiftUI // 為了 Color

// 單一一題的結構 (不變)
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

// 整個 API 回應的結構 (不變)
struct QuestionsResponse: Codable {
    let questions: [Question]
}


// --- 【計畫一修改】更新 ErrorAnalysis 的結構 ---
struct ErrorAnalysis: Codable, Identifiable {
    let id = UUID()
    // 移除了 error_type 和 error_subtype，換成新的代碼
    let error_type_code: String
    let key_point_summary: String
    let original_phrase: String
    let correction: String
    let explanation: String
    let severity: String

    // 對應新的 JSON key
    private enum CodingKeys: String, CodingKey {
        case error_type_code, key_point_summary, original_phrase, correction, explanation, severity
    }

    // 【新增】輔助屬性，用於在 UI 中顯示對應的完整文字
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
    
    // 【新增】輔助屬性，用於在 UI 中顯示對應的 SF Symbol 圖示
    var categoryIcon: String {
        switch error_type_code {
        case "A": return "text.book.closed.fill"
        case "B": return "sitemap.fill"
        case "C": return "bubble.left.and.bubble.right.fill"
        case "D": return "textformat"
        default: return "exclamationmark.triangle.fill"
        }
    }
    
    // 【新增】輔助屬性，用於在 UI 中顯示對應的顏色
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

// 用來定義整個 AI 點評回傳的結構 (不變)
struct FeedbackResponse: Codable {
    let is_generally_correct: Bool
    let overall_suggestion: String
    let error_analysis: [ErrorAnalysis]
    let did_master_review_concept: Bool? // 複習題才會有
}


// --- 其他 Models (不變) ---

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

    private enum CodingKeys: String, CodingKey {
        case id, category, subcategory, correct_phrase, explanation, user_context_sentence, incorrect_phrase_in_context, key_point_summary, mastery_level, mistake_count, correct_count, next_review_date, is_archived
    }
}

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
