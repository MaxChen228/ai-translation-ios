// DataModelProtocols.swift - 統一的資料模型協議
// 提供一致的資料模型基礎介面和通用功能

import Foundation
import SwiftUI

// MARK: - 基礎協議

/// 所有資料模型的基礎協議
protocol DataModel: Codable, Identifiable where ID: Hashable {
}

/// 可時間戳記的資料模型
protocol TimestampedModel: DataModel {
    var createdAt: String { get }
    var updatedAt: String? { get }
    
    /// 格式化的創建時間
    var formattedCreatedAt: String { get }
    /// 格式化的更新時間
    var formattedUpdatedAt: String? { get }
}

/// 可歸檔的資料模型
protocol ArchivableModel: DataModel {
    var isArchived: Bool { get }
}

/// 具有統計數據的資料模型
protocol StatisticalModel: DataModel {
    var totalCount: Int { get }
    var completedCount: Int { get }
    var progressPercentage: Double { get }
}

/// 具有掌握程度的資料模型
protocol MasteryModel: DataModel {
    var masteryLevel: Double { get }
    var masteryStatus: MasteryLevel { get }
}

/// 具有難度等級的資料模型
protocol DifficultyModel: DataModel {
    var difficultyLevel: Int { get }
    var difficultyColor: Color { get }
    var difficultyDisplayName: String { get }
}

// MARK: - 學習相關協議

/// 可學習的項目
protocol LearnableItem: DataModel, MasteryModel, TimestampedModel {
    var totalReviews: Int { get }
    var correctReviews: Int { get }
    var lastReviewedAt: String? { get }
    var nextReviewAt: String? { get }
    
    /// 準確率
    var accuracyRate: Double { get }
    /// 是否需要複習
    var isDueForReview: Bool { get }
}

/// 可練習的項目
protocol PracticableItem: LearnableItem {
    var practiceType: PracticeType { get }
}

/// 具有範例的模型
protocol ExampleModel: DataModel {
    associatedtype ExampleType: DataModel
    var examples: [ExampleType]? { get }
}

// MARK: - API 回應協議

/// 統一的API回應格式
protocol APIResponse: Codable {
    associatedtype DataType: Codable
    var success: Bool { get }
    var data: DataType { get }
    var message: String { get }
    var timestamp: String? { get }
}

/// 分頁回應協議
protocol PaginatedResponse: APIResponse {
    var pagination: PaginationInfo { get }
}

/// 統計回應協議
protocol StatisticsResponse: APIResponse where DataType: StatisticalModel {
    var summary: StatisticsSummary { get }
}

// MARK: - 通用資料結構

/// 掌握程度等級
enum MasteryLevel: String, CaseIterable, Codable {
    case new = "new"
    case learning = "learning"
    case reviewing = "reviewing"
    case mastered = "mastered"
    
    var displayName: String {
        switch self {
        case .new: return "新項目"
        case .learning: return "學習中"
        case .reviewing: return "複習中"
        case .mastered: return "已掌握"
        }
    }
    
    var color: Color {
        switch self {
        case .new: return .blue
        case .learning: return .orange
        case .reviewing: return .yellow
        case .mastered: return .green
        }
    }
    
    var systemImageName: String {
        switch self {
        case .new: return "plus.circle"
        case .learning: return "clock.circle"
        case .reviewing: return "arrow.clockwise.circle"
        case .mastered: return "checkmark.circle"
        }
    }
    
    /// 從數值轉換掌握程度
    static func fromLevel(_ level: Double) -> MasteryLevel {
        switch level {
        case 0: return .new
        case 0.1..<2.0: return .learning
        case 2.0..<4.0: return .reviewing
        case 4.0...: return .mastered
        default: return .new
        }
    }
}

/// 練習類型
enum PracticeType: String, CaseIterable, Codable {
    case flashcard = "flashcard"
    case multipleChoice = "multiple_choice"
    case contextFill = "context_fill"
    case pronunciation = "pronunciation"
    case writing = "writing"
    
