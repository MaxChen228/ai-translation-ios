// APIModels.swift - 強型別API數據模型
// 替換不安全的 [String: Any] 使用

import Foundation

// MARK: - 知識點更新模型
/// 知識點更新請求結構
struct KnowledgePointUpdateRequest: Codable {
    let masteryLevel: Double?
    let keyPointSummary: String?
    let explanation: String?
    let correctPhrase: String?
    let userContextSentence: String?
    let incorrectPhraseInContext: String?
    let category: String?
    let subcategory: String?
    let aiReviewNotes: String?
    let isArchived: Bool?
    
    /// 創建僅更新熟練度的請求
    static func masteryLevelUpdate(_ level: Double) -> KnowledgePointUpdateRequest {
        return KnowledgePointUpdateRequest(
            masteryLevel: level,
            keyPointSummary: nil,
            explanation: nil,
            correctPhrase: nil,
            userContextSentence: nil,
            incorrectPhraseInContext: nil,
            category: nil,
            subcategory: nil,
            aiReviewNotes: nil,
            isArchived: nil
        )
    }
    
    /// 創建歸檔狀態更新的請求
    static func archiveStatusUpdate(_ isArchived: Bool) -> KnowledgePointUpdateRequest {
        return KnowledgePointUpdateRequest(
            masteryLevel: nil,
            keyPointSummary: nil,
            explanation: nil,
            correctPhrase: nil,
            userContextSentence: nil,
            incorrectPhraseInContext: nil,
            category: nil,
            subcategory: nil,
            aiReviewNotes: nil,
            isArchived: isArchived
        )
    }
    
    /// 創建完整更新的請求
    static func fullUpdate(
        masteryLevel: Double? = nil,
        keyPointSummary: String? = nil,
        explanation: String? = nil,
        correctPhrase: String? = nil,
        userContextSentence: String? = nil,
        incorrectPhraseInContext: String? = nil,
        category: String? = nil,
        subcategory: String? = nil,
        aiReviewNotes: String? = nil,
        isArchived: Bool? = nil
    ) -> KnowledgePointUpdateRequest {
        return KnowledgePointUpdateRequest(
            masteryLevel: masteryLevel,
            keyPointSummary: keyPointSummary,
            explanation: explanation,
            correctPhrase: correctPhrase,
            userContextSentence: userContextSentence,
            incorrectPhraseInContext: incorrectPhraseInContext,
            category: category,
            subcategory: subcategory,
            aiReviewNotes: aiReviewNotes,
            isArchived: isArchived
        )
    }
}

// MARK: - 訪客問答模型
/// 訪客模式問題結構
struct GuestQuestion: Codable {
    let id: String
    let type: QuestionType
    let newSentence: String
    let hintText: String?
    let knowledgePointId: Int?
    let masteryLevel: Double?
    let expectedAnswer: String?
    let context: String?
    
    enum QuestionType: String, Codable {
        case translation = "translation"
        case fillInBlank = "fill_in_blank"
        case multipleChoice = "multiple_choice"
        case correction = "correction"
    }
}

/// 訪客答案提交請求
struct GuestAnswerSubmissionRequest: Codable {
    let question: GuestQuestion
    let userAnswer: String
    let submittedAt: String
    
    init(question: GuestQuestion, userAnswer: String) {
        self.question = question
        self.userAnswer = userAnswer
        self.submittedAt = ISO8601DateFormatter().string(from: Date())
    }
}

// MARK: - 知識點最終化模型
/// 知識點最終化請求結構
struct KnowledgePointFinalizationRequest: Codable {
    let errorAnalyses: [ErrorAnalysis]
    let questionData: QuestionData
    let userAnswer: String
    let submittedAt: String
    
    init(errorAnalyses: [ErrorAnalysis], questionData: QuestionData, userAnswer: String) {
        self.errorAnalyses = errorAnalyses
        self.questionData = questionData
        self.userAnswer = userAnswer
        self.submittedAt = ISO8601DateFormatter().string(from: Date())
    }
}

/// 問題資料結構
struct QuestionData: Codable {
    let questionId: String?
    let questionType: String?
    let originalSentence: String?
    let targetSentence: String?
    let context: String?
    let difficulty: Double?
    let category: String?
    let subcategory: String?
    let knowledgePointId: Int?
    let hintText: String?
    let expectedAnswer: String?
    
