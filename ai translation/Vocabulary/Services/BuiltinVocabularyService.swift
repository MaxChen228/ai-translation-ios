// BuiltinVocabularyService.swift
// 內建單字庫服務層

import Foundation
import Combine

@MainActor
class BuiltinVocabularyService: ObservableObject {
    private let baseURL = APIConfig.apiBaseURL
    private let session = URLSession.shared
    
    // MARK: - Published Properties
    
    @Published var categories: [BuiltinCategory] = []
    @Published var words: [BuiltinWord] = []
    @Published var loadingState: BuiltinVocabularyLoadingState = .idle
    @Published var currentFilter = BuiltinVocabularyFilter()
    
    // 分頁狀態
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var hasMorePages = false
    
    // MARK: - 分類管理
    
    /// 獲取所有內建單字分類
    func getCategories() async throws -> [BuiltinCategory] {
        guard let url = URL(string: "\(baseURL)/api/vocabulary/builtin/categories") else {
            throw BuiltinVocabularyError.invalidResponse
        }
        
        let (data, response) = try await NetworkManager.shared.performGETRequest(url: url)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        let categoriesResponse = try NetworkManager.shared.safeDecodeJSON(data, as: BuiltinCategoriesResponse.self)
        
        if categoriesResponse.success {
            self.categories = categoriesResponse.categories
            return categoriesResponse.categories
        } else {
            throw BuiltinVocabularyError.networkError(categoriesResponse.error ?? "Unknown error")
        }
    }
    
    // MARK: - 單字列表管理
    
    /// 獲取內建單字列表
    func getWords(request: BuiltinWordsRequest) async throws -> BuiltinWordsResponse {
        var components = URLComponents(string: "\(baseURL)/api/vocabulary/builtin/words")!
        components.queryItems = request.toQueryItems()
        
        guard let url = components.url else {
            throw BuiltinVocabularyError.invalidResponse
        }
        
        let (data, response) = try await NetworkManager.shared.performGETRequest(url: url)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        let wordsResponse = try NetworkManager.shared.safeDecodeJSON(data, as: BuiltinWordsResponse.self)
        
        if wordsResponse.success {
            // 更新分頁狀態
            self.currentPage = wordsResponse.page
            self.totalPages = wordsResponse.totalPages
            self.hasMorePages = wordsResponse.page < wordsResponse.totalPages
            
            // 如果是第一頁，替換資料；否則追加
            if request.page == 1 {
                self.words = wordsResponse.words
            } else {
                self.words.append(contentsOf: wordsResponse.words)
            }
            
            return wordsResponse
        } else {
            throw BuiltinVocabularyError.networkError(wordsResponse.error ?? "Unknown error")
        }
    }
    
    /// 載入更多單字（分頁）
    func loadMoreWords() async throws {
        guard hasMorePages else { return }
        
        switch loadingState {
        case .loading:
            return
        default:
            break
        }
        
        loadingState = .loading
        
        do {
            var request = createCurrentRequest()
            request.page = currentPage + 1
            
            _ = try await getWords(request: request)
            loadingState = .loaded
        } catch {
            loadingState = .error(error.localizedDescription)
            throw error
        }
    }
    
    /// 刷新單字列表
    func refreshWords() async throws {
        loadingState = .loading
        
        do {
            var request = createCurrentRequest()
            request.page = 1
            
            _ = try await getWords(request: request)
            loadingState = .loaded
        } catch {
            loadingState = .error(error.localizedDescription)
            throw error
        }
    }
    
    /// 根據當前篩選條件創建請求
    private func createCurrentRequest() -> BuiltinWordsRequest {
        return BuiltinWordsRequest(
            categoryId: currentFilter.selectedCategory?.id,
            difficultyLevel: currentFilter.selectedDifficulty,
            search: currentFilter.searchText.isEmpty ? nil : currentFilter.searchText,
            page: 1,
            limit: BuiltinVocabularyConstants.defaultPageSize
        )
    }
    
    // MARK: - 單字詳情
    
    /// 獲取單字詳細資訊
    func getWordDetail(word: String) async throws -> BuiltinWordDetail {
        guard let url = URL(string: "\(baseURL)/api/vocabulary/builtin/word/\(word)") else {
            throw BuiltinVocabularyError.invalidResponse
        }
        
        let (data, response) = try await NetworkManager.shared.performGETRequest(url: url)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        let detailResponse = try NetworkManager.shared.safeDecodeJSON(data, as: BuiltinWordDetailResponse.self)
        
        if detailResponse.success,
           let wordInfo = detailResponse.wordInfo,
           let dictionaryData = detailResponse.dictionaryData {
            
            return BuiltinWordDetail(
                success: true,
                wordInfo: wordInfo,
                dictionaryData: dictionaryData,
                timestamp: detailResponse.timestamp ?? ""
            )
        } else {
            throw BuiltinVocabularyError.networkError(detailResponse.error ?? "Failed to get word detail")
        }
    }
    
    // MARK: - 個人單字庫管理
    
