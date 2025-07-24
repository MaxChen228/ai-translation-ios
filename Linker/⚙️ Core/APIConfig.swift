// AI-tutor-v1.0/Linker/⚙️ Core/APIConfig.swift

import Foundation

struct APIConfig {
    static let apiBaseURL: String = {
        // 檢測是否在模擬器中運行
        let isSimulator = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
        
        if isSimulator {
            // 模擬器可以使用 localhost
            return "http://localhost:8000"
        } else {
            // 真實設備需要使用實際 IP
            // 從 Configuration.plist 讀取
            guard let url = Bundle.main.url(forResource: "Configuration", withExtension: "plist"),
                  let data = try? Data(contentsOf: url),
                  let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                  let baseURL = result["API_BASE_URL"] as? String else {
                // 如果讀取失敗，App 會直接崩潰並提示錯誤，這在開發階段是好事，可以確保你不會忘記設定。
                fatalError("Fatal Error: Configuration.plist not found or API_BASE_URL is not set.")
            }
            return baseURL
        }
    }()
}