    /// 標準初始化器
    init(
        questionId: String? = nil,
        questionType: String? = nil,
        originalSentence: String? = nil,
        targetSentence: String? = nil,
        context: String? = nil,
        difficulty: Double? = nil,
        category: String? = nil,
        subcategory: String? = nil,
        knowledgePointId: Int? = nil,
        hintText: String? = nil,
        expectedAnswer: String? = nil
    ) {
        self.questionId = questionId
        self.questionType = questionType
        self.originalSentence = originalSentence
        self.targetSentence = targetSentence
        self.context = context
        self.difficulty = difficulty
        self.category = category
        self.subcategory = subcategory
        self.knowledgePointId = knowledgePointId
        self.hintText = hintText
        self.expectedAnswer = expectedAnswer
    }
    
    /// 從 [String: Any?] 轉換為強型別結構
    init(from dictionary: [String: Any?]) {
        self.init(
            questionId: dictionary["question_id"] as? String,
            questionType: dictionary["question_type"] as? String,
            originalSentence: dictionary["original_sentence"] as? String,
            targetSentence: dictionary["target_sentence"] as? String,
            context: dictionary["context"] as? String,
            difficulty: dictionary["difficulty"] as? Double,
            category: dictionary["category"] as? String,
            subcategory: dictionary["subcategory"] as? String,
            knowledgePointId: dictionary["knowledge_point_id"] as? Int,
            hintText: dictionary["hint_text"] as? String,
            expectedAnswer: dictionary["expected_answer"] as? String
        )
    }
    
    /// 創建預設問題資料
    static func `default`(
        questionType: String = "translation",
        originalSentence: String? = nil,
        targetSentence: String? = nil,
        context: String? = nil
    ) -> QuestionData {
        return QuestionData(
            questionId: UUID().uuidString,
            questionType: questionType,
            originalSentence: originalSentence,
            targetSentence: targetSentence,
            context: context,
            difficulty: 0.5,
            category: "未分類",
            subcategory: "一般",
            knowledgePointId: nil,
            hintText: nil,
            expectedAnswer: nil
        )
    }
}


// MARK: - 批次操作模型
/// 批次知識點操作請求
struct BatchKnowledgePointRequest: Codable {
    let action: BatchAction
    let knowledgePointIds: [Int]
    let options: BatchOptions?
    
    enum BatchAction: String, Codable {
        case archive = "archive"
        case unarchive = "unarchive"
        case delete = "delete"
        case updateMastery = "update_mastery"
    }
    
    struct BatchOptions: Codable {
        let masteryLevel: Double?
        let preserveHistory: Bool?
        
        init(masteryLevel: Double? = nil, preserveHistory: Bool? = true) {
            self.masteryLevel = masteryLevel
            self.preserveHistory = preserveHistory
        }
    }
}

// MARK: - 錯誤合併模型
/// 錯誤合併請求
struct ErrorMergeRequest: Codable {
    let primaryError: ErrorAnalysis
    let secondaryError: ErrorAnalysis
    let mergeStrategy: MergeStrategy
    
    enum MergeStrategy: String, Codable {
        case combineExplanations = "combine_explanations"
        case prioritizeSeverity = "prioritize_severity"
        case mergeCorrections = "merge_corrections"
        case keepPrimary = "keep_primary"
    }
    
    init(primaryError: ErrorAnalysis, secondaryError: ErrorAnalysis, strategy: MergeStrategy = .combineExplanations) {
        self.primaryError = primaryError
        self.secondaryError = secondaryError
        self.mergeStrategy = strategy
    }
}

// MARK: - 輔助擴展
extension Dictionary where Key == String, Value == Any {
    /// 安全轉換為 KnowledgePointUpdateRequest
    func toKnowledgePointUpdateRequest() -> KnowledgePointUpdateRequest {
        return KnowledgePointUpdateRequest(
            masteryLevel: self["mastery_level"] as? Double,
            keyPointSummary: self["key_point_summary"] as? String,
            explanation: self["explanation"] as? String,
            correctPhrase: self["correct_phrase"] as? String,
            userContextSentence: self["user_context_sentence"] as? String,
            incorrectPhraseInContext: self["incorrect_phrase_in_context"] as? String,
            category: self["category"] as? String,
            subcategory: self["subcategory"] as? String,
            aiReviewNotes: self["ai_review_notes"] as? String,
            isArchived: self["is_archived"] as? Bool
        )
    }
}