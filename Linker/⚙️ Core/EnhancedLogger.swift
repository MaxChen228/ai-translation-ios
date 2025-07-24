// EnhancedLogger.swift - 增強版日誌系統
// 提供更強大的日誌功能，包括過濾、持久化、錯誤追蹤等

import Foundation
import os

// MARK: - 日誌配置
struct LoggerConfiguration {
    /// 最小日誌等級（低於此等級的日誌不會顯示）
    var minimumLevel: Logger.Level = .debug
    
    /// 啟用的日誌類別（nil 表示全部啟用）
    var enabledCategories: Set<Logger.Category>? = nil
    
    /// 是否在控制台顯示日誌
    var consoleOutputEnabled = true
    
    /// 是否持久化日誌到檔案
    var fileOutputEnabled = false
    
    /// 日誌檔案最大大小（MB）
    var maxLogFileSize: Double = 10.0
    
    /// 是否包含呼叫位置資訊
    var includeCallSiteInfo = true
    
    /// 是否包含執行緒資訊
    var includeThreadInfo = false
    
    /// 日誌格式
    var format: LogFormat = .detailed
    
    enum LogFormat {
        case simple     // 只有時間和訊息
        case standard   // 時間、等級、類別、訊息
        case detailed   // 包含檔案、函數、行號
        case json       // JSON 格式輸出
    }
}

// MARK: - 增強版 Logger
extension Logger {
    
    // 全域配置
    static var configuration = LoggerConfiguration()
    
    // 日誌歷史（用於搜尋和分析）
    private static var logHistory = LogHistory()
    
    // 錯誤追蹤器
    private static let errorTracker = ErrorTracker()
    
    // MARK: - 新增的日誌類別
    enum ExtendedCategory: String {
        case cache = "💾 CACHE"
        case sync = "🔄 SYNC"
        case analytics = "📊 ANALYTICS"
        case performance = "⚡ PERFORMANCE"
        case security = "🔒 SECURITY"
    }
    
    // MARK: - 配置方法
    
    /// 配置日誌系統
    static func configure(_ config: LoggerConfiguration) {
        configuration = config
        
        if config.fileOutputEnabled {
            LogFileManager.shared.setupLogFile()
        }
    }
    
    /// 設定最小日誌等級
    static func setMinimumLevel(_ level: Level) {
        configuration.minimumLevel = level
    }
    
    /// 啟用特定類別
    static func enableCategories(_ categories: Category...) {
        if configuration.enabledCategories == nil {
            configuration.enabledCategories = Set(categories)
        } else {
            categories.forEach { configuration.enabledCategories?.insert($0) }
        }
    }
    
    /// 禁用特定類別
    static func disableCategories(_ categories: Category...) {
        categories.forEach { configuration.enabledCategories?.remove($0) }
    }
    
    // MARK: - 增強的日誌方法
    
    /// 性能日誌
    static func performance(_ message: String, duration: TimeInterval, file: String = #file, function: String = #function, line: Int = #line) {
        let perfMessage = "\(message) - 耗時: \(String(format: "%.3f", duration))秒"
        log(perfMessage, level: .info, category: .general, isPerformance: true, file: file, function: function, line: line)
    }
    
