// Logger.swift - 統一日誌系統

import Foundation
import os

/// 統一的日誌系統，替代所有print()語句
struct Logger {
    
    // MARK: - 日誌等級
    enum Level: String, CaseIterable {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING" 
        case error = "❌ ERROR"
        case success = "✅ SUCCESS"
    }
    
    // MARK: - 日誌類別
    enum Category: String {
        case network = "🌐 NETWORK"
        case authentication = "🔐 AUTH"
        case database = "🗄️ DATABASE"
        case ui = "🎨 UI"
        case learning = "🧠 LEARNING"
        case api = "🔌 API"
        case general = "📝 GENERAL"
    }
    
    private static let osLogger = os.Logger(subsystem: "com.linker.app", category: "general")
    
    // MARK: - 主要日誌方法
    static func debug(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    static func success(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .success, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - 核心日誌實現
    private static func log(_ message: String, level: Level, category: Category, file: String, function: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        
        let logMessage = "\(timestamp) \(level.rawValue) \(category.rawValue) [\(fileName):\(line)] \(function) - \(message)"
        
        #if DEBUG
        // 開發模式：輸出到控制台
        print(logMessage)
        #endif
        
        // 生產模式：使用系統日誌
        switch level {
        case .debug:
            osLogger.debug("\(logMessage)")
        case .info:
            osLogger.info("\(logMessage)")
        case .warning:
            osLogger.warning("\(logMessage)")
        case .error, .success:
            osLogger.error("\(logMessage)")
        }
    }
}

// MARK: - 便利擴展
extension Logger {
    
    /// 網路請求日誌
    static func networkRequest(_ url: String, method: String = "GET") {
        info("🚀 \(method) \(url)", category: .network)
    }
    
    static func networkResponse(_ url: String, statusCode: Int, duration: TimeInterval) {
        let emoji = statusCode < 400 ? "✅" : "❌"
        info("\(emoji) \(statusCode) \(url) (\(String(format: "%.2f", duration))s)", category: .network)
    }
    
    static func networkError(_ error: Error, url: String = "") {
        Logger.error("🔥 \(url) - \(error.localizedDescription)", category: .network)
    }
    
    /// 認證相關日誌
    static func authSuccess(_ message: String) {
        success(message, category: .authentication)
    }
    
    static func authError(_ message: String) {
        error(message, category: .authentication)
    }
    
    /// API相關日誌
    static func apiCall(_ endpoint: String, parameters: [String: Any]? = nil) {
        let params = parameters?.description ?? "無參數"
        info("📡 API呼叫: \(endpoint) - \(params)", category: .api)
    }
    
    static func apiSuccess(_ endpoint: String, responseSize: Int = 0) {
        success("📥 API成功: \(endpoint) (大小: \(responseSize) bytes)", category: .api)
    }
    
    static func apiError(_ endpoint: String, error: Error) {
        Logger.error("💥 API失敗: \(endpoint) - \(error.localizedDescription)", category: .api)
    }
}

// MARK: - 日期格式化
extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}