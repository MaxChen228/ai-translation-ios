// ReaderModels.swift - 擴展後的閱讀器模型

import Foundation
import SwiftUI

// 書籍模型 - 添加EPUB相關支援
struct ReaderBook: Identifiable, Codable {
    let id: UUID
    var title: String
    var author: String
    var content: String // 保留用於文字內容書籍
    var coverColor: Color
    var progress: Double
    var totalPages: Int
    var currentPage: Int
    var dateAdded: Date
    var lastRead: Date?
    var bookmarks: [ReaderBookmark]
    var notes: [ReaderNote]
    
    // 檔案相關資訊
    var fileType: String?
    var originalFileName: String?
    var fileSize: Int64?
    
    // 新增：EPUB相關屬性
    var originalFilePath: String? // EPUB檔案在Documents/Books中的路徑
    var epubChapters: [EPUBChapterInfo]? // EPUB章節資訊
    var currentChapterIndex: Int = 0 // 當前章節索引
    
    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        content: String = "",
        coverColor: Color = Color.modernSpecial,
        progress: Double = 0.0,
        totalPages: Int,
        currentPage: Int = 1,
        dateAdded: Date = Date(),
        lastRead: Date? = nil,
        bookmarks: [ReaderBookmark] = [],
        notes: [ReaderNote] = [],
        fileType: String? = nil,
        originalFileName: String? = nil,
        fileSize: Int64? = nil,
        originalFilePath: String? = nil,
        epubChapters: [EPUBChapterInfo]? = nil,
        currentChapterIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.content = content
        self.coverColor = coverColor
        self.progress = progress
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.dateAdded = dateAdded
        self.lastRead = lastRead
        self.bookmarks = bookmarks
        self.notes = notes
        self.fileType = fileType
        self.originalFileName = originalFileName
        self.fileSize = fileSize
        self.originalFilePath = originalFilePath
        self.epubChapters = epubChapters
        self.currentChapterIndex = currentChapterIndex
    }
    
    // 檢查是否為EPUB檔案
    var isEPUB: Bool {
        return fileType?.lowercased() == "epub"
    }
    
    // 取得當前章節
    var currentChapter: EPUBChapterInfo? {
        guard let chapters = epubChapters,
              currentChapterIndex < chapters.count else { return nil }
        return chapters[currentChapterIndex]
    }
    
    // 取得指定頁數的內容（用於非EPUB檔案）
    func getPageContent(page: Int, wordsPerPage: Int = 600) -> String {
        let startIndex = max(0, (page - 1) * wordsPerPage)
        let endIndex = min(content.count, startIndex + wordsPerPage)
        
        if startIndex >= content.count {
            return ""
        }
        
        let startStringIndex = content.index(content.startIndex, offsetBy: startIndex)
        let endStringIndex = content.index(content.startIndex, offsetBy: endIndex)
        
        return String(content[startStringIndex..<endStringIndex])
    }
    
    // 更新閱讀進度
    mutating func updateProgress(currentPage: Int) {
        self.currentPage = currentPage
        self.progress = Double(currentPage) / Double(totalPages)
        self.lastRead = Date()
    }
    
    // 更新EPUB章節進度
    mutating func updateChapterProgress(chapterIndex: Int) {
        self.currentChapterIndex = chapterIndex
        if let chapters = epubChapters {
            self.progress = Double(chapterIndex) / Double(chapters.count)
        }
        self.lastRead = Date()
    }
    
    // 格式化檔案大小
    var formattedFileSize: String {
        guard let fileSize = fileSize else { return "未知" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

// 新增：EPUB章節資訊模型
struct EPUBChapterInfo: Identifiable, Codable {
    let id: UUID = UUID()
    let title: String
    let htmlFileName: String // HTML檔案名稱
    let order: Int // 章節順序
    let href: String // 相對於EPUB根目錄的路徑
    
    init(title: String, htmlFileName: String, order: Int, href: String) {
        self.title = title
        self.htmlFileName = htmlFileName
        self.order = order
        self.href = href
    }
}

// Color的Codable支援
extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decode(Double.self, forKey: .alpha)
        
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // 使用UIColor來獲取RGB值
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        try container.encode(Double(red), forKey: .red)
        try container.encode(Double(green), forKey: .green)
        try container.encode(Double(blue), forKey: .blue)
        try container.encode(Double(alpha), forKey: .alpha)
    }
}

