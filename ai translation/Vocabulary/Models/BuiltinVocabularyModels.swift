// BuiltinVocabularyModels.swift
// 內建單字庫相關資料模型

import Foundation

// MARK: - 內建單字分類

struct BuiltinCategory: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let nameZh: String
    let description: String?
    let icon: String?
    let displayOrder: Int
    let isActive: Bool
    let wordCount: Int
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, icon
        case nameZh = "name_zh"
        case displayOrder = "display_order"
        case isActive = "is_active"
        case wordCount = "word_count"
        case createdAt = "created_at"
    }
}

// MARK: - 內建單字

struct BuiltinWord: Codable, Identifiable {
    let id: Int
    let word: String
    let categoryId: Int
    let difficultyLevel: Int
    let frequencyRank: Int?
    let cefrLevel: String?
    let isCached: Bool
    let viewCount: Int
    let createdAt: String
    let updatedAt: String
    
    // 關聯資料
    let categoryName: String?
    let categoryNameZh: String?
    let categoryIcon: String?
    
    enum CodingKeys: String, CodingKey {
        case id, word
        case categoryId = "category_id"
        case difficultyLevel = "difficulty_level"
        case frequencyRank = "frequency_rank"
        case cefrLevel = "cefr_level"
        case isCached = "is_cached"
        case viewCount = "view_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case categoryName = "category_name"
        case categoryNameZh = "category_name_zh"
        case categoryIcon = "category_icon"
    }
    
    // 計算屬性
    var difficultyStars: String {
        String(repeating: "★", count: difficultyLevel)
    }
    
    var difficultyDescription: String {
        switch difficultyLevel {
        case 1: return "初級"
        case 2: return "初中級"
        case 3: return "中級"
        case 4: return "中高級"
        case 5: return "高級"
        default: return "未分級"
        }
    }
    
    var cefrLevelColor: String {
        switch cefrLevel {
        case "A1", "A2": return "green"
        case "B1", "B2": return "orange"
        case "C1", "C2": return "red"
        default: return "gray"
        }
    }
}

// MARK: - Merriam-Webster 字典資料

struct MerriamWebsterWord: Codable {
    let success: Bool
    let word: String
    let pronunciation: String?
    let partOfSpeech: String?
    let definitions: [String]
    let etymology: String?
    let synonyms: [String]
    let antonyms: [String]
    let audioUrls: [String]
    let fromCache: Bool
    let definitionZh: String?
    let suggestions: [String]?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success, word, pronunciation, definitions, etymology, synonyms, antonyms, message, suggestions
        case partOfSpeech = "part_of_speech"
        case audioUrls = "audio_urls"
        case fromCache = "from_cache"
        case definitionZh = "definition_zh"
    }
}

// MARK: - 單字詳情組合資料

struct BuiltinWordDetail: Codable {
    let success: Bool
    let wordInfo: BuiltinWord
    let dictionaryData: MerriamWebsterWord
    let timestamp: String
}

// MARK: - API 回應格式

struct BuiltinCategoriesResponse: Codable {
    let success: Bool
    let categories: [BuiltinCategory]
    let count: Int
    let error: String?
}

struct BuiltinWordsResponse: Codable {
    let success: Bool
    let words: [BuiltinWord]
    let totalCount: Int
    let page: Int
    let limit: Int
    let totalPages: Int
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success, words, page, limit, error
        case totalCount = "total_count"
        case totalPages = "total_pages"
    }
}

struct BuiltinWordDetailResponse: Codable {
    let success: Bool
    let wordInfo: BuiltinWord?
    let dictionaryData: MerriamWebsterWord?
    let timestamp: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success, timestamp, error
        case wordInfo = "word_info"
        case dictionaryData = "dictionary_data"
    }
}

struct AddToMyWordsResponse: Codable {
    let success: Bool
    let message: String?
    let vocabularyWordId: Int?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success, message, error
        case vocabularyWordId = "vocabulary_word_id"
    }
}

