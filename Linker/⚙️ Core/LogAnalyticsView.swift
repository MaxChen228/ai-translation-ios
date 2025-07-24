// LogAnalyticsView.swift - 日誌分析視圖
// 提供視覺化的日誌查看和分析功能

import SwiftUI
import Charts

// MARK: - 日誌分析視圖
struct LogAnalyticsView: View {
    @State private var selectedLevel: Logger.Level? = nil
    @State private var selectedCategory: Logger.Category? = nil
    @State private var searchText = ""
    @State private var showingExportOptions = false
    @State private var timeRange = TimeRange.lastHour
    
    // 日誌統計
    @State private var logStats = LogStatistics()
    @State private var errorStats = Logger.getErrorStatistics()
    @State private var filteredLogs: [LogEntry] = []
    
    enum TimeRange: String, CaseIterable {
        case lastMinute = "最近 1 分鐘"
        case lastHour = "最近 1 小時"
        case lastDay = "最近 24 小時"
        case all = "全部"
        
        var dateInterval: DateInterval? {
            let now = Date()
            switch self {
            case .lastMinute:
                return DateInterval(start: now.addingTimeInterval(-60), end: now)
            case .lastHour:
                return DateInterval(start: now.addingTimeInterval(-3600), end: now)
            case .lastDay:
                return DateInterval(start: now.addingTimeInterval(-86400), end: now)
            case .all:
                return nil
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 統計概覽
                statisticsOverview
                
                // 過濾器
                filterBar
                
                // 日誌列表
                logsList
            }
            .navigationTitle("日誌分析")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    exportButton
                }
            }
            .onAppear {
                refreshData()
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView()
            }
        }
    }
    
    // MARK: - 統計概覽
    
    private var statisticsOverview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ModernSpacing.md) {
                // 總日誌數
                StatCard(
                    title: "總日誌數",
                    value: "\(logStats.totalLogs)",
                    icon: "doc.text",
                    color: .blue
                )
                
                // 錯誤數
                StatCard(
                    title: "錯誤",
                    value: "\(logStats.errorCount)",
                    subtitle: "最近 1 小時: \(errorStats.recentErrors)",
                    icon: "exclamationmark.triangle",
                    color: .red
                )
                
                // 警告數
                StatCard(
                    title: "警告",
                    value: "\(logStats.warningCount)",
                    icon: "exclamationmark.circle",
                    color: .orange
                )
                
                // 平均每分鐘日誌
                StatCard(
                    title: "日誌頻率",
                    value: String(format: "%.1f", logStats.logsPerMinute),
                    subtitle: "條/分鐘",
                    icon: "speedometer",
                    color: .green
                )
            }
            .padding(.horizontal, ModernSpacing.md)
        }
        .padding(.vertical, ModernSpacing.md)
    }
    
    // MARK: - 過濾器欄
    
    private var filterBar: some View {
        VStack(spacing: ModernSpacing.sm) {
            // 搜尋欄
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜尋日誌...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, ModernSpacing.md)
            
            // 過濾選項
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ModernSpacing.sm) {
                    // 時間範圍
                    Menu {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(action: { timeRange = range }) {
                                Label(range.rawValue, systemImage: timeRange == range ? "checkmark" : "")
                            }
                        }
                    } label: {
                        FilterChip(
                            title: timeRange.rawValue,
                            icon: "clock",
                            isSelected: true
                        )
                    }
                    
                    // 日誌等級
                    ForEach(Logger.Level.allCases, id: \.self) { level in
                        FilterChip(
                            title: level.rawValue,
                            isSelected: selectedLevel == level,
                            color: colorForLevel(level)
                        ) {
                            if selectedLevel == level {
                                selectedLevel = nil
                            } else {
                                selectedLevel = level
                            }
                        }
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    // 日誌類別
                    ForEach(categoryOptions, id: \.self) { category in
                        FilterChip(
                            title: category.rawValue,
                            isSelected: selectedCategory == category
                        ) {
                            if selectedCategory == category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, ModernSpacing.md)
            }
        }
        .padding(.vertical, ModernSpacing.sm)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 日誌列表
    
    private var logsList: some View {
        List(filteredLogs) { log in
            LogEntryRow(entry: log)
                .listRowInsets(EdgeInsets(
                    top: ModernSpacing.xs,
                    leading: ModernSpacing.md,
                    bottom: ModernSpacing.xs,
                    trailing: ModernSpacing.md
                ))
        }
        .listStyle(PlainListStyle())
        .refreshable {
            refreshData()
        }
    }
    
    // MARK: - 匯出按鈕
    
    private var exportButton: some View {
        Button(action: { showingExportOptions = true }) {
            Image(systemName: "square.and.arrow.up")
        }
    }
    
    // MARK: - 輔助方法
    
    private func refreshData() {
        // 獲取日誌
        filteredLogs = Logger.searchLogs(
            keyword: searchText.isEmpty ? nil : searchText,
            level: selectedLevel,
            category: selectedCategory,
            timeRange: timeRange.dateInterval
        )
        
        // 更新統計
        updateStatistics()
    }
    
    private func updateStatistics() {
        logStats = LogStatistics()
        
        // 計算統計數據
        for log in filteredLogs {
            logStats.totalLogs += 1
            
            switch log.level {
            case .error:
                logStats.errorCount += 1
            case .warning:
                logStats.warningCount += 1
            default:
                break
            }
        }
        
        // 計算日誌頻率
        if let firstLog = filteredLogs.first,
           let lastLog = filteredLogs.last {
            let duration = lastLog.timestamp.timeIntervalSince(firstLog.timestamp) / 60.0
            if duration > 0 {
                logStats.logsPerMinute = Double(filteredLogs.count) / duration
            }
        }
        
        // 更新錯誤統計
        errorStats = Logger.getErrorStatistics()
    }
    
    private func colorForLevel(_ level: Logger.Level) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .success: return .green
        }
    }
    
    private var categoryOptions: [Logger.Category] {
        [.network, .authentication, .database, .ui, .learning, .api, .general]
    }
}