    var displayName: String {
        switch self {
        case .flashcard: return "翻卡練習"
        case .multipleChoice: return "選擇題"
        case .contextFill: return "語境填空"
        case .pronunciation: return "發音練習"
        case .writing: return "拼寫練習"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .flashcard: return "rectangle.stack"
        case .multipleChoice: return "checklist"
        case .contextFill: return "text.bubble"
        case .pronunciation: return "speaker.wave.2"
        case .writing: return "pencil"
        }
    }
}

/// 分頁資訊
struct PaginationInfo: Codable {
    let currentPage: Int
    let pageSize: Int
    let totalCount: Int
    let totalPages: Int
    let hasNextPage: Bool
    let hasPreviousPage: Bool
    
    private enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case pageSize = "page_size"
        case totalCount = "total_count"
        case totalPages = "total_pages"
        case hasNextPage = "has_next_page"
        case hasPreviousPage = "has_previous_page"
    }
    
    init(currentPage: Int, pageSize: Int, totalCount: Int) {
        self.currentPage = currentPage
        self.pageSize = pageSize
        self.totalCount = totalCount
        self.totalPages = max(1, Int(ceil(Double(totalCount) / Double(pageSize))))
        self.hasNextPage = currentPage < totalPages
        self.hasPreviousPage = currentPage > 1
    }
}

/// 統計摘要
struct StatisticsSummary: Codable {
    let totalItems: Int
    let activeItems: Int
    let completedItems: Int
    let averageProgress: Double
    let lastUpdatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case totalItems = "total_items"
        case activeItems = "active_items"
        case completedItems = "completed_items"
        case averageProgress = "average_progress"
        case lastUpdatedAt = "last_updated_at"
    }
    
    var completionRate: Double {
        guard totalItems > 0 else { return 0.0 }
        return Double(completedItems) / Double(totalItems) * 100
    }
}

/// 通用的API錯誤
struct APIErrorDetails: Codable {
    let code: String
    let message: String
    let details: [String: String]?
    let timestamp: String
    
    init(code: String, message: String, details: [String: String]? = nil) {
        self.code = code
        self.message = message
        self.details = details
        self.timestamp = ISO8601DateFormatter().string(from: Date())
    }
}

// MARK: - 預設實現

extension TimestampedModel {
    var formattedCreatedAt: String {
        return DateFormatter.displayFormatter.string(from: DateFormatter.iso8601Formatter.date(from: createdAt) ?? Date())
    }
    
    var formattedUpdatedAt: String? {
        guard let updatedAt = updatedAt else { return nil }
        return DateFormatter.displayFormatter.string(from: DateFormatter.iso8601Formatter.date(from: updatedAt) ?? Date())
    }
}

extension LearnableItem {
    var accuracyRate: Double {
        guard totalReviews > 0 else { return 0.0 }
        return Double(correctReviews) / Double(totalReviews) * 100
    }
    
    var isDueForReview: Bool {
        guard let nextReviewAt = nextReviewAt else { return false }
        let reviewDate = DateFormatter.iso8601Formatter.date(from: nextReviewAt) ?? Date.distantFuture
        return Date() >= reviewDate
    }
    
    var masteryStatus: MasteryLevel {
        return MasteryLevel.fromLevel(masteryLevel)
    }
}

extension DifficultyModel {
    var difficultyColor: Color {
        switch difficultyLevel {
        case 1: return .green
        case 2: return .mint
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }
    
    var difficultyDisplayName: String {
        switch difficultyLevel {
        case 1: return "簡單"
        case 2: return "容易"
        case 3: return "中等"
        case 4: return "困難"
        case 5: return "很難"
        default: return "未知"
        }
    }
}

extension StatisticalModel {
    var progressPercentage: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(completedCount) / Double(totalCount) * 100
    }
}

// MARK: - 日期處理擴展

extension DateFormatter {
    static let iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }()
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }()
}