    /// 追蹤函數執行時間
    static func measureTime<T>(label: String, category: Category = .general, operation: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            performance(label, duration: duration)
        }
        return try operation()
    }
    
    /// 帶有額外元數據的日誌
    static func logWithMetadata(_ message: String, level: Level, category: Category, metadata: [String: Any], file: String = #file, function: String = #function, line: Int = #line) {
        var enrichedMessage = message
        if !metadata.isEmpty {
            let metadataString = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            enrichedMessage += " | Metadata: {\(metadataString)}"
        }
        log(enrichedMessage, level: level, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - 日誌搜尋和過濾
    
    /// 搜尋日誌歷史
    static func searchLogs(keyword: String? = nil, level: Level? = nil, category: Category? = nil, timeRange: DateInterval? = nil) -> [LogEntry] {
        return logHistory.search(keyword: keyword, level: level, category: category, timeRange: timeRange)
    }
    
    /// 獲取最近的錯誤
    static func getRecentErrors(count: Int = 10) -> [LogEntry] {
        return logHistory.getRecentEntries(level: .error, count: count)
    }
    
    /// 導出日誌
    static func exportLogs(format: ExportFormat = .text) -> String {
        return logHistory.export(format: format)
    }
    
    // MARK: - 錯誤追蹤
    
    /// 記錄錯誤並追蹤
    static func trackError(_ error: Error, context: ErrorContext? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        errorTracker.track(error, context: context, file: file, function: function, line: line)
        
        let errorMessage = "錯誤: \(error.localizedDescription)"
        if let context = context {
            logWithMetadata(errorMessage, level: .error, category: .general, metadata: context.metadata, file: file, function: function, line: line)
        } else {
            Logger.error(errorMessage, category: .general, file: file, function: function, line: line)
        }
    }
    
    /// 獲取錯誤統計
    static func getErrorStatistics() -> ErrorStatistics {
        return errorTracker.getStatistics()
    }
    
    // MARK: - 核心日誌實現（重寫）
    
    internal static func log(_ message: String, level: Level, category: Category, isPerformance: Bool = false, file: String, function: String, line: Int) {
        // 檢查是否應該記錄此日誌
        guard shouldLog(level: level, category: category) else { return }
        
        let logEntry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            file: file,
            function: function,
            line: line,
            threadInfo: configuration.includeThreadInfo ? getThreadInfo() : nil
        )
        
        // 加入歷史記錄
        logHistory.add(logEntry)
        
        // 格式化日誌訊息
        let formattedMessage = formatLogMessage(logEntry)
        
        // 輸出到控制台
        if configuration.consoleOutputEnabled {
            #if DEBUG
            print(formattedMessage)
            #endif
        }
        
        // 輸出到系統日誌
        outputToSystemLog(logEntry)
        
        // 輸出到檔案
        if configuration.fileOutputEnabled {
            LogFileManager.shared.write(formattedMessage)
        }
        
        // 錯誤追蹤
        if level == .error {
            errorTracker.trackFromLog(logEntry)
        }
    }
    
    // MARK: - 輔助方法
    
    private static func shouldLog(level: Level, category: Category) -> Bool {
        // 檢查等級
        guard level.rawValue >= configuration.minimumLevel.rawValue else { return false }
        
        // 檢查類別
        if let enabledCategories = configuration.enabledCategories {
            return enabledCategories.contains(category)
        }
        
        return true
    }
    
    private static func formatLogMessage(_ entry: LogEntry) -> String {
        switch configuration.format {
        case .simple:
            return "\(entry.formattedTimestamp) \(entry.message)"
            
        case .standard:
            return "\(entry.formattedTimestamp) \(entry.level.rawValue) \(entry.category.rawValue) - \(entry.message)"
            
        case .detailed:
            var message = "\(entry.formattedTimestamp) \(entry.level.rawValue) \(entry.category.rawValue)"
            if configuration.includeCallSiteInfo {
                let fileName = (entry.file as NSString).lastPathComponent
                message += " [\(fileName):\(entry.line)] \(entry.function)"
            }
            if let threadInfo = entry.threadInfo {
                message += " [\(threadInfo)]"
            }
            message += " - \(entry.message)"
            return message
            
        case .json:
            return entry.toJSON()
        }
    }
    
    private static func outputToSystemLog(_ entry: LogEntry) {
        let osLogger = os.Logger(subsystem: "com.linker.app", category: entry.category.rawValue)
        
        switch entry.level {
        case .debug:
            osLogger.debug("\(entry.message)")
        case .info:
            osLogger.info("\(entry.message)")
        case .warning:
            osLogger.warning("\(entry.message)")
        case .error:
            osLogger.error("\(entry.message)")
        case .success:
            osLogger.info("✅ \(entry.message)")
        }
    }
    
    private static func getThreadInfo() -> String {
        if Thread.isMainThread {
            return "Main Thread"
        } else {
            return "Background Thread \(Thread.current.description)"
        }
    }
}