// MARK: - 日誌條目行
struct LogEntryRow: View {
    let entry: LogEntry
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.xs) {
            // 主要內容
            HStack(alignment: .top, spacing: ModernSpacing.sm) {
                // 等級指示器
                Circle()
                    .fill(colorForLevel(entry.level))
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                
                // 日誌內容
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.message)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(isExpanded ? nil : 2)
                    
                    HStack(spacing: ModernSpacing.md) {
                        // 時間戳
                        Label(entry.formattedTimestamp, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 類別
                        Text(entry.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemFill))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // 展開按鈕
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            // 展開的詳細資訊
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    
                    DetailRow(label: "檔案", value: (entry.file as NSString).lastPathComponent)
                    DetailRow(label: "函數", value: entry.function)
                    DetailRow(label: "行號", value: "\(entry.line)")
                    
                    if let thread = entry.threadInfo {
                        DetailRow(label: "執行緒", value: thread)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 20)
            }
        }
        .padding(.vertical, ModernSpacing.xs)
    }
    
    private func colorForLevel(_ level: Logger.Level) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .success: return .green
        }
    }
}

// MARK: - 詳細資訊行
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .fontWeight(.medium)
                .frame(width: 60, alignment: .trailing)
            Text(value)
                .font(.system(.caption, design: .monospaced))
        }
    }
}

// MARK: - 統計卡片
struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.xs) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(ModernSpacing.md)
        .frame(width: 140)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(ModernRadius.md)
    }
}

// MARK: - 過濾器晶片
struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    var color: Color = .accentColor
    let action: (() -> Void)?
    
    init(title: String, icon: String? = nil, isSelected: Bool, color: Color = .accentColor, action: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color(.tertiarySystemFill))
            .foregroundColor(isSelected ? color : .primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
        .disabled(action == nil)
    }
}

// MARK: - 匯出選項視圖
struct ExportOptionsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("選擇匯出格式") {
                    ExportOptionRow(
                        title: "純文字",
                        subtitle: "簡單的文字格式，適合閱讀",
                        icon: "doc.text",
                        format: .text
                    )
                    
                    ExportOptionRow(
                        title: "JSON",
                        subtitle: "結構化數據，適合程式處理",
                        icon: "doc.badge.gearshape",
                        format: .json
                    )
                    
                    ExportOptionRow(
                        title: "CSV",
                        subtitle: "表格格式，可用 Excel 開啟",
                        icon: "tablecells",
                        format: .csv
                    )
                }
            }
            .navigationTitle("匯出日誌")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 匯出選項行
struct ExportOptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let format: ExportFormat
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Button(action: { exportLogs() }) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private func exportLogs() {
        let _ = Logger.exportLogs(format: format)
        
        // 這裡可以實現實際的分享功能
        // 例如使用 UIActivityViewController
        
        dismiss()
    }
}

// MARK: - 日誌統計
struct LogStatistics {
    var totalLogs = 0
    var errorCount = 0
    var warningCount = 0
    var logsPerMinute = 0.0
}

// MARK: - 預覽
#if DEBUG
struct LogAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        LogAnalyticsView()
    }
}
#endif