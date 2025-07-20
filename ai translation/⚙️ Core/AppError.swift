// AppError.swift - 統一的應用錯誤處理機制

import Foundation

// MARK: - 統一錯誤類型
enum AppError: Error, LocalizedError {
    // 認證相關錯誤
    case authentication(AuthError)
    
    // API 相關錯誤  
    case api(APIError)
    
    // 網路相關錯誤
    case network(NetworkError)
    
    // 資料相關錯誤
    case data(DataError)
    
    // 系統相關錯誤
    case system(SystemError)
    
    // MARK: - 錯誤描述
    var errorDescription: String? {
        switch self {
        case .authentication(let authError):
            return authError.errorDescription
        case .api(let apiError):
            return apiError.localizedDescription
        case .network(let networkError):
            return networkError.localizedDescription
        case .data(let dataError):
            return dataError.localizedDescription
        case .system(let systemError):
            return systemError.localizedDescription
        }
    }
    
    // MARK: - 錯誤代碼
    var errorCode: String {
        switch self {
        case .authentication(let authError):
            return "AUTH_\(authError.code)"
        case .api(let apiError):
            return "API_\(apiError.code)"
        case .network(let networkError):
            return "NET_\(networkError.code)"
        case .data(let dataError):
            return "DATA_\(dataError.code)"
        case .system(let systemError):
            return "SYS_\(systemError.code)"
        }
    }
    
    // MARK: - 使用者友善訊息
    var userFriendlyMessage: String {
        switch self {
        case .authentication(let authError):
            return authError.userMessage
        case .api(let apiError):
            return apiError.userMessage
        case .network:
            return "網路連線有問題，請檢查網路設定後重試"
        case .data:
            return "資料處理時發生錯誤，請稍後再試"
        case .system:
            return "系統暫時無法處理請求，請稍後再試"
        }
    }
    
    // MARK: - 錯誤嚴重程度
    var severity: ErrorSeverity {
        switch self {
        case .authentication(.invalidCredentials), .authentication(.userAlreadyExists):
            return .warning
        case .authentication(.tokenExpired):
            return .info
        case .authentication:
            return .error
        case .api(.serverError(statusCode: let code, _)) where code >= 500:
            return .critical
        case .api:
            return .error
        case .network(.timeout), .network(.noConnection):
            return .warning
        case .network:
            return .error
        case .data:
            return .error
        case .system:
            return .critical
        }
    }
}

// MARK: - 錯誤嚴重程度
enum ErrorSeverity: String, CaseIterable {
    case info = "info"
    case warning = "warning" 
    case error = "error"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .info: return "提示"
        case .warning: return "警告"
        case .error: return "錯誤"
        case .critical: return "嚴重錯誤"
        }
    }
}

// MARK: - 網路錯誤
enum NetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    case invalidResponse
    case serverUnreachable
    
    var localizedDescription: String {
        switch self {
        case .noConnection:
            return "無網路連線"
        case .timeout:
            return "請求超時"
        case .invalidResponse:
            return "伺服器回應無效"
        case .serverUnreachable:
            return "無法連接伺服器"
        }
    }
    
    var code: String {
        switch self {
        case .noConnection: return "001"
        case .timeout: return "002"
        case .invalidResponse: return "003"
        case .serverUnreachable: return "004"
        }
    }
}

// MARK: - 資料錯誤
enum DataError: Error, LocalizedError {
    case decodingFailed
    case encodingFailed
    case invalidFormat
    case corruptedData
    case notFound
    
    var localizedDescription: String {
        switch self {
        case .decodingFailed:
            return "資料解析失敗"
        case .encodingFailed:
            return "資料編碼失敗"
        case .invalidFormat:
            return "資料格式無效"
        case .corruptedData:
            return "資料已損壞"
        case .notFound:
            return "找不到指定資料"
        }
    }
    
    var code: String {
        switch self {
        case .decodingFailed: return "001"
        case .encodingFailed: return "002"
        case .invalidFormat: return "003"
        case .corruptedData: return "004"
        case .notFound: return "005"
        }
    }
}

// MARK: - 系統錯誤
enum SystemError: Error, LocalizedError {
    case memoryWarning
    case diskSpaceLow
    case permissionDenied
    case unknown(String)
    
    var localizedDescription: String {
        switch self {
        case .memoryWarning:
            return "記憶體不足"
        case .diskSpaceLow:
            return "儲存空間不足"
        case .permissionDenied:
            return "權限不足"
        case .unknown(let message):
            return "未知錯誤：\(message)"
        }
    }
    
    var code: String {
        switch self {
        case .memoryWarning: return "001"
        case .diskSpaceLow: return "002"
        case .permissionDenied: return "003"
        case .unknown: return "999"
        }
    }
}

// MARK: - API 錯誤擴展
extension APIError {
    var userMessage: String {
        switch self {
        case .invalidURL:
            return "請求地址有誤"
        case .requestFailed:
            return "請求失敗，請重試"
        case .invalidResponse:
            return "伺服器回應異常"
        case .serverError(let statusCode, let message):
            if statusCode >= 500 {
                return "伺服器暫時無法處理請求"
            } else {
                return message.isEmpty ? "請求處理失敗" : message
            }
        case .decodingError:
            return "資料處理失敗"
        case .unknownError:
            return "發生未知錯誤"
        }
    }
    
    var code: String {
        switch self {
        case .invalidURL: return "001"
        case .requestFailed: return "002"
        case .invalidResponse: return "003"
        case .serverError(let statusCode, _): return "\(statusCode)"
        case .decodingError: return "005"
        case .unknownError: return "999"
        }
    }
}

// MARK: - 認證錯誤擴展
extension AuthError {
    var userMessage: String {
        switch self {
        case .invalidCredentials:
            return "帳號或密碼錯誤，請重新輸入"
        case .userAlreadyExists:
            return "此帳號已存在，請使用其他帳號"
        case .networkError:
            return "網路連線異常，請檢查網路設定"
        case .tokenExpired:
            return "登入已過期，請重新登入"
        case .invalidToken:
            return "認證憑證無效，請重新登入"
        case .serverError(let message):
            return message.isEmpty ? "認證服務暫時無法使用" : message
        case .unknown:
            return "認證過程發生未知錯誤"
        }
    }
    
    var code: String {
        switch self {
        case .invalidCredentials: return "001"
        case .userAlreadyExists: return "002"
        case .networkError: return "003"
        case .tokenExpired: return "004"
        case .invalidToken: return "005"
        case .serverError: return "006"
        case .unknown: return "999"
        }
    }
}

// MARK: - 錯誤轉換輔助函式
extension AppError {
    /// 從 AuthError 轉換
    static func from(_ error: AuthError) -> AppError {
        return .authentication(error)
    }
    
    /// 從 APIError 轉換
    static func from(_ error: APIError) -> AppError {
        return .api(error)
    }
    
    /// 從任意 Error 轉換
    static func from(_ error: Error) -> AppError {
        if let authError = error as? AuthError {
            return .authentication(authError)
        } else if let apiError = error as? APIError {
            return .api(apiError)
        } else {
            return .system(.unknown(error.localizedDescription))
        }
    }
}