// MARK: - 日誌等級比較
extension Logger.Level: Comparable {
    public static func < (lhs: Logger.Level, rhs: Logger.Level) -> Bool {
        let order: [Logger.Level] = [.debug, .info, .success, .warning, .error]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - 日誌條目
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: Logger.Level
    let category: Logger.Category
    let message: String
    let file: String
    let function: String
    let line: Int
    let threadInfo: String?
    
    var formattedTimestamp: String {
        DateFormatter.logFormatter.string(from: timestamp)
    }
    
    func toJSON() -> String {
        let dict: [String: Any] = [
            "id": id.uuidString,
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "level": level.rawValue,
            "category": category.rawValue,
            "message": message,
            "file": (file as NSString).lastPathComponent,
            "function": function,
            "line": line,
            "thread": threadInfo ?? "Unknown"
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .sortedKeys),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "{}"
    }
}

// MARK: - 日誌歷史管理
class LogHistory {
    private var entries: [LogEntry] = []
    private let maxEntries = 1000
    private let queue = DispatchQueue(label: "com.linker.logger.history", attributes: .concurrent)
    
    func add(_ entry: LogEntry) {
        queue.async(flags: .barrier) {
            self.entries.append(entry)
            if self.entries.count > self.maxEntries {
                self.entries.removeFirst(self.entries.count - self.maxEntries)
            }
        }
    }
    
    func search(keyword: String?, level: Logger.Level?, category: Logger.Category?, timeRange: DateInterval?) -> [LogEntry] {
        return queue.sync {
            entries.filter { entry in
                if let keyword = keyword, !entry.message.localizedCaseInsensitiveContains(keyword) {
                    return false
                }
                if let level = level, entry.level != level {
                    return false
                }
                if let category = category, entry.category != category {
                    return false
                }
                if let timeRange = timeRange, !timeRange.contains(entry.timestamp) {
                    return false
                }
                return true
            }
        }
    }
    
    func getRecentEntries(level: Logger.Level? = nil, count: Int) -> [LogEntry] {
        return queue.sync {
            let filtered = level != nil ? entries.filter { $0.level == level } : entries
            return Array(filtered.suffix(count))
        }
    }
    
    func export(format: ExportFormat) -> String {
        return queue.sync {
            switch format {
            case .text:
                return entries.map { entry in
                    "\(entry.formattedTimestamp) [\(entry.level.rawValue)] [\(entry.category.rawValue)] \(entry.message)"
                }.joined(separator: "\n")
                
            case .json:
                let jsonArray = entries.map { $0.toJSON() }
                return "[\n\(jsonArray.joined(separator: ",\n"))\n]"
                
            case .csv:
                var csv = "Timestamp,Level,Category,Message,File,Function,Line\n"
                csv += entries.map { entry in
                    "\"\(entry.formattedTimestamp)\",\"\(entry.level.rawValue)\",\"\(entry.category.rawValue)\",\"\(entry.message)\",\"\((entry.file as NSString).lastPathComponent)\",\"\(entry.function)\",\(entry.line)"
                }.joined(separator: "\n")
                return csv
            }
        }
    }
}

// MARK: - 錯誤追蹤
struct ErrorContext {
    let userId: String?
    let sessionId: String?
    let metadata: [String: Any]
    
    init(userId: String? = nil, sessionId: String? = nil, metadata: [String: Any] = [:]) {
        self.userId = userId
        self.sessionId = sessionId
        self.metadata = metadata
    }
}

class ErrorTracker {
    private var errors: [TrackedError] = []
    private let queue = DispatchQueue(label: "com.linker.logger.errors", attributes: .concurrent)
    
