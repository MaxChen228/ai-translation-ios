// DashboardAPIService.swift - 儀表板資料 API 服務

import Foundation

struct DashboardAPIService {
    private static let baseURL = "\(APIConfig.apiBaseURL)/api"
    
    // MARK: - 儀表板相關 API
    
    /// 統一的儀表板數據獲取 (支援認證和訪客模式)
    static func getDashboard() async throws -> DashboardResponse {
        let urlString = "\(baseURL)/data/get_dashboard"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        APIHelper.addAuthHeader(to: &request, requireAuth: false) // 支援訪客模式
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorBody["error"] ?? errorBody["message"] {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "無法獲取儀表板數據")
        }
        
        do {
            let dashboardResponse = try JSONDecoder().decode(DashboardResponse.self, from: data)
            return dashboardResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// 獲取學習日曆熱力圖數據 (支援認證和訪客模式)
    static func getCalendarHeatmap(year: Int, month: Int) async throws -> HeatmapResponse {
        guard var urlComponents = URLComponents(string: "\(baseURL)/data/get_calendar_heatmap") else {
            throw APIError.invalidURL
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "year", value: String(year)),
            URLQueryItem(name: "month", value: String(month))
        ]
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        APIHelper.addAuthHeader(to: &request, requireAuth: false) // 支援訪客模式
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorBody["error"] ?? errorBody["message"] {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "無法獲取日曆數據")
        }
        
        do {
            let heatmapResponse = try JSONDecoder().decode(HeatmapResponse.self, from: data)
            return heatmapResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - 支援的資料結構
// HeatmapResponse 定義已在 LearningCalendarView.swift 中，這裡不重複定義