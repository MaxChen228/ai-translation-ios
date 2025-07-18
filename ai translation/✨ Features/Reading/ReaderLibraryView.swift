// ReaderLibraryView.swift - 重構版本，支援真實檔案匯入

import SwiftUI
import UniformTypeIdentifiers

struct ReaderLibraryView: View {
    @StateObject private var bookImporter = BookImporter()
    @State private var books: [ReaderBook] = []
    @State private var showingFileImporter = false
    @State private var selectedBook: ReaderBook?
    @State private var searchText = ""
    @State private var showingImportProgress = false
    @State private var showingErrorAlert = false
    
    private var filteredBooks: [ReaderBook] {
        if searchText.isEmpty {
            return books
        } else {
            return books.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // 歡迎卡片或匯入進度
                    if bookImporter.isImporting {
                        ImportProgressCard(
                            progress: bookImporter.importProgress,
                            status: bookImporter.importStatus
                        )
                    } else if books.isEmpty {
                        WelcomeCard {
                            showingFileImporter = true
                        }
                    }
                    
                    // 最近閱讀
                    if !books.isEmpty {
                        RecentBooksSection(books: filteredBooks) { book in
                            selectedBook = book
                        }
                    }
                    
                    // 我的圖書館
                    if !books.isEmpty {
                        LibrarySection(books: filteredBooks) { book in
                            selectedBook = book
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("📚 我的圖書館")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "搜尋書籍")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFileImporter = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.orange)
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.epub, .pdf, .plainText],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .fullScreenCover(item: $selectedBook) { book in
            ReaderView(book: book)
        }
        .alert("匯入錯誤", isPresented: $showingErrorAlert) {
            Button("確定") { }
        } message: {
            if let error = bookImporter.lastError {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            loadBooks()
        }
        .onChange(of: bookImporter.lastError) { _, error in
            if error != nil {
                showingErrorAlert = true
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func loadBooks() {
        do {
            let storageManager = BookStorageManager()
            books = try storageManager.loadAllBooks()
            print("📚 載入了 \(books.count) 本書籍")
        } catch {
            print("❌ 載入書籍失敗: \(error)")
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                let importedBooks = await bookImporter.importBooks(from: urls)
                
                // 將新匯入的書籍加入列表
                await MainActor.run {
                    books.append(contentsOf: importedBooks)
                    print("✅ 成功匯入 \(importedBooks.count) 本書籍")
                }
            }
        case .failure(let error):
            print("❌ 檔案選擇失敗: \(error.localizedDescription)")
        }
    }
}

// MARK: - 子組件

struct WelcomeCard: View {
    let onImportBook: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.linearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("開始您的閱讀之旅")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                
                VStack(spacing: 4) {
                    Text("支援 EPUB、PDF、TXT 格式")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    
                    Text("匯入您的第一本電子書開始閱讀")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            }
            
            Button(action: onImportBook) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("匯入電子書")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.linearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                }
            }
            
            // 支援格式說明
            HStack(spacing: 16) {
                ForEach(["EPUB", "PDF", "TXT"], id: \.self) { format in
                    Text(format)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray6))
                        }
                }
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

struct ImportProgressCard: View {
    let progress: Double
    let status: String
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                
                Text("正在匯入書籍")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(status)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

struct RecentBooksSection: View {
    let books: [ReaderBook]
    let onBookTap: (ReaderBook) -> Void
    
    private var recentBooks: [ReaderBook] {
        books.sorted { $0.lastRead ?? Date.distantPast > $1.lastRead ?? Date.distantPast }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最近閱讀")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
            
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(recentBooks) { book in
                        RecentBookCard(book: book) {
                            onBookTap(book)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -20)
        }
    }
}

struct RecentBookCard: View {
    let book: ReaderBook
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // 書籍封面
                RoundedRectangle(cornerRadius: 8)
                    .fill(book.coverColor.opacity(0.8))
                    .frame(width: 100, height: 140)
                    .overlay {
                        VStack {
                            Text(book.title)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                            
                            Spacer()
                            
                            Text(book.author)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                        .padding(12)
                    }
                
                // 進度資訊
                VStack(spacing: 4) {
                    Text("第 \(book.currentPage) 頁")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text("\(Int(book.progress * 100))%")
                        .font(.system(size: 10))
                        .foregroundStyle(book.coverColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct LibrarySection: View {
    let books: [ReaderBook]
    let onBookTap: (ReaderBook) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("我的圖書館")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(books.count) 本書籍")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 20) {
                ForEach(books) { book in
                    LibraryBookCard(book: book) {
                        onBookTap(book)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

struct LibraryBookCard: View {
    let book: ReaderBook
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // 書籍封面
                RoundedRectangle(cornerRadius: 12)
                    .fill(book.coverColor.opacity(0.8))
                    .aspectRatio(0.7, contentMode: .fit)
                    .overlay {
                        VStack(spacing: 8) {
                            Text(book.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                            
                            Spacer()
                            
                            Text(book.author)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(8)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        // 進度指示器
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .overlay {
                                Circle()
                                    .trim(from: 0, to: book.progress)
                                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                    .frame(width: 24, height: 24)
                                    .rotationEffect(.degrees(-90))
                            }
                            .padding(8)
                    }
                
                // 書籍資訊
                VStack(spacing: 4) {
                    Text(book.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 4) {
                        Text("\(Int(book.progress * 100))% •")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        
                        if let fileType = book.fileType {
                            Text(fileType.uppercased())
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(book.coverColor)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: 140)
    }
}

// MARK: - 支援的檔案類型擴展

extension UTType {
    static let epub = UTType(filenameExtension: "epub")!
}

#Preview {
    ReaderLibraryView()
}