    /// 將內建單字加入個人單字庫
    func addToMyWords(word: String, userId: Int = 1) async throws -> AddToMyWordsResponse {
        guard let url = URL(string: "\(baseURL)/api/vocabulary/builtin/word/\(word)/add-to-my-words") else {
            throw BuiltinVocabularyError.invalidResponse
        }
        
        let request = AddToMyWordsRequest(word: word, userId: userId)
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(request)
        
        let (data, response) = try await NetworkManager.shared.performPOSTRequest(url: url, body: bodyData)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        let addResponse = try NetworkManager.shared.safeDecodeJSON(data, as: AddToMyWordsResponse.self)
        return addResponse
    }
    
    // MARK: - 搜尋功能
    
    /// 搜尋內建單字
    func searchWords(query: String, limit: Int = 20) async throws -> [BuiltinWord] {
        guard !query.isEmpty else { return [] }
        
        var components = URLComponents(string: "\(baseURL)/api/vocabulary/builtin/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            throw BuiltinVocabularyError.invalidResponse
        }
        
        let (data, response) = try await NetworkManager.shared.performGETRequest(url: url)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        let searchResponse = try NetworkManager.shared.safeDecodeJSON(data, as: SearchWordsResponse.self)
        
        if searchResponse.success {
            return searchResponse.words
        } else {
            throw BuiltinVocabularyError.networkError(searchResponse.error ?? "Search failed")
        }
    }
    
    // MARK: - 熱門和隨機單字
    
    /// 獲取熱門單字
    func getPopularWords(limit: Int = 10) async throws -> [BuiltinWord] {
        guard let url = URL(string: "\(baseURL)/api/vocabulary/builtin/popular?limit=\(limit)") else {
            throw BuiltinVocabularyError.invalidResponse
        }
        
        let (data, response) = try await NetworkManager.shared.performGETRequest(url: url)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        let popularResponse = try NetworkManager.shared.safeDecodeJSON(data, as: PopularWordsResponse.self)
        
        if popularResponse.success {
            return popularResponse.words
        } else {
            throw BuiltinVocabularyError.networkError(popularResponse.error ?? "Failed to get popular words")
        }
    }
    
    /// 獲取隨機單字
    func getRandomWords(limit: Int = 5) async throws -> [BuiltinWord] {
        guard let url = URL(string: "\(baseURL)/api/vocabulary/builtin/random?limit=\(limit)") else {
            throw BuiltinVocabularyError.invalidResponse
        }
        
        let (data, response) = try await NetworkManager.shared.performGETRequest(url: url)
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        let randomResponse = try NetworkManager.shared.safeDecodeJSON(data, as: RandomWordsResponse.self)
        
        if randomResponse.success {
            return randomResponse.words
        } else {
            throw BuiltinVocabularyError.networkError(randomResponse.error ?? "Failed to get random words")
        }
    }
    
    // MARK: - 篩選管理
    
    /// 應用篩選條件
    func applyFilter(_ filter: BuiltinVocabularyFilter) async throws {
        currentFilter = filter
        try await refreshWords()
    }
    
    /// 清除篩選條件
    func clearFilter() async throws {
        currentFilter.reset()
        try await refreshWords()
    }
    
    /// 設置分類篩選
    func filterByCategory(_ category: BuiltinCategory?) async throws {
        currentFilter.selectedCategory = category
        try await refreshWords()
    }
    
    /// 設置難度篩選
    func filterByDifficulty(_ difficulty: Int?) async throws {
        currentFilter.selectedDifficulty = difficulty
        try await refreshWords()
    }
    
    /// 設置搜尋文字
    func setSearchText(_ text: String) async throws {
        currentFilter.searchText = text
        
        // 實作去抖動搜尋
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒延遲
        
        // 檢查搜尋文字是否還是一樣（避免過時的搜尋）
        if currentFilter.searchText == text {
            try await refreshWords()
        }
    }
    
    // MARK: - 快取管理
    
    /// 清理過期快取
    func clearExpiredCache() async throws {
        guard let url = URL(string: "\(baseURL)/api/vocabulary/builtin/clear-cache") else {
            throw BuiltinVocabularyError.invalidResponse
        }
        
        let (data, response) = try await NetworkManager.shared.performPOSTRequest(url: url, body: Data())
        try NetworkManager.shared.validateHTTPResponse(response, data: data)
        
        // 可以根據需要處理回應
    }
    
    // MARK: - 音頻播放支援
    
    /// 獲取音頻播放 URL
    func getAudioURL(for word: String) async throws -> URL? {
        let detail = try await getWordDetail(word: word)
        
        if let audioUrlString = detail.dictionaryData.primaryAudioUrl,
           let audioURL = URL(string: audioUrlString) {
            return audioURL
        }
        
        return nil
    }
}

// MARK: - Convenience Methods

extension BuiltinVocabularyService {
    
    /// 快速載入分類和初始單字
    func loadInitialData() async throws {
        loadingState = .loading
        
        do {
            // 並行載入分類和單字
            async let categoriesTask = getCategories()
            async let wordsTask = getWords(request: BuiltinWordsRequest())
            
            _ = try await categoriesTask
            _ = try await wordsTask
            
            loadingState = .loaded
        } catch {
            loadingState = .error(error.localizedDescription)
            throw error
        }
    }
    
    /// 檢查單字是否已在個人單字庫中
    func isWordInMyVocabulary(word: String) -> Bool {
        // 這裡可以整合 VocabularyService 來檢查
        // 暫時返回 false
        return false
    }
}