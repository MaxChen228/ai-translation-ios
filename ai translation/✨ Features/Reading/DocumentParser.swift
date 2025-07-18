// DocumentParser.swift - 統一文件解析服務

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct DocumentParser {
    
    // MARK: - 主要解析入口
    
    static func parseDocument(from url: URL) async throws -> ParsedBook {
        print("📚 開始解析文件: \(url.lastPathComponent)")
        
        // 確保可以存取檔案
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentParseError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // 根據檔案類型選擇解析方法
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "epub":
            return try await parseEPUB(from: url)
        case "pdf":
            return try await parsePDF(from: url)
        case "txt":
            return try await parseTXT(from: url)
        default:
            throw DocumentParseError.unsupportedFormat(fileExtension)
        }
    }
    
    // MARK: - EPUB 解析（簡化版本）
    
    // MARK: - EPUB 解析（保留檔案路徑版本）
    private static func parseEPUB(from url: URL) async throws -> ParsedBook {
        print("📖 解析EPUB檔案...")
        
        // 提取基本資訊
        let fileName = url.deletingPathExtension().lastPathComponent
        let bookInfo = extractBookInfoFromFileName(fileName)
        
        // 不再生成demo內容，改為提供檔案路徑資訊
        let epubInfo = """
        這是一本EPUB電子書，檔案已成功匯入。
        
        檔案：\(url.lastPathComponent)
        書名：\(bookInfo.title)
        作者：\(bookInfo.author)
        
        點擊進入閱讀器以開始閱讀真實的EPUB內容。
        """
        
        let coverColor = generateCoverColor(for: bookInfo.title)
        
        return ParsedBook(
            title: bookInfo.title,
            author: bookInfo.author,
            content: epubInfo, // 簡短說明文字
            totalPages: 1, // EPUB將使用章節導航
            coverColor: coverColor,
            fileType: .epub
        )
    }
    
    // MARK: - PDF 解析
    
    private static func parsePDF(from url: URL) async throws -> ParsedBook {
        print("📄 解析PDF檔案...")
        
        guard let pdfDocument = PDFDocument(url: url) else {
            throw DocumentParseError.corruptedFile
        }
        
        // 提取PDF資訊
        let title = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
                   ?? url.deletingPathExtension().lastPathComponent
        let author = pdfDocument.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String
                    ?? "未知作者"
        
        // 提取文字內容
        var fullText = ""
        let pageCount = pdfDocument.pageCount
        
        for pageIndex in 0..<pageCount {
            if let page = pdfDocument.page(at: pageIndex),
               let pageText = page.string {
                fullText += pageText + "\n\n"
            }
        }
        
        let coverColor = generateCoverColor(for: title)
        
        return ParsedBook(
            title: title,
            author: author,
            content: fullText,
            totalPages: pageCount,
            coverColor: coverColor,
            fileType: .pdf
        )
    }
    
    // MARK: - TXT 解析
    
    private static func parseTXT(from url: URL) async throws -> ParsedBook {
        print("📝 解析TXT檔案...")
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let title = url.deletingPathExtension().lastPathComponent
        let pageCount = estimatePageCount(content: content)
        let coverColor = generateCoverColor(for: title)
        
        return ParsedBook(
            title: title,
            author: "未知作者",
            content: content,
            totalPages: pageCount,
            coverColor: coverColor,
            fileType: .txt
        )
    }
    
    // MARK: - 輔助方法
    
    private static func extractBookInfoFromFileName(_ fileName: String) -> (title: String, author: String) {
        // 嘗試從檔案名稱解析書名和作者
        // 處理常見格式如："書名 - 作者"、"作者 - 書名"等
        
        if fileName.contains(" - ") {
            let parts = fileName.components(separatedBy: " - ")
            if parts.count >= 2 {
                // 假設格式為 "書名 - 作者"
                let possibleTitle = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let possibleAuthor = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 如果作者部分包含"作者"、"Author"等關鍵字，則認為是作者
                if possibleAuthor.lowercased().contains("author") || possibleAuthor.contains("作者") {
                    return (possibleTitle, possibleAuthor)
                } else {
                    return (possibleTitle, possibleAuthor)
                }
            }
        }
        
        // 處理括號格式 "書名 (作者)"
        if let openParen = fileName.lastIndex(of: "("),
           let closeParen = fileName.lastIndex(of: ")"),
           openParen < closeParen {
            
            let title = String(fileName[..<openParen]).trimmingCharacters(in: .whitespacesAndNewlines)
            let author = String(fileName[fileName.index(after: openParen)..<closeParen])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return (title.isEmpty ? fileName : title, author.isEmpty ? "未知作者" : author)
        }
        
        // 如果無法解析，則使用檔案名稱作為書名
        return (fileName, "未知作者")
    }
    
    private static func estimatePageCount(content: String) -> Int {
        // 估算頁數：假設每頁600字
        let wordCount = content.count
        return max(1, (wordCount + 599) / 600)
    }
    
    private static func generateCoverColor(for title: String) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .indigo, .pink, .teal]
        let index = abs(title.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - 錯誤類型

enum DocumentParseError: LocalizedError {
    case accessDenied
    case unsupportedFormat(String)
    case corruptedFile
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "無法存取檔案"
        case .unsupportedFormat(let format):
            return "不支援的檔案格式: .\(format)"
        case .corruptedFile:
            return "檔案已損壞或格式錯誤"
        case .processingFailed(let reason):
            return "處理失敗: \(reason)"
        }
    }
}

// MARK: - 資料模型

struct ParsedBook {
    let title: String
    let author: String
    let content: String
    let totalPages: Int
    let coverColor: Color
    let fileType: SupportedFileType
}

struct EPUBBookInfo {
    let title: String
    let author: String
    let chapters: [EPUBChapter]
}

struct EPUBChapter {
    let title: String
    let fileName: String
    let content: String
}

enum SupportedFileType {
    case epub, pdf, txt
    
    var displayName: String {
        switch self {
        case .epub: return "EPUB"
        case .pdf: return "PDF"
        case .txt: return "文本檔案"
        }
    }
}
