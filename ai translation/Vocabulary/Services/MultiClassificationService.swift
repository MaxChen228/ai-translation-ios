//
//  MultiClassificationService.swift
//  ai translation
//
//  多分類單字系統服務層
//

import Foundation
import SwiftUI

@MainActor
class MultiClassificationService: BaseNetworkService {
    
    // MARK: - Published Properties
    
    @Published var systems: [ClassificationSystem] = []
    @Published var currentSystem: ClassificationSystem?
    @Published var categoryInfo: SystemCategoryInfo?
    @Published var words: [MultiClassWord] = []
    @Published var selectedLetter: String = "A"
    
    // 分頁狀態
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var hasMorePages = false
    
    // MARK: - 獲取分類系統
    
    func fetchClassificationSystems() async {
        do {
            let response = try await executeRequest(.getClassificationSystems, responseType: SystemsResponse.self)
            
            if response.success {
                self.systems = response.data.systems
                print("✅ Successfully loaded \(self.systems.count) classification systems")
            } else {
                throw AppError.api(.serverError(statusCode: 0, message: response.message))
            }
        } catch {
            print("❌ Error fetching classification systems: \(error)")
        }
    }
    
    // MARK: - 獲取類別資訊
    
    func fetchCategoryInfo(systemCode: String) async {
        do {
            let response = try await executeRequest(.getCategoryInfo(systemCode: systemCode), responseType: CategoryInfoResponse.self)
            
            if response.success {
                self.categoryInfo = response.data
                print("🟢 成功載入類別資訊: \(response.data.availableCategories)")
            } else {
                throw AppError.api(.serverError(statusCode: 0, message: response.message))
            }
        } catch {
            print("🔴 載入類別資訊失敗: \(error)")
        }
    }
    
    // MARK: - 獲取字母分布
    
    func fetchAlphabetDistribution(systemCode: String, category: String) async -> AlphabetData? {
        do {
            let response = try await executeRequest(.getAlphabetDistribution(systemCode: systemCode, category: category), responseType: AlphabetResponse.self, showLoading: false)
            
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
        do {
            let response = try await executeRequest(.getWordsInCategory(systemCode: systemCode, category: category, letter: letter, page: page, pageSize: 50), responseType: WordsResponse.self)
            
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
                throw AppError.api(.serverError(statusCode: 0, message: response.message))
            }
        } catch {
            print("獲取單字列表失敗: \(error)")
        }
    }
    
    // MARK: - 獲取單字詳情
    
    func fetchWordDetail(wordId: Int) async -> MultiClassWordDetail? {
        do {
            let response = try await executeRequest(.getWordDetail(wordId: wordId), responseType: WordDetailResponse.self, showLoading: false)
            
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
            // 使用統一的搜尋端點結構
            struct SearchResponse: Codable {
                let success: Bool
                let data: SearchData
                let message: String
            }
            
            struct SearchData: Codable {
                let results: [MultiClassWord]
            }
            
            let response = try await executeRequest(.searchMultiClassWords(query: query, systemCode: systemCode, limit: 20), responseType: SearchResponse.self, showLoading: false)
            
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