// MARK: - 通用包裝器

/// 通用的API回應包裝器
struct StandardAPIResponse<T: Codable>: APIResponse {
    let success: Bool
    let data: T
    let message: String
    let timestamp: String?
    let error: APIErrorDetails?
    
    init(success: Bool, data: T, message: String = "", error: APIErrorDetails? = nil) {
        self.success = success
        self.data = data
        self.message = message
        self.timestamp = ISO8601DateFormatter().string(from: Date())
        self.error = error
    }
}

/// 分頁回應包裝器
struct PaginatedAPIResponse<T: Codable>: PaginatedResponse {
    let success: Bool
    let data: T
    let message: String
    let timestamp: String?
    let pagination: PaginationInfo
    
    init(success: Bool, data: T, pagination: PaginationInfo, message: String = "") {
        self.success = success
        self.data = data
        self.message = message
        self.pagination = pagination
        self.timestamp = ISO8601DateFormatter().string(from: Date())
    }
}

/// 統計回應包裝器
struct StatisticsAPIResponse<T: StatisticalModel>: StatisticsResponse {
    let success: Bool
    let data: T
    let message: String
    let timestamp: String?
    let summary: StatisticsSummary
    
    init(success: Bool, data: T, summary: StatisticsSummary, message: String = "") {
        self.success = success
        self.data = data
        self.message = message
        self.summary = summary
        self.timestamp = ISO8601DateFormatter().string(from: Date())
    }
}

// MARK: - 模型驗證協議

/// 可驗證的資料模型
protocol ValidatableModel: DataModel {
    func validate() -> ValidationResult
}

/// 驗證結果
struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    
    static let valid = ValidationResult(isValid: true, errors: [])
    
    init(isValid: Bool, errors: [ValidationError] = []) {
        self.isValid = isValid
        self.errors = errors
    }
}

/// 驗證錯誤
struct ValidationError: Error, LocalizedError {
    let field: String
    let message: String
    let code: String
    
    init(field: String, message: String, code: String = "VALIDATION_ERROR") {
        self.field = field
        self.message = message
        self.code = code
    }
    
    var errorDescription: String? {
        return message
    }
    
    // 支援舊版本的靜態錯誤類型
    static let invalidMasteryLevel = ValidationError(
        field: "masteryLevel",
        message: "熟練度必須在 0.0 到 1.0 之間",
        code: "INVALID_MASTERY_LEVEL"
    )
    
    static let emptyNotes = ValidationError(
        field: "notes",
        message: "備註不能為空",
        code: "EMPTY_NOTES"
    )
    
    static let emptyIds = ValidationError(
        field: "ids",
        message: "ID 列表不能為空",
        code: "EMPTY_IDS"
    )
    
    static let tooManyIds = ValidationError(
        field: "ids",
        message: "一次最多只能處理 100 個項目",
        code: "TOO_MANY_IDS"
    )
    
    static let invalidTimeRange = ValidationError(
        field: "timeRange",
        message: "時間範圍無效",
        code: "INVALID_TIME_RANGE"
    )
}

// MARK: - 搜尋相關協議

/// 可搜尋的資料模型
protocol SearchableModel: DataModel {
    /// 搜尋關鍵字
    var searchKeywords: [String] { get }
    /// 搜尋相關性分數
    func searchRelevance(for query: String) -> Double
}

extension SearchableModel {
    func searchRelevance(for query: String) -> Double {
        let lowercaseQuery = query.lowercased()
        var score: Double = 0
        
        for keyword in searchKeywords {
            let lowercaseKeyword = keyword.lowercased()
            if lowercaseKeyword == lowercaseQuery {
                score += 100 // 完全匹配
            } else if lowercaseKeyword.contains(lowercaseQuery) {
                score += 50 // 部分匹配
            } else if lowercaseKeyword.hasPrefix(lowercaseQuery) {
                score += 75 // 前綴匹配
            }
        }
        
        return score / Double(searchKeywords.count)
    }
}