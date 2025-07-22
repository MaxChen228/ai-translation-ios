// BuiltinVocabularyView.swift
// 內建單字庫主頁面

import SwiftUI

struct BuiltinVocabularyView: View {
    @StateObject private var service = BuiltinVocabularyService()
    @State private var showingWordDetail = false
    @State private var selectedWord: BuiltinWord?
    @State private var searchText = ""
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜尋欄
                searchSection
                
                // 分類選擇器
                if !service.categories.isEmpty {
                    categorySection
                }
                
                // 篩選指示器
                if service.currentFilter.isActive {
                    filterIndicatorSection
                }
                
                // 單字列表
                wordListSection
            }
            .navigationTitle("內建單字庫")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("篩選") {
                        showingFilters = true
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                BuiltinVocabularyFilterView(service: service)
            }
            .sheet(isPresented: $showingWordDetail) {
                if let word = selectedWord {
                    BuiltinWordDetailView(word: word)
                }
            }
            .task {
                await loadInitialData()
            }
            .refreshable {
                await refreshData()
            }
        }
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        VStack {
            ModernInputField(
                title: "搜尋",
                placeholder: "搜尋單字...",
                text: $searchText
            )
            .onChange(of: searchText) { newValue in
                Task {
                    try? await service.setSearchText(newValue)
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("分類")
                    .font(.appHeadline(for: "分類"))
                    .padding(.leading)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ModernSpacing.md) {
                    // 全部分類按鈕
                    Button(action: {
                        Task {
                            try? await service.filterByCategory(nil)
                        }
                    }) {
                        VStack(spacing: ModernSpacing.xs) {
                            Text("📚")
                                .font(.appTitle2())
                            Text("全部")
                                .font(.appCaption(for: "全部"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .foregroundStyle(service.currentFilter.selectedCategory == nil ? Color.modernAccent : Color.modernTextPrimary)
                    .frame(width: 80, height: 70)
                    .background {
                        RoundedRectangle(cornerRadius: ModernRadius.md)
                            .fill(service.currentFilter.selectedCategory == nil ? Color.modernAccentSoft : Color.clear)
                            .overlay {
                                RoundedRectangle(cornerRadius: ModernRadius.md)
                                    .stroke(service.currentFilter.selectedCategory == nil ? Color.modernAccent : Color.modernBorder, lineWidth: 1)
                            }
                    }
                    
                    // 各分類按鈕
                    ForEach(service.categories) { category in
                        let isSelected = service.currentFilter.selectedCategory?.id == category.id
                        Button(action: {
                            Task {
                                try? await service.filterByCategory(category)
                            }
                        }) {
                            VStack(spacing: ModernSpacing.xs) {
                                Text(category.displayIcon)
                                    .font(.appTitle2())
                                
                                Text(category.nameZh)
                                    .font(.appCaption(for: category.nameZh))
                                    .fontWeight(isSelected ? .semibold : .regular)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text("\(category.wordCount)")
                                    .font(.appCaption2())
                                    .foregroundStyle(Color.modernTextSecondary)
                            }
                        }
                        .foregroundStyle(isSelected ? Color.modernAccent : Color.modernTextPrimary)
                        .frame(width: 80, height: 70)
                        .background {
                            RoundedRectangle(cornerRadius: ModernRadius.md)
                                .fill(isSelected ? Color.modernAccentSoft : Color.clear)
                                .overlay {
                                    RoundedRectangle(cornerRadius: ModernRadius.md)
                                        .stroke(isSelected ? Color.modernAccent : Color.modernBorder, lineWidth: 1)
                                }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 90)
        }
        .padding(.bottom)
    }
    
    // MARK: - Filter Indicator Section
    
    private var filterIndicatorSection: some View {
        HStack {
            Text("已套用篩選")
                .font(.appCaption(for: "已套用篩選"))
                .foregroundStyle(Color.modernTextSecondary)
            
            Spacer()
            
            Button("清除篩選") {
                Task {
                    try? await service.clearFilter()
                }
            }
            .font(.appCaption(for: "清除篩選"))
            .foregroundStyle(Color.modernAccent)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Word List Section
    
    private var wordListSection: some View {
        Group {
            switch service.loadingState {
            case .idle:
                EmptyView()
                
            case .loading:
                if service.words.isEmpty {
                    ModernLoadingView("載入中...")
                } else {
                    wordList
                }
                
            case .loaded:
                if service.words.isEmpty {
                    ModernEmptyStateView(
                        icon: "book.closed",
                        title: "沒有找到單字",
                        message: "嘗試調整篩選條件或搜尋關鍵字",
                        actionTitle: "清除篩選"
                    ) {
                        Task {
                            try? await service.clearFilter()
                        }
                    }
                } else {
                    wordList
                }
                
            case .error(let message):
                VStack(spacing: ModernSpacing.lg) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.appLargeTitle())
                        .foregroundStyle(Color.modernWarning)
                    
                    Text("載入失敗")
                        .font(.appTitle3(for: "載入失敗"))
                        .foregroundStyle(Color.modernTextPrimary)
                    
                    Text(message)
                        .font(.appBody(for: message))
                        .foregroundStyle(Color.modernTextSecondary)
                        .multilineTextAlignment(.center)
                    
                    ModernButton("重試", style: .primary) {
                        Task {
                            await refreshData()
                        }
                    }
                    .frame(maxWidth: 200)
                }
                .padding(ModernSpacing.xl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var wordList: some View {
        List {
            ForEach(service.words) { word in
                WordRowView(word: word) {
                    selectedWord = word
                    showingWordDetail = true
                }
            }
            
            // 載入更多
            if service.hasMorePages {
                LoadMoreView {
                    await loadMoreWords()
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    
    // MARK: - Helper Methods
    
    private func loadInitialData() async {
        do {
            try await service.loadInitialData()
        } catch {
            print("載入初始資料失敗: \(error)")
        }
    }
    
    private func refreshData() async {
        do {
            try await service.refreshWords()
        } catch {
            print("刷新資料失敗: \(error)")
        }
    }
    
    private func loadMoreWords() async {
        do {
            try await service.loadMoreWords()
        } catch {
            print("載入更多單字失敗: \(error)")
        }
    }
}

// MARK: - Supporting Views


struct WordRowView: View {
    let word: BuiltinWord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(word.displayName)
                            .font(.appHeadline(for: word.displayName))
                            .foregroundStyle(Color.modernTextPrimary)
                        
                        Spacer()
                        
                        // 快取指示器
                        if word.isCached {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.modernSuccess)
                                .font(.appCaption())
                        }
                    }
                    
                    HStack(spacing: ModernSpacing.sm) {
                        // 分類標籤
                        Text(word.categoryDisplayName)
                            .font(.appCaption(for: word.categoryDisplayName))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.modernAccentSoft)
                            .foregroundStyle(Color.modernAccent)
                            .clipShape(Capsule())
                        
                        // 難度星級
                        Text(word.difficultyStars)
                            .font(.appCaption(for: word.difficultyStars))
                            .foregroundStyle(Color.modernWarning)
                        
                        // CEFR 等級
                        if let cefrLevel = word.cefrLevel {
                            Text(cefrLevel)
                                .font(.appCaption(for: cefrLevel))
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(cefrLevelColor(for: cefrLevel))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: ModernRadius.xs))
                        }
                        
                        Spacer()
                        
                        // 瀏覽次數
                        if word.viewCount > 0 {
                            Text("\(word.viewCount)次瀏覽")
                                .font(.appCaption2())
                                .foregroundStyle(Color.modernTextSecondary)
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.appCaption())
                    .foregroundStyle(Color.modernTextSecondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func cefrLevelColor(for level: String) -> Color {
        switch level {
        case "A1", "A2": return .green
        case "B1", "B2": return .orange
        case "C1", "C2": return .red
        default: return .gray
        }
    }
}



struct LoadMoreView: View {
    let loadMore: () async -> Void
    @State private var isLoading = false
    
    var body: some View {
        HStack {
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .modernAccent))
            } else {
                ModernButton("載入更多", style: .secondary) {
                    Task {
                        isLoading = true
                        await loadMore()
                        isLoading = false
                    }
                }
            }
            
            Spacer()
        }
        .padding(ModernSpacing.md)
    }
}

// MARK: - Preview

#Preview {
    BuiltinVocabularyView()
}