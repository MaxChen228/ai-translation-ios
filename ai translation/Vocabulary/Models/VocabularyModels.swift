// AI-tutor-v1.0/ai translation/📚 Vocabulary/Models/VocabularyModels.swift

import Foundation

// MARK: - 統計數據模型
struct VocabularyStatistics: Codable {
    let totalWords: Int
    let masteredWords: Int
    let learningWords: Int
    let newWords: Int
    let dueToday: Int
    let masteryPercentage: Double
    
    enum CodingKeys: String, CodingKey {
        case totalWords = "total_words"
        case masteredWords = "mastered_words"
        case learningWords = "learning_words"
        case newWords = "new_words"
        case dueToday = "due_today"
        case masteryPercentage = "mastery_percentage"
    }
}

// MARK: - 單字模型
struct VocabularyWord: Codable, Identifiable {
    let id: Int
    let word: String
    let pronunciationIPA: String?
    let pronunciationAudioURL: String?
    let partOfSpeech: String?
    let definitionZH: String
    let definitionEN: String?
    let difficultyLevel: Int
    let wordFrequencyRank: Int?
    let masteryLevel: Double
    let totalReviews: Int
    let correctReviews: Int
    let consecutiveCorrect: Int
    let lastReviewedAt: String?
    let nextReviewAt: String?
    let sourceType: String
    let addedContext: String?
    let createdAt: String
    let updatedAt: String
    let isArchived: Bool
    let examples: [VocabularyExample]?
    
    enum CodingKeys: String, CodingKey {
        case id, word, examples
        case pronunciationIPA = "pronunciation_ipa"
        case pronunciationAudioURL = "pronunciation_audio_url"
        case partOfSpeech = "part_of_speech"
        case definitionZH = "definition_zh"
        case definitionEN = "definition_en"
        case difficultyLevel = "difficulty_level"
        case wordFrequencyRank = "word_frequency_rank"
        case masteryLevel = "mastery_level"
        case totalReviews = "total_reviews"
        case correctReviews = "correct_reviews"
        case consecutiveCorrect = "consecutive_correct"
        case lastReviewedAt = "last_reviewed_at"
        case nextReviewAt = "next_review_at"
        case sourceType = "source_type"
        case addedContext = "added_context"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isArchived = "is_archived"
    }
    
    // 計算屬性
    var masteryStatus: MasteryStatus {
        if masteryLevel >= 4.0 { return .mastered }
        else if masteryLevel > 0 { return .learning }
        else { return .new }
    }
    
    var accuracyRate: Double {
        guard totalReviews > 0 else { return 0.0 }
        return Double(correctReviews) / Double(totalReviews) * 100
    }
    
    var difficultyColor: String {
        switch difficultyLevel {
        case 1: return "#4CAF50"  // 綠色
        case 2: return "#8BC34A"  // 淺綠
        case 3: return "#FFC107"  // 黃色
        case 4: return "#FF9800"  // 橘色
        case 5: return "#F44336"  // 紅色
        default: return "#757575" // 灰色
        }
    }
}

// MARK: - 例句模型
struct VocabularyExample: Codable, Identifiable {
    let id: Int?
    let sentenceEN: String
    let sentenceZH: String?
    let source: String
    let difficultyLevel: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case sentenceEN = "sentence_en"
        case sentenceZH = "sentence_zh"
        case source
        case difficultyLevel = "difficulty_level"
    }
}

// MARK: - 掌握狀態枚舉
enum MasteryStatus: String, CaseIterable {
    case new = "new"
    case learning = "learning"
    case mastered = "mastered"
    
    var displayName: String {
        switch self {
        case .new: return "新單字"
        case .learning: return "學習中"
        case .mastered: return "已掌握"
        }
    }
    
    var color: String {
        switch self {
        case .new: return "#2196F3"      // 藍色
        case .learning: return "#FF9800" // 橘色
        case .mastered: return "#4CAF50" // 綠色
        }
    }
    
    var systemImageName: String {
        switch self {
        case .new: return "plus.circle"
        case .learning: return "clock.circle"
        case .mastered: return "checkmark.circle"
        }
    }
}

