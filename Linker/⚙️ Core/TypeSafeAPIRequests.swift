// TypeSafeAPIRequests.swift - 型別安全的 API 請求結構

import Foundation

// MARK: - 型別安全的更新請求
struct UpdateKnowledgePointRequest: Codable {
    let masteryLevel: Double?
    let notes: String?
    let isArchived: Bool?
    let category: String?
    let subcategory: String?
    
    init(
        masteryLevel: Double? = nil,
        notes: String? = nil,
        isArchived: Bool? = nil,
        category: String? = nil,
        subcategory: String? = nil
    ) {
        self.masteryLevel = masteryLevel
        self.notes = notes
        self.isArchived = isArchived
        self.category = category
        self.subcategory = subcategory
    }
    
    private enum CodingKeys: String, CodingKey {
        case masteryLevel = "mastery_level"
        case notes
        case isArchived = "is_archived"
        case category
        case subcategory
    }
}

// MARK: - 型別安全的 AI 審閱請求
struct AIReviewRequest: Codable {
    let modelName: String?
    let reviewType: ReviewType
    let options: ReviewOptions?
    
    enum ReviewType: String, Codable {
        case quick = "quick"
        case detailed = "detailed"
        case comprehensive = "comprehensive"
    }
    
    struct ReviewOptions: Codable {
        let includeExamples: Bool
        let focusAreas: [String]
        let difficultyLevel: String?
        
        private enum CodingKeys: String, CodingKey {
            case includeExamples = "include_examples"
            case focusAreas = "focus_areas"
            case difficultyLevel = "difficulty_level"
        }
    }
    
    init(
        modelName: String? = nil,
        reviewType: ReviewType = .quick,
        options: ReviewOptions? = nil
    ) {
        self.modelName = modelName
        self.reviewType = reviewType
        self.options = options
    }
    
    private enum CodingKeys: String, CodingKey {
        case modelName = "model_name"
        case reviewType = "review_type"
        case options
    }
}

// MARK: - 型別安全的批次操作請求
struct BatchOperationRequest: Codable {
    let action: BatchAction
    let ids: [Int]
    let options: BatchOptions?
    
    enum BatchAction: String, Codable {
        case archive = "archive"
        case unarchive = "unarchive"
        case delete = "delete"
        case updateCategory = "update_category"
        case updateMastery = "update_mastery"
    }
    
    struct BatchOptions: Codable {
        let newCategory: String?
        let newMasteryLevel: Double?
        let reason: String?
        
        private enum CodingKeys: String, CodingKey {
            case newCategory = "new_category"
            case newMasteryLevel = "new_mastery_level"
            case reason
        }
    }
    
    init(
        action: BatchAction,
        ids: [Int],
        options: BatchOptions? = nil
    ) {
        self.action = action
        self.ids = ids
        self.options = options
    }
}

// MARK: - 型別安全的搜尋請求
struct SearchKnowledgePointsRequest: Codable {
    let query: String?
    let category: String?
    let subcategory: String?
    let masteryRange: MasteryRange?
    let sortBy: SortOption
    let sortOrder: SortOrder
    let limit: Int
    let offset: Int
    
    struct MasteryRange: Codable {
        let min: Double
        let max: Double
    }
    
    enum SortOption: String, Codable {
        case createdDate = "created_date"
        case masteryLevel = "mastery_level"
        case category = "category"
        case mistakeCount = "mistake_count"
        case lastReviewDate = "last_review_date"
    }
    
    enum SortOrder: String, Codable {
        case ascending = "asc"
        case descending = "desc"
    }
    
    init(
        query: String? = nil,
        category: String? = nil,
        subcategory: String? = nil,
        masteryRange: MasteryRange? = nil,
        sortBy: SortOption = .createdDate,
        sortOrder: SortOrder = .descending,
        limit: Int = 20,
        offset: Int = 0
    ) {
        self.query = query
        self.category = category
        self.subcategory = subcategory
        self.masteryRange = masteryRange
        self.sortBy = sortBy
        self.sortOrder = sortOrder
        self.limit = limit
        self.offset = offset
    }
    
    private enum CodingKeys: String, CodingKey {
        case query
        case category
        case subcategory
        case masteryRange = "mastery_range"
        case sortBy = "sort_by"
        case sortOrder = "sort_order"
        case limit
        case offset
    }
}

// MARK: - 型別安全的學習統計請求
struct LearningStatsRequest: Codable {
    let startDate: String
    let endDate: String
    let granularity: Granularity
    let includeCategories: Bool
    let includeTrends: Bool
    
    enum Granularity: String, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
    }
    
    init(
        startDate: String,
        endDate: String,
        granularity: Granularity = .daily,
        includeCategories: Bool = true,
        includeTrends: Bool = true
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.granularity = granularity
        self.includeCategories = includeCategories
        self.includeTrends = includeTrends
    }
    
    private enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case endDate = "end_date"
        case granularity
        case includeCategories = "include_categories"
        case includeTrends = "include_trends"
    }
}

