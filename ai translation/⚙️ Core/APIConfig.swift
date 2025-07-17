// AI-tutor-v1.0/ai translation/⚙️ Core/APIConfig.swift

import Foundation

struct APIConfig {
    static let apiBaseURL: String = {
        guard let url = Bundle.main.url(forResource: "Configuration", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let baseURL = result["API_BASE_URL"] as? String else {
            // 如果讀取失敗，App 會直接崩潰並提示錯誤，這在開發階段是好事，可以確保你不會忘記設定。
            fatalError("Fatal Error: Configuration.plist not found or API_BASE_URL is not set.")
        }
        return baseURL
    }()
}
