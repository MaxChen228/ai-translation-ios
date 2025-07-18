// BookImporter.swift - 書籍匯入管理服務

import Foundation
import SwiftUI

@MainActor
class BookImporter: ObservableObject {
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0
    @Published var importStatus = ""
    @Published var lastError: ImportError?
    
    private let storageManager = BookStorageManager()
    
    // MARK: - 主要匯入方法
    
    func importBooks(from urls: [URL]) async -> [ReaderBook] {
        isImporting = true
        importProgress = 0.0
        lastError = nil
        
        var importedBooks: [ReaderBook] = []
        
        for (index, url) in urls.enumerated() {
            do {
                updateStatus("正在匯入 \(url.lastPathComponent)...")
                
                // 解析文件
                let parsedBook = try await DocumentParser.parseDocument(from: url)
                
                // 轉換為ReaderBook
                let readerBook = convertToReaderBook(parsedBook)
                
                // 儲存到本地
                try await storageManager.saveBook(readerBook, originalURL: url)
                
                importedBooks.append(readerBook)
                
                // 更新進度
                importProgress = Double(index + 1) / Double(urls.count)
                
            } catch {
                print("❌ 匯入失敗: \(url.lastPathComponent) - \(error)")
                lastError = ImportError(fileName: url.lastPathComponent, underlyingError: error)
            }
        }
        
        updateStatus(importedBooks.isEmpty ? "匯入失敗" : "匯入完成")
        isImporting = false
        
        return importedBooks
    }
    
    func importSingleBook(from url: URL) async -> ReaderBook? {
        isImporting = true
        importProgress = 0.0
        lastError = nil
        
        defer {
            isImporting = false
        }
        
        do {
            updateStatus("正在解析 \(url.lastPathComponent)...")
            
            // 解析文件
            let parsedBook = try await DocumentParser.parseDocument(from: url)
            
            // 轉換為ReaderBook
            let readerBook = convertToReaderBook(parsedBook)
            
            // 儲存到本地
            try await storageManager.saveBook(readerBook, originalURL: url)
            
            updateStatus("匯入完成")
            importProgress = 1.0
            
            return readerBook
            
        } catch {
            print("❌ 匯入失敗: \(url.lastPathComponent) - \(error)")
            
            // 針對不同錯誤類型提供更友善的訊息
            let friendlyError: ImportError
            if let docError = error as? DocumentParseError {
                switch docError {
                case .unsupportedFormat(let format):
                    friendlyError = ImportError(
                        fileName: url.lastPathComponent,
                        underlyingError: DocumentParseError.processingFailed("不支援 .\(format) 檔案格式")
                    )
                default:
                    friendlyError = ImportError(fileName: url.lastPathComponent, underlyingError: error)
                }
            } else {
                friendlyError = ImportError(fileName: url.lastPathComponent, underlyingError: error)
            }
            
            lastError = friendlyError
            updateStatus("匯入失敗")
            
            return nil
        }
    }
    
    // MARK: - 私有方法
    
    private func convertToReaderBook(_ parsedBook: ParsedBook) -> ReaderBook {
        return ReaderBook(
            id: UUID(),
            title: parsedBook.title,
            author: parsedBook.author,
            content: parsedBook.content,
            coverColor: parsedBook.coverColor,
            progress: 0.0,
            totalPages: parsedBook.totalPages,
            currentPage: 1,
            dateAdded: Date(),
            lastRead: nil
        )
    }
    
    private func updateStatus(_ status: String) {
        importStatus = status
        print("📚 匯入狀態: \(status)")
    }
}

// MARK: - 書籍儲存管理

class BookStorageManager {
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var booksDirectory: URL {
        documentsDirectory.appendingPathComponent("Books")
    }
    
    init() {
        createBooksDirectoryIfNeeded()
    }
    
    func saveBook(_ book: ReaderBook, originalURL: URL) async throws {
        let bookDirectory = booksDirectory.appendingPathComponent(book.id.uuidString)
        try fileManager.createDirectory(at: bookDirectory, withIntermediateDirectories: true)
        
        // 儲存書籍元資料
        let metadataURL = bookDirectory.appendingPathComponent("metadata.json")
        let metadataData = try JSONEncoder().encode(book)
        try metadataData.write(to: metadataURL)
        
        // 複製原始檔案
        let originalFileName = originalURL.lastPathComponent
        let savedFileURL = bookDirectory.appendingPathComponent(originalFileName)
        
        if originalURL.startAccessingSecurityScopedResource() {
            defer { originalURL.stopAccessingSecurityScopedResource() }
            try fileManager.copyItem(at: originalURL, to: savedFileURL)
        }
        
        print("✅ 書籍已儲存: \(book.title)")
    }
    
    func loadAllBooks() throws -> [ReaderBook] {
        guard fileManager.fileExists(atPath: booksDirectory.path) else {
            return []
        }
        
        let bookDirectories = try fileManager.contentsOfDirectory(
            at: booksDirectory,
            includingPropertiesForKeys: nil
        )
        
        var books: [ReaderBook] = []
        
        for bookDir in bookDirectories {
            let metadataURL = bookDir.appendingPathComponent("metadata.json")
            
            if fileManager.fileExists(atPath: metadataURL.path) {
                do {
                    let data = try Data(contentsOf: metadataURL)
                    let book = try JSONDecoder().decode(ReaderBook.self, from: data)
                    books.append(book)
                } catch {
                    print("⚠️ 無法載入書籍元資料: \(bookDir.lastPathComponent)")
                }
            }
        }
        
        return books.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    func deleteBook(_ book: ReaderBook) throws {
        let bookDirectory = booksDirectory.appendingPathComponent(book.id.uuidString)
        try fileManager.removeItem(at: bookDirectory)
        print("🗑️ 已刪除書籍: \(book.title)")
    }
    
    private func createBooksDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: booksDirectory.path) {
            try? fileManager.createDirectory(at: booksDirectory, withIntermediateDirectories: true)
        }
    }
}

// MARK: - 錯誤處理

struct ImportError: LocalizedError, Identifiable, Equatable {
    let id = UUID()
    let fileName: String
    let underlyingError: Error
    
    var errorDescription: String? {
        "無法匯入 \(fileName): \(underlyingError.localizedDescription)"
    }
    
    // MARK: - Equatable 實作
    static func == (lhs: ImportError, rhs: ImportError) -> Bool {
        lhs.id == rhs.id &&
        lhs.fileName == rhs.fileName &&
        lhs.underlyingError.localizedDescription == rhs.underlyingError.localizedDescription
    }
}
