//
//  MultiClassificationModels.swift
//  ai translation
//
//  多分類單字系統資料模型
//

import Foundation
import SwiftUI

// MARK: - 分類系統

struct ClassificationSystem: Codable, Identifiable, Hashable {
    let systemId: Int
    let systemName: String
    let systemCode: String
    let description: String
    let categories: [String]
    let totalWords: Int
    let enrichedWords: Int
    let displayOrder: Int?
    
    var id: Int { systemId }
    
    private enum CodingKeys: String, CodingKey {
        case systemId = "system_id"
        case systemName = "system_name"
        case systemCode = "system_code"
        case description
        case categories
        case totalWords = "total_words"
        case enrichedWords = "enriched_words"
        case displayOrder = "display_order"
    }
    
    // 計算屬性
    var enrichedPercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(enrichedWords) / Double(totalWords) * 100
    }
    
    var progressText: String {
        "\(enrichedWords)/\(totalWords)"
    }
    
    var percentageText: String {
        String(format: "%.1f%%", enrichedPercentage)
    }
    
    // 系統圖標
    var iconName: String {
        switch systemCode {
        case "LEVEL":
            return "book.fill"
        case "CEFR":
            return "globe"
        case "TOEIC":
            return "briefcase.fill"
        case "TOEFL":
            return "graduationcap.fill"
        case "IELTS":
            return "flag.fill"
        default:
            return "text.book.closed"
        }
    }
    
    // 系統顏色
    var themeColor: Color {
        switch systemCode {
        case "LEVEL":
            return .blue
        case "CEFR":
            return .green
        case "TOEIC":
            return .red
        case "TOEFL":
            return .orange
        case "IELTS":
            return .purple
        default:
            return .gray
        }
    }
}

// MARK: - 分類統計

struct CategoryStats: Codable {
    let wordCount: Int
    let enrichedCount: Int
    let enrichedPercentage: Double
    let avgQuality: Double
    
    private enum CodingKeys: String, CodingKey {
        case wordCount = "word_count"
        case enrichedCount = "enriched_count"
        case enrichedPercentage = "enriched_percentage"
        case avgQuality = "avg_quality"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wordCount = try container.decode(Int.self, forKey: .wordCount)
        enrichedCount = try container.decode(Int.self, forKey: .enrichedCount)
        enrichedPercentage = try container.decode(Double.self, forKey: .enrichedPercentage)
        
        // 處理 avgQuality 可能是字符串或數字的情況
        if let doubleValue = try? container.decode(Double.self, forKey: .avgQuality) {
            avgQuality = doubleValue
        } else if let stringValue = try? container.decode(String.self, forKey: .avgQuality),
                  let doubleValue = Double(stringValue) {
            avgQuality = doubleValue
        } else {
            avgQuality = 0.0
        }
    }
}

// MARK: - 系統分類資訊

struct SystemCategoryInfo: Codable {
    let systemName: String
    let systemCode: String
    let availableCategories: [String]
    let categoryStats: [String: CategoryStats]
    
    private enum CodingKeys: String, CodingKey {
        case systemName = "system_name"
        case systemCode = "system_code"
        case availableCategories = "available_categories"
        case categoryStats = "category_stats"
    }
}

// MARK: - 多分類單字

struct MultiClassWord: Codable, Identifiable {
    let wordId: Int
    let word: String
    let pronunciation: String?
    let partOfSpeech: String?
    let isEnriched: Bool
    let qualityScore: Int
    let enrichedAt: String?
    
    var id: Int { wordId }
    
    private enum CodingKeys: String, CodingKey {
        case wordId = "word_id"
        case word
        case pronunciation
        case partOfSpeech = "part_of_speech"
        case isEnriched = "is_enriched"
        case qualityScore = "quality_score"
        case enrichedAt = "enriched_at"
    }
    
    // UI 狀態圖標
    var statusIcon: String {
        isEnriched ? "star.fill" : "star"
    }
    
    var statusColor: Color {
        isEnriched ? .yellow : .gray
    }
}

// MARK: - 單字分類標籤

struct WordClassification: Codable {
    let systemName: String
    let systemCode: String
    let category: String
    let confidenceScore: Int
    
    private enum CodingKeys: String, CodingKey {
        case systemName = "system_name"
        case systemCode = "system_code"
        case category
        case confidenceScore = "confidence_score"
    }
    
    var displayText: String {
        "\(systemCode) \(category)"
    }
}

// MARK: - 單字詳細資訊

