// NetworkServiceProtocol.swift - 統一的網路服務協議
// 提供一致的網路請求介面，減少重複代碼

import Foundation

/// 統一的網路服務協議
/// 所有的 API 服務都應該實現此協議以確保一致性
protocol NetworkServiceProtocol {
    var baseURL: String { get }
    var networkManager: NetworkManager { get }
    
    /// 執行API請求
    /// - Parameters:
    ///   - endpoint: API端點定義
    ///   - responseType: 期望的回應類型
    /// - Returns: 解析後的回應物件
    func performRequest<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T
    
    /// 執行API請求（無回應體）
    /// - Parameter endpoint: API端點定義
    func performRequest(_ endpoint: APIEndpoint) async throws
}

/// 預設的網路服務實現
extension NetworkServiceProtocol {
    
    /// 統一的請求執行邏輯
    func performRequest<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        // 構建URL
        guard let url = endpoint.buildURL(baseURL: baseURL) else {
            throw AppError.api(.invalidURL)
        }
        
        // 創建請求
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeoutInterval
        
        // 設置請求頭
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 添加認證token（如果需要）
        if endpoint.requiresAuth {
            try await networkManager.addAuthHeaderAsync(to: &request, requireAuth: true)
        }
        
        // 設置請求體
        if let requestBody = try endpoint.buildRequestBody() {
            request.httpBody = requestBody
        }
        
        // 執行請求
        let (data, response) = try await networkManager.performRequest(request)
        
        // 檢查HTTP回應狀態
        if let httpResponse = response as? HTTPURLResponse {
            guard 200...299 ~= httpResponse.statusCode else {
                // 嘗試解析錯誤訊息
                var errorMessage = "HTTP錯誤"
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorData["error"] ?? errorData["message"] {
                    errorMessage = message
                }
                
                // 根據狀態碼進行特殊處理
                switch httpResponse.statusCode {
                case 401:
                    throw AppError.authentication(.tokenExpired)
                case 403:
                    throw AppError.authentication(.invalidToken)
                case 422:
                    throw AppError.api(.serverError(statusCode: httpResponse.statusCode, message: errorMessage))
                default:
                    throw AppError.api(.serverError(statusCode: httpResponse.statusCode, message: errorMessage))
                }
            }
        }
        
        // 解析JSON回應
        do {
            return try JSONDecoder().decode(responseType, from: data)
        } catch {
            throw AppError.data(.decodingFailed)
        }
    }
    
    /// 執行無回應體的請求
    func performRequest(_ endpoint: APIEndpoint) async throws {
        let _: EmptyResponse = try await performRequest(endpoint, responseType: EmptyResponse.self)
    }
    
}

/// 空回應結構（用於不需要回應體的請求）
private struct EmptyResponse: Codable {
    // 空結構
}

/// 網路服務的基礎實現類
/// 其他服務可以繼承此類來獲得統一的網路功能
@MainActor
class BaseNetworkService: ObservableObject, NetworkServiceProtocol {
    let baseURL: String
    let networkManager: NetworkManager
    
    // 通用的發布屬性
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(baseURL: String = APIConfig.apiBaseURL, networkManager: NetworkManager = NetworkManager.shared) {
        self.baseURL = baseURL
        self.networkManager = networkManager
    }
    
    /// 執行請求並處理通用的載入狀態和錯誤
    func executeRequest<T: Codable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type,
        showLoading: Bool = true
    ) async throws -> T {
        if showLoading {
            isLoading = true
        }
        errorMessage = nil
        
        defer {
            if showLoading {
                isLoading = false
            }
        }
        
        do {
            return try await performRequest(endpoint, responseType: responseType)
        } catch {
            let appError = convertToAppError(error)
            errorMessage = appError.localizedDescription
            throw appError
        }
    }
    
    /// 執行無回應體的請求並處理通用狀態
    func executeRequest(
        _ endpoint: APIEndpoint,
        showLoading: Bool = true
    ) async throws {
        if showLoading {
            isLoading = true
        }
        errorMessage = nil
        
        defer {
            if showLoading {
                isLoading = false
            }
        }
        
        do {
            try await performRequest(endpoint)
        } catch {
            let appError = convertToAppError(error)
            errorMessage = appError.localizedDescription
            throw appError
        }
    }
}

/// 網路服務工廠
/// 用於創建和管理不同類型的網路服務實例
@MainActor
class NetworkServiceFactory {
    static let shared = NetworkServiceFactory()
    
    private init() {}
    
    /// 創建單字記憶庫服務
    func createVocabularyService() -> VocabularyService {
        return VocabularyService()
    }
    
    /// 創建多分類單字服務
    func createMultiClassificationService() -> MultiClassificationService {
        return MultiClassificationService()
    }
    
    /// 創建統一API服務
    func createUnifiedAPIService() -> UnifiedAPIServiceProtocol {
        return UnifiedAPIService.shared
    }
}


// MARK: - 日誌和監控

extension NetworkServiceProtocol {
    /// 記錄API請求日誌
    func logRequest(_ endpoint: APIEndpoint, duration: TimeInterval? = nil) {
        let logMessage = "🌐 API Request: \(endpoint.method.rawValue) \(endpoint.urlPath)"
        
        if let duration = duration {
            print("\(logMessage) - Duration: \(String(format: "%.2f", duration))s")
        } else {
            print(logMessage)
        }
    }
    
    /// 記錄API錯誤日誌
    func logError(_ endpoint: APIEndpoint, error: Error) {
        print("❌ API Error: \(endpoint.method.rawValue) \(endpoint.urlPath) - \(error.localizedDescription)")
    }
    
    /// 將通用錯誤轉換為 AppError
    func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        if let apiError = error as? APIError {
            return .api(apiError)
        }
        
        if let authError = error as? AuthError {
            return .authentication(authError)
        }
        
        if let urlError = error as? URLError {
            let networkError: NetworkError
            switch urlError.code {
            case .notConnectedToInternet:
                networkError = .noConnection
            case .timedOut:
                networkError = .timeout
            case .cannotFindHost, .cannotConnectToHost:
                networkError = .serverUnreachable
            default:
                networkError = .invalidResponse
            }
            return .network(networkError)
        }
        
        // 預設回傳系統錯誤
        let systemError = SystemError.unknown(error.localizedDescription)
        return .system(systemError)
    }
}