// MARK: - 型別安全的問題生成請求
struct GenerateQuestionsRequest: Codable {
    let count: Int
    let difficulty: QuestionDifficulty
    let types: [QuestionType]
    let categories: [String]?
    let excludeRecentlyAnswered: Bool
    
    enum QuestionDifficulty: String, Codable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case mixed = "mixed"
    }
    
    enum QuestionType: String, Codable {
        case translation = "translation"
        case correction = "correction"
        case completion = "completion"
        case choice = "choice"
        case review = "review"
    }
    
    init(
        count: Int = 5,
        difficulty: QuestionDifficulty = .mixed,
        types: [QuestionType] = [.translation, .correction],
        categories: [String]? = nil,
        excludeRecentlyAnswered: Bool = true
    ) {
        self.count = count
        self.difficulty = difficulty
        self.types = types
        self.categories = categories
        self.excludeRecentlyAnswered = excludeRecentlyAnswered
    }
    
    private enum CodingKeys: String, CodingKey {
        case count
        case difficulty
        case types
        case categories
        case excludeRecentlyAnswered = "exclude_recently_answered"
    }
}

// MARK: - 型別安全的答案提交請求
struct SubmitAnswerRequest: Codable {
    let questionId: String
    let userAnswer: String
    let timeSpent: TimeInterval
    let questionData: QuestionData
    let context: AnswerContext?
    
    struct QuestionData: Codable {
        let sentence: String
        let type: String
        let hint: String?
        let knowledgePointId: Int?
        
        private enum CodingKeys: String, CodingKey {
            case sentence = "new_sentence"
            case type
            case hint = "hint_text"
            case knowledgePointId = "knowledge_point_id"
        }
    }
    
    struct AnswerContext: Codable {
        let sessionId: String
        let attemptNumber: Int
        let usedHints: [String]
        let confidence: Double?
        
        private enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
            case attemptNumber = "attempt_number"
            case usedHints = "used_hints"
            case confidence
        }
    }
    
    init(
        questionId: String,
        userAnswer: String,
        timeSpent: TimeInterval,
        questionData: QuestionData,
        context: AnswerContext? = nil
    ) {
        self.questionId = questionId
        self.userAnswer = userAnswer
        self.timeSpent = timeSpent
        self.questionData = questionData
        self.context = context
    }
    
    private enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case userAnswer = "user_answer"
        case timeSpent = "time_spent"
        case questionData = "question_data"
        case context
    }
}

// MARK: - API 請求建構器
struct APIRequestBuilder {
    
    /// 建構更新知識點請求
    static func updateKnowledgePoint(
        masteryLevel: Double? = nil,
        notes: String? = nil,
        isArchived: Bool? = nil,
        category: String? = nil,
        subcategory: String? = nil
    ) -> UpdateKnowledgePointRequest {
        return UpdateKnowledgePointRequest(
            masteryLevel: masteryLevel,
            notes: notes,
            isArchived: isArchived,
            category: category,
            subcategory: subcategory
        )
    }
    
    /// 建構 AI 審閱請求
    static func aiReview(
        modelName: String? = nil,
        reviewType: AIReviewRequest.ReviewType = .quick,
        includeExamples: Bool = true,
        focusAreas: [String] = [],
        difficultyLevel: String? = nil
    ) -> AIReviewRequest {
        let options = AIReviewRequest.ReviewOptions(
            includeExamples: includeExamples,
            focusAreas: focusAreas,
            difficultyLevel: difficultyLevel
        )
        
        return AIReviewRequest(
            modelName: modelName,
            reviewType: reviewType,
            options: options
        )
    }
    
    /// 建構批次操作請求
    static func batchOperation(
        action: BatchOperationRequest.BatchAction,
        ids: [Int],
        newCategory: String? = nil,
        newMasteryLevel: Double? = nil,
        reason: String? = nil
    ) -> BatchOperationRequest {
        let options = BatchOperationRequest.BatchOptions(
            newCategory: newCategory,
            newMasteryLevel: newMasteryLevel,
            reason: reason
        )
        
        return BatchOperationRequest(
            action: action,
            ids: ids,
            options: options
        )
    }
}

// MARK: - 請求驗證
extension UpdateKnowledgePointRequest {
    func validate() throws {
        if let masteryLevel = masteryLevel {
            guard masteryLevel >= 0.0 && masteryLevel <= 1.0 else {
                throw ValidationError.invalidMasteryLevel
            }
        }
        
        if let notes = notes {
            guard !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ValidationError.emptyNotes
            }
        }
    }
}

extension BatchOperationRequest {
    func validate() throws {
        guard !ids.isEmpty else {
            throw ValidationError.emptyIds
        }
        
        guard ids.count <= 100 else {
            throw ValidationError.tooManyIds
        }
        
        if action == .updateMastery, let masteryLevel = options?.newMasteryLevel {
            guard masteryLevel >= 0.0 && masteryLevel <= 1.0 else {
                throw ValidationError.invalidMasteryLevel
            }
        }
    }
}

// MARK: - 驗證錯誤（已移至DataModelProtocols.swift統一定義）
// 使用新的ValidationError結構