struct MultiClassWordDetail: Codable {
    let wordId: Int
    let word: String
    let isEnriched: Bool
    let classifications: [WordClassification]
    let basicInfo: BasicWordInfo
    let enrichedInfo: EnrichedWordInfo?
    
    private enum CodingKeys: String, CodingKey {
        case wordId = "word_id"
        case word
        case isEnriched = "is_enriched"
        case classifications
        case basicInfo = "basic_info"
        case enrichedInfo = "enriched_info"
    }
}

struct BasicWordInfo: Codable {
    let word: String
    let classifications: [WordClassification]
}

struct EnrichedWordInfo: Codable {
    let pronunciation: String
    let partOfSpeech: String
    let definitions: [String]
    let etymology: String?
    let synonyms: [String]
    let antonyms: [String]
    let audioUrls: [String]
    let qualityScore: Int
    let source: String
    let enrichedAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case pronunciation
        case partOfSpeech = "part_of_speech"
        case definitions
        case etymology
        case synonyms
        case antonyms
        case audioUrls = "audio_urls"
        case qualityScore = "quality_score"
        case source
        case enrichedAt = "enriched_at"
    }
}

// MARK: - 字母分布

struct AlphabetDistribution {
    let letter: String
    let count: Int
    
    var isActive: Bool {
        count > 0
    }
}

// MARK: - API 回應結構

struct SystemsResponse: Codable {
    let success: Bool
    let data: SystemsData
    let message: String
}

struct SystemsData: Codable {
    let systems: [ClassificationSystem]
    let totalSystems: Int
    
    private enum CodingKeys: String, CodingKey {
        case systems
        case totalSystems = "total_systems"
    }
}

struct CategoryInfoResponse: Codable {
    let success: Bool
    let data: SystemCategoryInfo
    let message: String
}

struct WordsResponse: Codable {
    let success: Bool
    let data: WordsData
    let message: String
}

struct WordsData: Codable {
    let words: [MultiClassWord]
    let pagination: Pagination
    let filter: WordFilter
}

struct Pagination: Codable {
    let currentPage: Int
    let pageSize: Int
    let totalCount: Int
    let totalPages: Int
    
    private enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case pageSize = "page_size"
        case totalCount = "total_count"
        case totalPages = "total_pages"
    }
}

struct WordFilter: Codable {
    let systemCode: String
    let category: String
    let letter: String?
    
    private enum CodingKeys: String, CodingKey {
        case systemCode = "system_code"
        case category
        case letter
    }
}

struct AlphabetResponse: Codable {
    let success: Bool
    let data: AlphabetData
    let message: String
}

struct AlphabetData: Codable {
    let systemCode: String
    let category: String
    let alphabetDistribution: [String: Int]
    let activeLetters: [String: Int]
    let totalLetters: Int
    let totalWords: Int
    
    private enum CodingKeys: String, CodingKey {
        case systemCode = "system_code"
        case category
        case alphabetDistribution = "alphabet_distribution"
        case activeLetters = "active_letters"
        case totalLetters = "total_letters"
        case totalWords = "total_words"
    }
    
    // 轉換為排序陣列
    var sortedLetters: [(letter: String, count: Int)] {
        activeLetters.map { (letter: $0.key, count: $0.value) }
            .sorted { $0.letter < $1.letter }
    }
}

struct WordDetailResponse: Codable {
    let success: Bool
    let data: MultiClassWordDetail
    let message: String
}

// MARK: - UI 輔助

extension MultiClassWord {
    // 類別標籤樣式
    func categoryBadgeColor(for systemCode: String) -> Color {
        switch systemCode {
        case "LEVEL": return .blue
        case "CEFR": return .green
        default: return .gray
        }
    }
}

// MARK: - 分類級別顯示

extension String {
    func categoryDisplayName(for systemCode: String) -> String {
        switch systemCode {
        case "LEVEL":
            return "Level \(self)"
        case "CEFR":
            return self
        default:
            return self
        }
    }
    
    func categoryEmoji(for systemCode: String) -> String {
        switch systemCode {
        case "LEVEL":
            switch self {
            case "1": return "🌱"
            case "2": return "🌿"
            case "3": return "🌳"
            case "4": return "🌲"
            case "5": return "🏔"
            case "6": return "🌟"
            default: return "📚"
            }
        case "CEFR":
            switch self {
            case "A1": return "🔰"
            case "A2": return "🟢"
            case "B1": return "🟡"
            case "B2": return "🟠"
            case "C1": return "🔴"
            case "C2": return "🟣"
            default: return "🌍"
            }
        default:
            return "📖"
        }
    }
}