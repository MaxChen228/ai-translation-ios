// ReaderModels.swift - 擴展後的閱讀器模型

import Foundation
import SwiftUI

// 書籍模型 - 添加content內容欄位
struct ReaderBook: Identifiable, Codable {
    let id: UUID
    var title: String
    var author: String
    var content: String // 新增：書籍完整內容
    var coverColor: Color
    var progress: Double
    var totalPages: Int
    var currentPage: Int
    var dateAdded: Date
    var lastRead: Date?
    var bookmarks: [ReaderBookmark]
    var notes: [ReaderNote]
    
    // 新增：檔案相關資訊
    var fileType: String?
    var originalFileName: String?
    var fileSize: Int64?
    
    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        content: String = "",
        coverColor: Color = .blue,
        progress: Double = 0.0,
        totalPages: Int,
        currentPage: Int = 1,
        dateAdded: Date = Date(),
        lastRead: Date? = nil,
        bookmarks: [ReaderBookmark] = [],
        notes: [ReaderNote] = [],
        fileType: String? = nil,
        originalFileName: String? = nil,
        fileSize: Int64? = nil
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
    }
    
    // 新增：取得指定頁數的內容
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
    
    // 新增：更新閱讀進度
    mutating func updateProgress(currentPage: Int) {
        self.currentPage = currentPage
        self.progress = Double(currentPage) / Double(totalPages)
        self.lastRead = Date()
    }
    
    // 新增：格式化檔案大小
    var formattedFileSize: String {
        guard let fileSize = fileSize else { return "未知" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
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
    
    init(id: UUID = UUID(), pageNumber: Int, position: Double, note: String = "", dateCreated: Date = Date()) {
        self.id = id
        self.pageNumber = pageNumber
        self.position = position
        self.note = note
        self.dateCreated = dateCreated
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
    
    init(id: UUID = UUID(), selectedText: String, note: String, pageNumber: Int, position: ReaderTextPosition, dateCreated: Date = Date()) {
        self.id = id
        self.selectedText = selectedText
        self.note = note
        self.pageNumber = pageNumber
        self.position = position
        self.dateCreated = dateCreated
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
        case cream = "米色"
        case dark = "深色"
        
        var color: Color {
            switch self {
            case .white: return .white
            case .cream: return Color(red: 0.98, green: 0.96, blue: 0.89)
            case .dark: return Color(red: 0.1, green: 0.1, blue: 0.1)
            }
        }
        
        var textColor: Color {
            switch self {
            case .white, .cream: return .black
            case .dark: return .white
            }
        }
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    // 新增：獲取適合的字體
    func getUIFont(size: CGFloat, for text: String) -> UIFont {
        // 檢測文字主要語言
        let chineseCharCount = text.filter { $0.isChineseCharacter }.count
        let totalCharCount = text.count
        
        let isMainlyChinese = Double(chineseCharCount) / Double(totalCharCount) > 0.3
        
        if isMainlyChinese {
            return UIFont(name: chineseFontFamily.fontName, size: size) ?? UIFont.systemFont(ofSize: size)
        } else {
            return UIFont(name: englishFontFamily.fontName, size: size) ?? UIFont.systemFont(ofSize: size)
        }
    }
    
    // 新增：獲取SwiftUI Font (用於預覽)
    func getFont(size: CGFloat, for text: String) -> Font {
        let chineseCharCount = text.filter { $0.isChineseCharacter }.count
        let totalCharCount = text.count
        
        let isMainlyChinese = Double(chineseCharCount) / Double(totalCharCount) > 0.3
        
        if isMainlyChinese {
            return .custom(chineseFontFamily.fontName, size: size)
        } else {
            return .custom(englishFontFamily.fontName, size: size)
        }
    }
}

// 字符擴展：檢測中文字符
extension Character {
    var isChineseCharacter: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return (0x4E00...0x9FFF).contains(scalar.value) || // CJK統一漢字
               (0x3400...0x4DBF).contains(scalar.value) || // CJK擴展A
               (0x20000...0x2A6DF).contains(scalar.value) || // CJK擴展B
               (0x2A700...0x2B73F).contains(scalar.value) || // CJK擴展C
               (0x2B740...0x2B81F).contains(scalar.value) || // CJK擴展D
               (0x2B820...0x2CEAF).contains(scalar.value)    // CJK擴展E
    }
}