// MARK: - 學習模式枚舉
enum StudyMode: String, CaseIterable {
    case review = "review"
    case newLearning = "new_learning"
    case targeted = "targeted"
    
    var displayName: String {
        switch self {
        case .review: return "📚 複習模式"
        case .newLearning: return "🆕 新學習模式"
        case .targeted: return "🎯 專項練習"
        }
    }
    
    var description: String {
        switch self {
        case .review: return "複習到期單字"
        case .newLearning: return "學習新單字"
        case .targeted: return "特定難度/主題"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .review: return "arrow.clockwise.circle"
        case .newLearning: return "plus.square"
        case .targeted: return "target"
        }
    }
}

// MARK: - 練習類型枚舉
enum PracticeType: String, CaseIterable {
    case flashcard = "flashcard"
    case multipleChoice = "multiple_choice"
    case contextFill = "context_fill"
    
    var displayName: String {
        switch self {
        case .flashcard: return "翻卡模式"
        case .multipleChoice: return "選擇題測驗"
        case .contextFill: return "語境填空"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .flashcard: return "rectangle.stack"
        case .multipleChoice: return "checklist"
        case .contextFill: return "text.bubble"
        }
    }
}

// MARK: - 測驗問題模型
struct QuizQuestion: Codable, Identifiable {
    let id = UUID()
    let wordId: Int
    let word: String
    let pronunciation: String?
    let questionType: String
    
    // Flashcard 特有屬性
    let partOfSpeech: String?
    let definitionZH: String?
    let definitionEN: String?
    let examples: [VocabularyExample]?
    
    // Multiple Choice 特有屬性
    let questionText: String?
    let options: [String]?
    let correctIndex: Int?
    let explanation: String?
    
    // Context Fill 特有屬性
    let questionSentence: String?
    let completeSentence: String?
    let targetWord: String?
    let hints: [String]?
    
    enum CodingKeys: String, CodingKey {
        case wordId = "word_id"
        case word, pronunciation
        case questionType = "question_type"
        case partOfSpeech = "part_of_speech"
        case definitionZH = "definition_zh"
        case definitionEN = "definition_en"
        case examples
        case questionText = "question_text"
        case options
        case correctIndex = "correct_index"
        case explanation
        case questionSentence = "question_sentence"
        case completeSentence = "complete_sentence"
        case targetWord = "target_word"
        case hints
    }
}

// MARK: - 測驗回應模型
struct QuizResponse: Codable {
    let quizType: String
    let questions: [QuizQuestion]
    let totalQuestions: Int
    
    enum CodingKeys: String, CodingKey {
        case quizType = "quiz_type"
        case questions
        case totalQuestions = "total_questions"
    }
}

// MARK: - 複習提交模型
struct ReviewSubmission: Codable {
    let wordId: Int
    let isCorrect: Bool
    let reviewType: String
    let responseTime: Double?
    
    enum CodingKeys: String, CodingKey {
        case wordId = "word_id"
        case isCorrect = "is_correct"
        case reviewType = "review_type"
        case responseTime = "response_time"
    }
}

// MARK: - 複習結果模型
struct ReviewResult: Codable {
    let message: String
    let updatedWord: VocabularyWord
    
    enum CodingKeys: String, CodingKey {
        case message
        case updatedWord = "updated_word"
    }
}

// MARK: - 學習總結模型
struct StudySummary {
    let totalQuestions: Int
    let correctAnswers: Int
    let studyTime: TimeInterval
    let wordsStudied: [VocabularyWord]
    let newMasteryAchievements: [VocabularyWord]
    let accuracyRate: Double
    
    init(totalQuestions: Int, correctAnswers: Int, studyTime: TimeInterval, wordsStudied: [VocabularyWord]) {
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.studyTime = studyTime
        self.wordsStudied = wordsStudied
        self.newMasteryAchievements = wordsStudied.filter { $0.masteryLevel >= 4.0 && $0.consecutiveCorrect >= 3 }
        self.accuracyRate = totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) * 100 : 0
    }
}