struct PopularWordsResponse: Codable {
    let success: Bool
    let words: [BuiltinWord]
    let count: Int
    let error: String?
}

struct RandomWordsResponse: Codable {
    let success: Bool
    let words: [BuiltinWord]
    let count: Int
    let error: String?
}

struct SearchWordsResponse: Codable {
    let success: Bool
    let query: String?
    let words: [BuiltinWord]
    let count: Int
    let error: String?
}

// MARK: - 請求參數模型

struct BuiltinWordsRequest {
    var categoryId: Int?
    var difficultyLevel: Int?
    var search: String?
    var page: Int = 1
    var limit: Int = 20
    
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        if let categoryId = categoryId {
            items.append(URLQueryItem(name: "category_id", value: String(categoryId)))
        }
        
        if let difficultyLevel = difficultyLevel {
            items.append(URLQueryItem(name: "difficulty_level", value: String(difficultyLevel)))
        }
        
        if let search = search, !search.isEmpty {
            items.append(URLQueryItem(name: "search", value: search))
        }
        
        items.append(URLQueryItem(name: "page", value: String(page)))
        items.append(URLQueryItem(name: "limit", value: String(limit)))
        
        return items
    }
}

struct AddToMyWordsRequest: Codable {
    let word: String
    let userId: Int
    
    enum CodingKeys: String, CodingKey {
        case word
        case userId = "user_id"
    }
}

// MARK: - UI 狀態管理

enum BuiltinVocabularyLoadingState {
    case idle
    case loading
    case loaded
    case error(String)
}

// MARK: - 篩選器

struct BuiltinVocabularyFilter {
    var selectedCategory: BuiltinCategory?
    var selectedDifficulty: Int?
    var selectedCEFR: String?
    var searchText: String = ""
    
    var isActive: Bool {
        selectedCategory != nil || selectedDifficulty != nil || selectedCEFR != nil || !searchText.isEmpty
    }
    
    mutating func reset() {
        selectedCategory = nil
        selectedDifficulty = nil
        selectedCEFR = nil
        searchText = ""
    }
}

// MARK: - 錯誤類型

enum BuiltinVocabularyError: LocalizedError {
    case networkError(String)
    case decodingError(String)
    case invalidResponse
    case wordNotFound
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "網路錯誤: \(message)"
        case .decodingError(let message):
            return "資料解析錯誤: \(message)"
        case .invalidResponse:
            return "無效的伺服器回應"
        case .wordNotFound:
            return "找不到指定的單字"
        case .apiKeyMissing:
            return "API 金鑰遺失"
        }
    }
}

// MARK: - 常數

enum BuiltinVocabularyConstants {
    static let defaultPageSize = 20
    static let maxPageSize = 100
    static let cacheExpiryHours = 24
    
    // CEFR 等級
    static let cefrLevels = ["A1", "A2", "B1", "B2", "C1", "C2"]
    
    // 難度等級
    static let difficultyLevels = [
        1: "初級",
        2: "初中級", 
        3: "中級",
        4: "中高級",
        5: "高級"
    ]
    
    // 音頻播放相關
    static let audioPlayerTimeoutSeconds: TimeInterval = 30
}

// MARK: - 擴展

extension BuiltinWord {
    var displayName: String {
        word.capitalized
    }
    
    var categoryDisplayName: String {
        categoryNameZh ?? categoryName ?? "未分類"
    }
    
    var hasAudio: Bool {
        // 假設大部分內建單字都有音頻
        return true
    }
}

extension MerriamWebsterWord {
    var hasValidData: Bool {
        success && !word.isEmpty && (!definitions.isEmpty || !synonyms.isEmpty)
    }
    
    var primaryDefinition: String? {
        definitions.first
    }
    
    var hasAudio: Bool {
        !audioUrls.isEmpty
    }
    
    var primaryAudioUrl: String? {
        audioUrls.first
    }
}

extension BuiltinCategory {
    var displayIcon: String {
        icon ?? "📚"
    }
    
    var isEmpty: Bool {
        wordCount == 0
    }
}