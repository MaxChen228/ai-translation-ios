//
//  MultiClassificationService.swift
//  ai translation
//
//  多分類單字系統服務層
//

import Foundation
import SwiftUI

@MainActor
class MultiClassificationService: ObservableObject {
    private let baseURL = APIConfig.apiBaseURL
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()
    
    // MARK: - Published Properties
    
    @Published var systems: [ClassificationSystem] = []
    @Published var currentSystem: ClassificationSystem?
    @Published var categoryInfo: SystemCategoryInfo?
    @Published var words: [MultiClassWord] = []
    @Published var selectedLetter: String = "A"
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 分頁狀態
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var hasMorePages = false
    
    // MARK: - 獲取分類系統
    
    func fetchClassificationSystems() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let urlString = "\(baseURL)/api/vocabulary/systems"
            print("🔗 Fetching classification systems from: \(urlString)")
            
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }
            
            let (data, response) = try await session.data(from: url)
            
            // 檢查 HTTP 回應
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    throw NSError(domain: "", code: httpResponse.statusCode, 
                                userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(httpResponse.statusCode)"])
                }
            }
            
            let decodedResponse = try JSONDecoder().decode(SystemsResponse.self, from: data)
            
            if decodedResponse.success {
                self.systems = decodedResponse.data.systems
                print("✅ Successfully loaded \(self.systems.count) classification systems")
            } else {
                throw NSError(domain: "", code: 0, 
                            userInfo: [NSLocalizedDescriptionKey: decodedResponse.message])
            }
        } catch {
            print("❌ Error fetching classification systems: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - 獲取類別資訊
    
    func fetchCategoryInfo(systemCode: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let urlString = "\(baseURL)/api/vocabulary/systems/\(systemCode)/categories"
            print("🟢 MultiClassificationService: 正在請求類別資訊: \(urlString)")
            
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }
            
            let (data, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🟢 HTTP 狀態碼: \(httpResponse.statusCode)")
            }
            
            let decodedResponse = try JSONDecoder().decode(CategoryInfoResponse.self, from: data)
            
            if decodedResponse.success {
                self.categoryInfo = decodedResponse.data
                print("🟢 成功載入類別資訊: \(decodedResponse.data.availableCategories)")
            } else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: decodedResponse.message])
            }
        } catch {
            print("🔴 載入類別資訊失敗: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - 獲取字母分布
    
    func fetchAlphabetDistribution(systemCode: String, category: String) async -> AlphabetData? {
        do {
            guard let url = URL(string: "\(baseURL)/api/vocabulary/systems/\(systemCode)/\(category)/alphabet") else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(AlphabetResponse.self, from: data)
            
            if response.success {
                return response.data
            }
        } catch {
            print("獲取字母分布失敗: \(error)")
        }
        
        return nil
    }
    
    // MARK: - 獲取單字列表
    
    func fetchWords(systemCode: String, category: String, letter: String? = nil, page: Int = 1) async {
        isLoading = true
        errorMessage = nil
        
        do {
            var components = URLComponents(string: "\(baseURL)/api/vocabulary/systems/\(systemCode)/\(category)/words")!
            components.queryItems = [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "page_size", value: "50")
            ]
            
            if let letter = letter {
                components.queryItems?.append(URLQueryItem(name: "letter", value: letter))
            }
            
            guard let url = components.url else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(WordsResponse.self, from: data)
            
            if response.success {
                if page == 1 {
                    self.words = response.data.words
                } else {
                    self.words.append(contentsOf: response.data.words)
                }
                
                self.currentPage = response.data.pagination.currentPage
                self.totalPages = response.data.pagination.totalPages
                self.hasMorePages = currentPage < totalPages
            } else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: response.message])
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - 獲取單字詳情
    
    func fetchWordDetail(wordId: Int) async -> MultiClassWordDetail? {
        do {
            guard let url = URL(string: "\(baseURL)/api/vocabulary/word/\(wordId)/detail") else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(WordDetailResponse.self, from: data)
            
            if response.success {
                return response.data
            }
        } catch {
            print("獲取單字詳情失敗: \(error)")
        }
        
        return nil
    }
    
    // MARK: - 搜尋單字
    
    func searchWords(query: String, systemCode: String? = nil) async -> [MultiClassWord] {
        do {
            var components = URLComponents(string: "\(baseURL)/api/vocabulary/search")!
            components.queryItems = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: "20")
            ]
            
            if let systemCode = systemCode {
                components.queryItems?.append(URLQueryItem(name: "system", value: systemCode))
            }
            
            guard let url = components.url else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await session.data(from: url)
            
            // 使用與 BuiltinVocabularyService 相同的搜尋回應結構
            struct SearchResponse: Codable {
                let success: Bool
                let data: SearchData
                let message: String
            }
            
            struct SearchData: Codable {
                let results: [MultiClassWord]
            }
            
            let response = try JSONDecoder().decode(SearchResponse.self, from: data)
            
            if response.success {
                return response.data.results
            }
        } catch {
            print("搜尋單字失敗: \(error)")
        }
        
        return []
    }
    
    // MARK: - 重置狀態
    
    func resetWords() {
        words = []
        currentPage = 1
        totalPages = 1
        hasMorePages = false
    }
    
    // MARK: - 載入更多
    
    func loadMoreWords(systemCode: String, category: String) async {
        guard hasMorePages && !isLoading else { return }
        await fetchWords(systemCode: systemCode, category: category, letter: selectedLetter, page: currentPage + 1)
    }
}