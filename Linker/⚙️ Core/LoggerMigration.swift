// LoggerMigration.swift - 日誌遷移助手
// 提供便利方法幫助從 print() 遷移到 Logger

import Foundation

// MARK: - 日誌遷移規則
struct LogMigrationRules {
    /// 根據訊息內容判斷日誌等級
    static func determineLevel(from message: String) -> Logger.Level {
        let lowercased = message.lowercased()
        
        if lowercased.contains("error") || lowercased.contains("❌") || lowercased.contains("失敗") || lowercased.contains("錯誤") {
            return .error
        } else if lowercased.contains("warning") || lowercased.contains("⚠️") || lowercased.contains("警告") {
            return .warning
        } else if lowercased.contains("success") || lowercased.contains("✅") || lowercased.contains("成功") || lowercased.contains("完成") {
            return .success
        } else if lowercased.contains("debug") || lowercased.contains("🔍") || lowercased.contains("偵錯") || lowercased.contains("調試") {
            return .debug
        } else {
            return .info
        }
    }
    
    /// 根據檔案路徑判斷日誌類別
    static func determineCategory(from file: String, message: String) -> Logger.Category {
        let filename = (file as NSString).lastPathComponent.lowercased()
        let lowercasedMessage = message.lowercased()
        
        // 根據檔案名稱判斷
        if filename.contains("auth") || filename.contains("login") || filename.contains("register") {
            return .authentication
        } else if filename.contains("network") || filename.contains("api") || filename.contains("service") {
            return .network
        } else if filename.contains("dashboard") || filename.contains("view") || filename.contains("ui") {
            return .ui
        } else if filename.contains("database") || filename.contains("repository") || filename.contains("storage") {
            return .database
        } else if filename.contains("learning") || filename.contains("ai") || filename.contains("tutor") {
            return .learning
        }
        
        // 根據訊息內容判斷
        if lowercasedMessage.contains("api") || lowercasedMessage.contains("請求") || lowercasedMessage.contains("回應") {
            return .api
        } else if lowercasedMessage.contains("認證") || lowercasedMessage.contains("登入") || lowercasedMessage.contains("登出") {
            return .authentication
        } else if lowercasedMessage.contains("儲存") || lowercasedMessage.contains("載入") || lowercasedMessage.contains("資料庫") {
            return .database
        } else if lowercasedMessage.contains("學習") || lowercasedMessage.contains("知識點") || lowercasedMessage.contains("練習") {
            return .learning
        }
        
        return .general
    }
    
    /// 清理訊息（移除多餘的符號和前綴）
    static func cleanMessage(_ message: String) -> String {
        var cleaned = message
        
        // 移除常見的前綴模式
        let prefixPatterns = [
            #"^\[[\w\s]+\]\s*"#,  // [ClassName] 前綴
            #"^💾\s*"#,           // 儲存圖示
            #"^🔍\s*"#,           // 搜尋圖示
            #"^☁️\s*"#,           // 雲端圖示
            #"^✅\s*"#,           // 成功圖示
            #"^❌\s*"#,           // 錯誤圖示
            #"^⚠️\s*"#,           // 警告圖示
            #"^🔐\s*"#,           // 認證圖示
        ]
        
        for pattern in prefixPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: cleaned.utf16.count)
                cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
            }
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - 快速遷移擴展
extension Logger {
    /// 從 print 快速遷移的便利方法
    static func migrate(from printMessage: String, file: String = #file, function: String = #function, line: Int = #line) {
        let level = LogMigrationRules.determineLevel(from: printMessage)
        let category = LogMigrationRules.determineCategory(from: file, message: printMessage)
        let cleanedMessage = LogMigrationRules.cleanMessage(printMessage)
        
        log(cleanedMessage, level: level, category: category, file: file, function: function, line: line)
    }
}

// MARK: - 批量遷移建議
struct LogMigrationSuggestion {
    let originalCode: String
    let suggestedCode: String
    let file: String
    let line: Int
    
    /// 生成遷移報告
    static func generateMigrationReport(for file: String, content: String) -> [LogMigrationSuggestion] {
        var suggestions: [LogMigrationSuggestion] = []
        let lines = content.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            if let suggestion = analyzeLine(line, fileContext: file, lineNumber: index + 1) {
                suggestions.append(suggestion)
            }
        }
        