// 書籤模型
struct ReaderBookmark: Identifiable, Codable {
    let id: UUID
    var pageNumber: Int
    var position: Double // 頁面中的位置 0.0-1.0
    var note: String
    var dateCreated: Date
    
    // 新增：EPUB章節支援
    var chapterIndex: Int? // 對應的章節索引
    var chapterTitle: String? // 章節標題
    
    init(
        id: UUID = UUID(),
        pageNumber: Int,
        position: Double,
        note: String = "",
        dateCreated: Date = Date(),
        chapterIndex: Int? = nil,
        chapterTitle: String? = nil
    ) {
        self.id = id
        self.pageNumber = pageNumber
        self.position = position
        self.note = note
        self.dateCreated = dateCreated
        self.chapterIndex = chapterIndex
        self.chapterTitle = chapterTitle
    }
}

// 筆記模型
struct ReaderNote: Identifiable, Codable {
    let id: UUID
    var selectedText: String
    var note: String
    var pageNumber: Int
    var position: ReaderTextPosition
    var dateCreated: Date
    var isKnowledgePoint: Bool = false
    var knowledgePointId: Int?
    
    // 新增：EPUB章節支援
    var chapterIndex: Int? // 對應的章節索引
    var chapterTitle: String? // 章節標題
    
    init(
        id: UUID = UUID(),
        selectedText: String,
        note: String,
        pageNumber: Int,
        position: ReaderTextPosition,
        dateCreated: Date = Date(),
        chapterIndex: Int? = nil,
        chapterTitle: String? = nil
    ) {
        self.id = id
        self.selectedText = selectedText
        self.note = note
        self.pageNumber = pageNumber
        self.position = position
        self.dateCreated = dateCreated
        self.chapterIndex = chapterIndex
        self.chapterTitle = chapterTitle
    }
}

// 文字位置模型
struct ReaderTextPosition: Codable {
    var startIndex: Int
    var endIndex: Int
    var pageNumber: Int
    
    init(startIndex: Int, endIndex: Int, pageNumber: Int) {
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.pageNumber = pageNumber
    }
}

// 閱讀設定
struct ReaderSettings: Codable {
    var fontSize: Double = 16.0
    var chineseFontFamily: ChineseFontFamily = .sourceHanSerif
    var englishFontFamily: EnglishFontFamily = .rounded
    var lineSpacing: Double = 1.5
    var pageMargin: Double = 20.0
    var backgroundColor: ReaderBackgroundColor = .white
    var autoSaveProgress: Bool = true
    
    enum ChineseFontFamily: String, CaseIterable, Codable {
        case sourceHanSerif = "思源宋體"
        case system = "系統字體"
        
        var fontName: String {
            switch self {
            case .sourceHanSerif: return "SourceHanSerifTC-Regular"
            case .system: return "PingFangTC-Regular"
            }
        }
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    enum EnglishFontFamily: String, CaseIterable, Codable {
        case rounded = "圓潤字體"
        case serif = "襯線字體"
        case system = "系統字體"
        
        var fontName: String {
            switch self {
            case .rounded: return "SFProRounded-Regular"
            case .serif: return "TimesNewRomanPSMT"
            case .system: return "SFProText-Regular"
            }
        }
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    enum ReaderBackgroundColor: String, CaseIterable, Codable {
        case white = "白色"
        case sepia = "護眼色"
        case dark = "深色"
        
        var color: Color {
            switch self {
            case .white: return .white
            case .sepia: return Color(.systemBackground)
            case .dark: return Color(.systemBackground)
            }
        }
        
        var displayName: String {
            return self.rawValue
        }
    }
}