    struct TrackedError {
        let error: Error
        let context: ErrorContext?
        let timestamp: Date
        let file: String
        let function: String
        let line: Int
        let stackTrace: [String]
    }
    
    func track(_ error: Error, context: ErrorContext?, file: String, function: String, line: Int) {
        let stackTrace = Thread.callStackSymbols
        
        queue.async(flags: .barrier) {
            let trackedError = TrackedError(
                error: error,
                context: context,
                timestamp: Date(),
                file: file,
                function: function,
                line: line,
                stackTrace: stackTrace
            )
            self.errors.append(trackedError)
            
            // 保持最近 100 個錯誤
            if self.errors.count > 100 {
                self.errors.removeFirst(self.errors.count - 100)
            }
        }
    }
    
    func trackFromLog(_ entry: LogEntry) {
        queue.async(flags: .barrier) {
            let error = NSError(domain: "LoggerError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: entry.message
            ])
            
            let trackedError = TrackedError(
                error: error,
                context: nil,
                timestamp: entry.timestamp,
                file: entry.file,
                function: entry.function,
                line: entry.line,
                stackTrace: []
            )
            self.errors.append(trackedError)
        }
    }
    
    func getStatistics() -> ErrorStatistics {
        return queue.sync {
            let errorTypes = Dictionary(grouping: errors) { String(describing: type(of: $0.error)) }
            let errorCounts = errorTypes.mapValues { $0.count }
            
            let hourAgo = Date().addingTimeInterval(-3600)
            let recentErrors = errors.filter { $0.timestamp > hourAgo }.count
            
            return ErrorStatistics(
                totalErrors: errors.count,
                recentErrors: recentErrors,
                errorsByType: errorCounts.map { ($0.key, $0.value) },
                mostCommonError: errorCounts.max(by: { $0.value < $1.value })?.key
            )
        }
    }
}

struct ErrorStatistics {
    let totalErrors: Int
    let recentErrors: Int
    let errorsByType: [(String, Int)]
    let mostCommonError: String?
}

// MARK: - 日誌檔案管理
class LogFileManager {
    static let shared = LogFileManager()
    
    private var fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "com.linker.logger.file")
    
    private var logFileURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let logsDirectory = documentsDirectory.appendingPathComponent("Logs")
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        
        let dateString = DateFormatter.logFileDateFormatter.string(from: Date())
        return logsDirectory.appendingPathComponent("linker-\(dateString).log")
    }
    
    func setupLogFile() {
        queue.async {
            guard let url = self.logFileURL else { return }
            
            // 檢查檔案大小
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let fileSize = attributes[.size] as? Int64,
               Double(fileSize) / 1024 / 1024 > Logger.configuration.maxLogFileSize {
                // 旋轉日誌檔案
                self.rotateLogFile()
            }
            
            // 如果檔案不存在，創建它
            if !FileManager.default.fileExists(atPath: url.path) {
                FileManager.default.createFile(atPath: url.path, contents: nil)
            }
            
            // 開啟檔案句柄
            self.fileHandle = try? FileHandle(forWritingTo: url)
            self.fileHandle?.seekToEndOfFile()
        }
    }
    
    func write(_ message: String) {
        queue.async {
            guard let data = (message + "\n").data(using: .utf8) else { return }
            self.fileHandle?.write(data)
        }
    }
    
    private func rotateLogFile() {
        fileHandle?.closeFile()
        fileHandle = nil
        
        guard let currentURL = logFileURL else { return }
        let rotatedURL = currentURL.deletingPathExtension().appendingPathExtension("old.log")
        
        try? FileManager.default.removeItem(at: rotatedURL)
        try? FileManager.default.moveItem(at: currentURL, to: rotatedURL)
    }
}

// MARK: - 輸出格式
enum ExportFormat {
    case text
    case json
    case csv
}

// MARK: - 日期格式化擴展
private extension DateFormatter {
    static let logFileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}