        return suggestions
    }
    
    private static func analyzeLine(_ line: String, fileContext: String, lineNumber: Int) -> LogMigrationSuggestion? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // 匹配 print 語句
        let printPattern = #"print\s*\(\s*"([^"]+)"\s*\)"#
        guard let regex = try? NSRegularExpression(pattern: printPattern, options: []) else { return nil }
        
        let nsRange = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        guard let match = regex.firstMatch(in: trimmed, options: [], range: nsRange) else { return nil }
        
        // 提取訊息
        guard let messageRange = Range(match.range(at: 1), in: trimmed) else { return nil }
        let message = String(trimmed[messageRange])
        
        // 判斷日誌等級和類別
        let level = LogMigrationRules.determineLevel(from: message)
        let category = LogMigrationRules.determineCategory(from: fileContext, message: message)
        let cleanedMessage = LogMigrationRules.cleanMessage(message)
        
        // 生成建議的程式碼
        let suggestedCode: String
        switch level {
        case .debug:
            suggestedCode = "Logger.debug(\"\(cleanedMessage)\", category: .\(category))"
        case .info:
            suggestedCode = "Logger.info(\"\(cleanedMessage)\", category: .\(category))"
        case .warning:
            suggestedCode = "Logger.warning(\"\(cleanedMessage)\", category: .\(category))"
        case .error:
            suggestedCode = "Logger.error(\"\(cleanedMessage)\", category: .\(category))"
        case .success:
            suggestedCode = "Logger.success(\"\(cleanedMessage)\", category: .\(category))"
        }
        
        return LogMigrationSuggestion(
            originalCode: trimmed,
            suggestedCode: suggestedCode,
            file: fileContext,
            line: lineNumber
        )
    }
}

// MARK: - 開發時期的日誌助手
#if DEBUG
extension Logger {
    /// 開發時期的詳細日誌（生產環境會自動移除）
    static func dev(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        debug("[DEV] \(message)", category: .general, file: file, function: function, line: line)
    }
    
    /// 打印物件的詳細資訊
    static func dump<T>(_ object: T, label: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        var output = ""
        Swift.dump(object, to: &output)
        debug("\(label)\n\(output)", category: .general, file: file, function: function, line: line)
    }
    
    /// 追蹤函數呼叫
    static func trace(_ message: String = "Function called", file: String = #file, function: String = #function, line: Int = #line) {
        debug("[TRACE] \(function) - \(message)", category: .general, file: file, function: function, line: line)
    }
}
#endif

// MARK: - 常用日誌模板
extension Logger {
    
    // MARK: - 網路相關
    
    static func networkRequestStarted(url: String, method: String = "GET") {
        networkRequest(url, method: method)
    }
    
    static func networkRequestCompleted(url: String, statusCode: Int, duration: TimeInterval) {
        networkResponse(url, statusCode: statusCode, duration: duration)
    }
    
    static func networkRequestFailed(url: String, error: Error) {
        networkError(error, url: url)
    }
    
    // MARK: - 資料操作
    
    static func dataLoaded<T>(type: T.Type, count: Int, source: String = "未知") {
        info("成功載入 \(count) 個 \(type) 物件，來源: \(source)", category: .database)
    }
    
    static func dataSaved<T>(type: T.Type, count: Int, destination: String = "本地") {
        success("成功儲存 \(count) 個 \(type) 物件到 \(destination)", category: .database)
    }
    
    static func dataOperationFailed<T>(operation: String, type: T.Type, error: Error) {
        Logger.error("\(operation) \(type) 失敗: \(error.localizedDescription)", category: .database)
    }
    
    // MARK: - UI 事件
    
    static func viewAppeared(viewName: String) {
        info("\(viewName) 已顯示", category: .ui)
    }
    
    static func userAction(_ action: String, in view: String) {
        info("使用者操作: \(action) - 在 \(view)", category: .ui)
    }
    
    static func uiStateChanged(from oldState: String, to newState: String) {
        info("UI 狀態變更: \(oldState) → \(newState)", category: .ui)
    }
    
    // MARK: - 學習相關
    
    static func learningSessionStarted(type: String) {
        info("開始 \(type) 學習會話", category: .learning)
    }
    
    static func learningProgress(completed: Int, total: Int, type: String) {
        info("學習進度: \(completed)/\(total) \(type)", category: .learning)
    }
    
    static func learningCompleted(type: String, score: Double? = nil) {
        if let score = score {
            success("完成 \(type) 學習，得分: \(String(format: "%.1f", score))%", category: .learning)
        } else {
            success("完成 \(type) 學習", category: .learning)
        }
    }
}