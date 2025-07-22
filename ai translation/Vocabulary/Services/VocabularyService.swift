// AI-tutor-v1.0/ai translation/📚 Vocabulary/Services/VocabularyService.swift

import Foundation

@MainActor
class VocabularyService: ObservableObject {
    private let baseURL = APIConfig.apiBaseURL
    
    // MARK: - 統計相關
    
    /// 獲取單字庫統計
    func getStatistics() async throws -> VocabularyStatistics {
        guard let url = URL(string: "\(baseURL)/api/vocabulary/statistics") else {
            throw VocabularyError.networkError("無效的URL")
        }
        
        let (data, response) = try await NetworkManager.shared.performGETRequest(url: url)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        return try NetworkManager.shared.safeDecodeJSON(data, as: VocabularyStatistics.self)
    }
    
    // MARK: - 單字管理
    
    /// 獲取單字列表
    func getWords(search: String? = nil, page: Int = 1, limit: Int = 20, dueOnly: Bool = false) async throws -> WordListResponse {
        var components = URLComponents(string: "\(baseURL)/api/vocabulary/words")!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        
        if dueOnly {
            queryItems.append(URLQueryItem(name: "due_only", value: "true"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw VocabularyError.networkError("無效的URL")
        }
        
        let (data, response) = try await NetworkManager.shared.performGETRequest(url: url)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        return try NetworkManager.shared.safeDecodeJSON(data, as: WordListResponse.self)
    }
    
    /// 獲取今日複習單字
    func getDailyReviewWords(limit: Int = 20) async throws -> ReviewWordsResponse {
        guard let url = URL(string: "\(baseURL)/api/vocabulary/review/daily?limit=\(limit)") else {
            throw VocabularyError.networkError("無效的URL")
        }
        
        let (data, response) = try await NetworkManager.shared.performGETRequest(url: url)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        return try NetworkManager.shared.safeDecodeJSON(data, as: ReviewWordsResponse.self)
    }
    
    /// 獲取單字詳細資訊
    func getWordDetail(wordId: Int) async throws -> VocabularyWord {
        guard let url = URL(string: "\(baseURL)/api/vocabulary/words/\(wordId)") else {
            throw VocabularyError.networkError("無效的URL")
        }
        
        let (data, response) = try await NetworkManager.shared.performGETRequest(url: url)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        return try NetworkManager.shared.safeDecodeJSON(data, as: VocabularyWord.self)
    }
    
    // MARK: - 測驗相關
    
    /// 生成測驗
    func generateQuiz(type: PracticeType, wordCount: Int = 10, difficultyLevel: Int? = nil) async throws -> QuizResponse {
        guard let url = URL(string: "\(baseURL)/api/vocabulary/quiz/generate") else {
            throw VocabularyError.networkError("無效的URL")
        }
        
        var requestBody: [String: Any] = [
            "quiz_type": type.rawValue,
            "word_count": wordCount
        ]
        
        if let difficulty = difficultyLevel {
            requestBody["difficulty_level"] = difficulty
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        let (data, response) = try await NetworkManager.shared.performPOSTRequest(url: url, body: bodyData)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        return try NetworkManager.shared.safeDecodeJSON(data, as: QuizResponse.self)
    }
    
    /// 提交複習結果
    func submitReview(submission: ReviewSubmission) async throws -> ReviewResult {
        guard let url = URL(string: "\(baseURL)/api/vocabulary/review/submit") else {
            throw VocabularyError.networkError("無效的URL")
        }
        
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(submission)
        
        let (data, response) = try await NetworkManager.shared.performPOSTRequest(url: url, body: bodyData)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        return try NetworkManager.shared.safeDecodeJSON(data, as: ReviewResult.self)
    }
}

// MARK: - 輔助模型

struct WordListResponse: Codable {
    let words: [VocabularyWord]
    let totalCount: Int
    let page: Int
    let limit: Int
    
    enum CodingKeys: String, CodingKey {
        case words
        case totalCount = "total_count"
        case page, limit
    }
}

struct ReviewWordsResponse: Codable {
    let reviewWords: [VocabularyWord]
    let totalDue: Int
    
    enum CodingKeys: String, CodingKey {
        case reviewWords = "review_words"
        case totalDue = "total_due"
    }
}

// MARK: - 錯誤類型

enum VocabularyError: LocalizedError {
    case networkError(String)
    case decodingError(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "網路錯誤: \(message)"
        case .decodingError(let message):
            return "資料解析錯誤: \(message)"
        case .invalidResponse:
            return "無效的伺服器回應"
        }
    }
}
