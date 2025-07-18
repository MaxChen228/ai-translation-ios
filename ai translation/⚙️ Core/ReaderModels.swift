// ReaderModels.swift

import Foundation
import SwiftUI

// 書籍模型
struct ReaderBook: Identifiable, Codable {
    let id: UUID
    var title: String
    var author: String
    var content: String = ""
    var coverColor: Color = .blue
    var progress: Double = 0.0
    var totalPages: Int
    var currentPage: Int = 1
    var dateAdded: Date
    var lastRead: Date?
    var bookmarks: [ReaderBookmark] = []
    var notes: [ReaderNote] = []
    
    // 編碼相關
    private enum CodingKeys: String, CodingKey {
        case id, title, author, content, progress, totalPages, currentPage, dateAdded, lastRead, bookmarks, notes
        case coverColorData
    }
    
    init(id: UUID = UUID(), title: String, author: String, content: String = "", coverColor: Color = .blue, progress: Double = 0.0, totalPages: Int, currentPage: Int = 1, dateAdded: Date = Date(), lastRead: Date? = nil) {
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
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decode(String.self, forKey: .author)
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        progress = try container.decode(Double.self, forKey: .progress)
        totalPages = try container.decode(Int.self, forKey: .totalPages)
        currentPage = try container.decode(Int.self, forKey: .currentPage)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        lastRead = try container.decodeIfPresent(Date.self, forKey: .lastRead)
        bookmarks = try container.decodeIfPresent([ReaderBookmark].self, forKey: .bookmarks) ?? []
        notes = try container.decodeIfPresent([ReaderNote].self, forKey: .notes) ?? []
        
        // 處理顏色編碼
        if let colorData = try container.decodeIfPresent(Data.self, forKey: .coverColorData) {
            // 這裡可以實作顏色的序列化，暫時用預設值
            coverColor = .blue
        } else {
            coverColor = .blue
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(author, forKey: .author)
        try container.encode(content, forKey: .content)
        try container.encode(progress, forKey: .progress)
        try container.encode(totalPages, forKey: .totalPages)
        try container.encode(currentPage, forKey: .currentPage)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encodeIfPresent(lastRead, forKey: .lastRead)
        try container.encode(bookmarks, forKey: .bookmarks)
        try container.encode(notes, forKey: .notes)
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

// 筆記模型（將來會整合知識點）
struct ReaderNote: Identifiable, Codable {
    let id: UUID
    var selectedText: String
    var note: String
    var pageNumber: Int
    var position: ReaderTextPosition
    var dateCreated: Date
    var isKnowledgePoint: Bool = false // 是否轉為知識點
    var knowledgePointId: Int? // 關聯的知識點ID
    
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
    var fontFamily: String = "系統字體"
    var lineSpacing: Double = 1.5
    var pageMargin: Double = 20.0
    var backgroundColor: ReaderBackgroundColor = .white
    var autoSaveProgress: Bool = true
    
    enum ReaderBackgroundColor: String, CaseIterable, Codable {
        case white = "白色"
        case sepia = "護眼黃"
        case dark = "深色"
        
        var color: Color {
            switch self {
            case .white: return .white
            case .sepia: return Color(red: 0.98, green: 0.96, blue: 0.89)
            case .dark: return Color(.systemBackground)
            }
        }
    }
}
