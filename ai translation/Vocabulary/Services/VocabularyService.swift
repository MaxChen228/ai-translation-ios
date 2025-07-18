// AI-tutor-v1.0/ai translation/📚 Vocabulary/Services/VocabularyService.swift

import Foundation

@MainActor
class VocabularyService: ObservableObject {
    private let baseURL = APIConfig.apiBaseURL
    
    // MARK: - 統計相關
    
    /// 獲取單字庫統計
    func getStatistics() async throws -> VocabularyStatistics {
        let url = URL(string: "\(baseURL)/api/vocabulary/statistics")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VocabularyError.networkError("獲取統計資料失敗")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(VocabularyStatistics.self, from: data)
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
        
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VocabularyError.networkError("獲取單字列表失敗")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(WordListResponse.self, from: data)
    }
    
    /// 獲取今日複習單字
    func getDailyReviewWords(limit: Int = 20) async throws -> ReviewWordsResponse {
        let url = URL(string: "\(baseURL)/api/vocabulary/review/daily?limit=\(limit)")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VocabularyError.networkError("獲取今日複習單字失敗")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ReviewWordsResponse.self, from: data)
    }
    
    /// 獲取單字詳細資訊
    func getWordDetail(wordId: Int) async throws -> VocabularyWord {
        let url = URL(string: "\(baseURL)/api/vocabulary/words/\(wordId)")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VocabularyError.networkError("獲取單字詳情失敗")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(VocabularyWord.self, from: data)
    }
    
    // MARK: - 測驗相關
    
    /// 生成測驗
    func generateQuiz(type: PracticeType, wordCount: Int = 10, difficultyLevel: Int? = nil) async throws -> QuizResponse {
        let url = URL(string: "\(baseURL)/api/vocabulary/quiz/generate")!
        
        var requestBody: [String: Any] = [
            "quiz_type": type.rawValue,
            "word_count": wordCount
        ]
        
        if let difficulty = difficultyLevel {
            requestBody["difficulty_level"] = difficulty
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VocabularyError.networkError("生成測驗失敗")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(QuizResponse.self, from: data)
    }
    
    /// 提交複習結果
    func submitReview(submission: ReviewSubmission) async throws -> ReviewResult {
        let url = URL(string: "\(baseURL)/api/vocabulary/review/submit")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(submission)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VocabularyError.networkError("提交複習結果失敗")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ReviewResult.self, from: data)
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
