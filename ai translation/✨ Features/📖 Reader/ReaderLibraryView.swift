// ReaderLibraryView.swift

import SwiftUI

struct ReaderLibraryView: View {
    @State private var books: [ReaderBook] = []
    @State private var showingFileImporter = false
    @State private var selectedBook: ReaderBook?
    @State private var searchText = ""
    
    // Demo書籍
    private let demoBooks: [ReaderBook] = [
        ReaderBook(
            id: UUID(),
            title: "英語語法大全",
            author: "示範作者",
            coverColor: .blue,
            progress: 0.3,
            totalPages: 200,
            currentPage: 60,
            dateAdded: Date()
        ),
        ReaderBook(
            id: UUID(),
            title: "商業英文寫作",
            author: "範例作者",
            coverColor: .green,
            progress: 0.7,
            totalPages: 150,
            currentPage: 105,
            dateAdded: Date()
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Apple Books風格的歡迎區域
                    AppleBooksWelcomeCard(
                        onImportBook: {
                            showingFileImporter = true
                        }
                    )
                    
                    // 最近閱讀
                    if !books.isEmpty {
                        AppleBooksRecentSection(books: books) { book in
                            selectedBook = book
                        }
                    }
                    
                    // 我的圖書館
                    AppleBooksLibrarySection(
                        books: books.isEmpty ? demoBooks : books,
                        searchText: searchText
                    ) { book in
                        selectedBook = book
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
            allowedContentTypes: [.text, .pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        // 暫時註解掉 ReaderView 的引用，等下一步創建
        .sheet(item: $selectedBook) { book in
            // ReaderView(book: book)
            // 暫時用簡單的展示視圖
            VStack {
                Text("閱讀器開發中")
                    .font(.title)
                Text("書籍：\(book.title)")
                    .font(.headline)
                Button("關閉") {
                    selectedBook = nil
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .onAppear {
            if books.isEmpty {
                books = demoBooks
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            // TODO: 實際的文件處理邏輯
            print("導入文件: \(url.lastPathComponent)")
        case .failure(let error):
            print("文件導入失敗: \(error.localizedDescription)")
        }
    }
}

// MARK: - Apple Books風格組件

struct AppleBooksWelcomeCard: View {
    let onImportBook: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 圖標和標題
            VStack(spacing: 12) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.linearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("開始您的智慧閱讀")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("匯入文件，邊讀邊學，建立專屬知識庫")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            // 匯入按鈕
            Button(action: onImportBook) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("匯入第一本書")
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
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

struct AppleBooksRecentSection: View {
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
            
            // 修復 ScrollView 初始化
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(recentBooks) { book in
                        AppleBooksRecentCard(book: book) {
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

struct AppleBooksRecentCard: View {
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
                    
                    Text("\(Int(book.progress * 100))% 完成")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: 120)
    }
}

struct AppleBooksLibrarySection: View {
    let books: [ReaderBook]
    let searchText: String
    let onBookTap: (ReaderBook) -> Void
    
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
        VStack(alignment: .leading, spacing: 16) {
            Text("我的圖書館")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 20) {
                ForEach(filteredBooks) { book in
                    AppleBooksLibraryCard(book: book) {
                        onBookTap(book)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

struct AppleBooksLibraryCard: View {
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
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                        .padding(12)
                    }
                
                // 進度條
                VStack(spacing: 6) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.systemGray5))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(book.coverColor)
                                .frame(width: geometry.size.width * book.progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    HStack {
                        Text("第 \(book.currentPage) 頁")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(book.progress * 100))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(book.coverColor)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ReaderLibraryView()
}
