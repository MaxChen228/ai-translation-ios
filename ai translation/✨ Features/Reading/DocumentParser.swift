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
    
    // MARK: - EPUB 解析
    
    private static func parseEPUB(from url: URL) async throws -> ParsedBook {
        print("📖 解析EPUB檔案...")
        
        // 創建臨時目錄來解壓EPUB
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // 解壓EPUB檔案 (EPUB其實是ZIP格式)
        try await unzipFile(from: url, to: tempDir)
        
        // 解析META-INF/container.xml找到OPF檔案
        let containerPath = tempDir.appendingPathComponent("META-INF/container.xml")
        let opfPath = try parseContainerXML(containerPath)
        let opfFullPath = tempDir.appendingPathComponent(opfPath)
        
        // 解析OPF檔案獲取書籍資訊
        let bookInfo = try parseOPF(opfFullPath)
        
        // 提取書籍內容
        let content = try await extractEPUBContent(from: tempDir, bookInfo: bookInfo)
        
        // 生成封面顏色
        let coverColor = generateCoverColor(for: bookInfo.title)
        
        return ParsedBook(
            title: bookInfo.title,
            author: bookInfo.author,
            content: content,
            totalPages: estimatePageCount(content: content),
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
    
    private static func unzipFile(from sourceURL: URL, to destinationURL: URL) async throws {
        // 簡化版解壓縮實作 - 在實際專案中建議使用ZIPFoundation框架
        // 這裡用Task模擬非同步操作
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // TODO: 實作實際的ZIP解壓縮
        // 暫時拋出錯誤提示需要實作
        throw DocumentParseError.processingFailed("ZIP解壓縮功能需要整合ZIPFoundation框架")
    }
    
    private static func parseContainerXML(_ url: URL) throws -> String {
        // 解析container.xml找到OPF檔案路徑
        // 簡化實作，實際需要XML解析
        return "OEBPS/content.opf" // 常見的預設路徑
    }
    
    private static func parseOPF(_ url: URL) throws -> EPUBBookInfo {
        // 解析OPF檔案獲取書籍元資料
        // 簡化實作，實際需要XML解析
        return EPUBBookInfo(
            title: "解析中的書籍",
            author: "解析中的作者",
            chapters: []
        )
    }
    
    private static func extractEPUBContent(from baseURL: URL, bookInfo: EPUBBookInfo) async throws -> String {
        // 提取並合併所有章節內容
        // 簡化實作
        return "EPUB內容解析中，需要整合完整的EPUB解析庫..."
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
