// ReadingAreaView.swift - 閱讀區獨立容器

import SwiftUI

struct ReadingAreaView: View {
    var body: some View {
        TabView {
            // 我的圖書館
            ReaderLibraryView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("圖書館")
                }
            
            // 閱讀歷史
            ReadingHistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("歷史")
                }
            
            // 書籤與筆記
            ReadingNotesView()
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("筆記")
                }
            
            // 閱讀設定
            ReadingSettingsContainerView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
        }
        .accentColor(.blue) // 閱讀區使用藍色主題
    }
}

// MARK: - 閱讀歷史頁面

struct ReadingHistoryView: View {
    @State private var recentBooks: [ReaderBook] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if recentBooks.isEmpty {
                        EmptyReadingHistoryView()
                    } else {
                        ForEach(recentBooks) { book in
                            ReadingHistoryCard(book: book)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("📖 閱讀歷史")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadRecentBooks()
        }
    }
    
    private func loadRecentBooks() {
        // 這裡之後會載入實際的閱讀歷史
        // 暫時使用空陣列
        recentBooks = []
    }
}

struct EmptyReadingHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.appLargeTitle())
                .foregroundStyle(.secondary)
            
            Text("尚無閱讀歷史")
                .font(.appHeadline(for: "尚無閱讀歷史"))
                .foregroundStyle(.primary)
            
            Text("開始閱讀書籍後，會在這裡顯示您的閱讀記錄")
                .font(.appSubheadline(for: "開始閱讀書籍後，會在這裡顯示您的閱讀記錄"))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ReadingHistoryCard: View {
    let book: ReaderBook
    
    var body: some View {
        HStack(spacing: 16) {
            // 書籍封面
            RoundedRectangle(cornerRadius: 8)
                .fill(book.coverColor)
                .frame(width: 60, height: 80)
                .overlay {
                    Image(systemName: "book.closed")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let lastRead = book.lastRead {
                    Text("最後閱讀：\(lastRead, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                ProgressView(value: book.progress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
            }
            
            Spacer()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - 書籤與筆記頁面

struct ReadingNotesView: View {
    @State private var notes: [ReaderNote] = []
    @State private var bookmarks: [ReaderBookmark] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // 書籤區塊
                    BookmarksSection(bookmarks: bookmarks)
                    
                    Divider()
                    
                    // 筆記區塊
                    NotesSection(notes: notes)
                }
                .padding(20)
            }
            .navigationTitle("📚 筆記與書籤")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadNotesAndBookmarks()
        }
    }
    
    private func loadNotesAndBookmarks() {
        // 這裡之後會載入實際的筆記和書籤
        // 暫時使用空陣列
        notes = []
        bookmarks = []
    }
}

struct BookmarksSection: View {
    let bookmarks: [ReaderBookmark]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.blue)
                
                Text("我的書籤")
                    .font(.appTitle2(for: "我的書籤"))
                
                Spacer()
                
                Text("\(bookmarks.count)")
                    .font(.appCaption(for: "\(bookmarks.count)"))
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            if bookmarks.isEmpty {
                Text("還沒有任何書籤")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(bookmarks) { bookmark in
                    BookmarkCard(bookmark: bookmark)
                }
            }
        }
    }
}

struct NotesSection: View {
    let notes: [ReaderNote]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.blue)
                
                Text("我的筆記")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(notes.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            if notes.isEmpty {
                Text("還沒有任何筆記")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(notes) { note in
                    NoteCard(note: note)
                }
            }
        }
    }
}

struct BookmarkCard: View {
    let bookmark: ReaderBookmark
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("第 \(bookmark.pageNumber) 頁")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())
                
                Spacer()
                
                Text(bookmark.dateCreated, formatter: shortDateFormatter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !bookmark.note.isEmpty {
                Text(bookmark.note)
                    .font(.body)
                    .lineLimit(3)
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        }
    }
    
    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

struct NoteCard: View {
    let note: ReaderNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("第 \(note.pageNumber) 頁")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
                
                Spacer()
                
                Text(note.dateCreated, formatter: shortDateFormatter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("\"\(note.selectedText)\"")
                .font(.body)
                .fontWeight(.medium)
                .padding(.leading, 8)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(.green)
                        .frame(width: 3)
                }
            
            Text(note.note)
                .font(.body)
                .lineLimit(3)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        }
    }
    
    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

// MARK: - 閱讀設定頁面

struct ReadingSettingsContainerView: View {
    @State private var defaultSettings = ReaderSettings()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // 閱讀偏好設定說明
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.blue)
                            
                            Text("預設閱讀設定")
                                .font(.appTitle2(for: "預設閱讀設定"))
                        }
                        
                        Text("這些設定將套用到所有新開啟的書籍，您也可以在閱讀時個別調整。")
                            .font(.appSubheadline(for: "這些設定將套用到所有新開啟的書籍，您也可以在閱讀時個別調整。"))
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                    .padding(20)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    
                    // 閱讀設定內容
                    ReaderSettingsView(settings: $defaultSettings)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("🔧 閱讀設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ReadingAreaView()
}
