// BuiltinWordDetailView.swift
// 內建單字詳情頁面

import SwiftUI
import AVFoundation

struct BuiltinWordDetailView: View {
    let word: BuiltinWord
    
    @StateObject private var service = BuiltinVocabularyService()
    @StateObject private var audioPlayer = AudioPlayerManager()
    
    @State private var wordDetail: BuiltinWordDetail?
    @State private var loadingState: BuiltinVocabularyLoadingState = .idle
    @State private var showingAddConfirmation = false
    @State private var isAddedToVocabulary = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                switch loadingState {
                case .idle, .loading:
                    ModernLoadingView("載入中...")
                    
                case .loaded:
                    if let detail = wordDetail {
                        detailContent(detail)
                    } else {
                        errorContent
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
                                await loadWordDetail()
                            }
                        }
                        .frame(maxWidth: 200)
                    }
                    .padding(ModernSpacing.xl)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(word.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let detail = wordDetail, detail.dictionaryData.hasAudio {
                        Button(action: { playAudio() }) {
                            Image(systemName: audioPlayer.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                        }
                        .disabled(audioPlayer.isLoading)
                    }
                }
            }
            .task {
                await loadWordDetail()
            }
        }
    }
    
    // MARK: - Detail Content
    
    @ViewBuilder
    private func detailContent(_ detail: BuiltinWordDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ModernSpacing.lg) {
                // 單字標題區
                wordHeaderSection(detail)
                
                // 定義區
                if !detail.dictionaryData.definitions.isEmpty {
                    definitionsSection(detail.dictionaryData.definitions)
                }
                
                // 同義詞區
                if !detail.dictionaryData.synonyms.isEmpty {
                    synonymsSection(detail.dictionaryData.synonyms)
                }
                
                // 反義詞區
                if !detail.dictionaryData.antonyms.isEmpty {
                    antonymsSection(detail.dictionaryData.antonyms)
                }
                
                // 詞源區
                if let etymology = detail.dictionaryData.etymology, !etymology.isEmpty {
                    etymologySection(etymology)
                }
                
                // 單字資訊區
                wordInfoSection(detail.wordInfo)
                
                // 加入個人單字庫按鈕
                addToVocabularyButton
                
                Spacer(minLength: ModernSpacing.lg)
            }
            .padding(ModernSpacing.md)
        }
    }
    
    private func wordHeaderSection(_ detail: BuiltinWordDetail) -> some View {
        VStack(alignment: .leading, spacing: ModernSpacing.md) {
            HStack {
                Text(detail.wordInfo.displayName)
                    .font(.appLargeTitle(for: detail.wordInfo.displayName))
                    .fontWeight(.bold)
                
                Spacer()
                
                // 音頻播放按鈕
                if detail.dictionaryData.hasAudio {
                    Button(action: { playAudio() }) {
                        HStack(spacing: ModernSpacing.xs) {
                            Image(systemName: audioPlayer.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                            Text("播放")
                                .font(.appCaption(for: "播放"))
                        }
                        .padding(.horizontal, ModernSpacing.md)
                        .padding(.vertical, ModernSpacing.xs)
                        .background(Color.modernAccentSoft)
                        .foregroundStyle(Color.modernAccent)
                        .clipShape(Capsule())
                    }
                    .disabled(audioPlayer.isLoading)
                }
            }
            
            // 發音和詞性
            HStack(spacing: ModernSpacing.md) {
                if let pronunciation = detail.dictionaryData.pronunciation, !pronunciation.isEmpty {
                    HStack(spacing: ModernSpacing.xs) {
                        Image(systemName: "speaker.1")
                            .foregroundStyle(Color.modernTextSecondary)
                        Text("[\(pronunciation)]")
                            .font(.appHeadline(for: "[\(pronunciation)]"))
                            .fontWeight(.medium)
                    }
                }
                
                if let partOfSpeech = detail.dictionaryData.partOfSpeech, !partOfSpeech.isEmpty {
                    Text(partOfSpeech)
                        .font(.appHeadline(for: partOfSpeech))
                        .fontWeight(.medium)
                        .padding(.horizontal, ModernSpacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.modernBorder.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: ModernRadius.xs))
                }
            }
            
            // 標籤行
            HStack(spacing: ModernSpacing.sm) {
                // 分類標籤
                Text(detail.wordInfo.categoryDisplayName)
                    .font(.appCaption(for: detail.wordInfo.categoryDisplayName))
                    .padding(.horizontal, ModernSpacing.sm)
                    .padding(.vertical, ModernSpacing.xs)
                    .background(Color.modernAccentSoft)
                    .foregroundStyle(Color.modernAccent)
                    .clipShape(Capsule())
                
                // 難度標籤
                Text(detail.wordInfo.difficultyDescription)
                    .font(.appCaption(for: detail.wordInfo.difficultyDescription))
                    .padding(.horizontal, ModernSpacing.sm)
                    .padding(.vertical, ModernSpacing.xs)
                    .background(Color.modernWarning.opacity(0.1))
                    .foregroundStyle(Color.modernWarning)
                    .clipShape(Capsule())
                
                // CEFR 等級
                if let cefrLevel = detail.wordInfo.cefrLevel {
                    Text(cefrLevel)
                        .font(.appCaption(for: cefrLevel))
                        .fontWeight(.semibold)
                        .padding(.horizontal, ModernSpacing.sm)
                        .padding(.vertical, ModernSpacing.xs)
                        .background(cefrLevelColor(for: cefrLevel))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
        }
        .padding(ModernSpacing.md)
        .background(Color.modernSurface)
        .clipShape(RoundedRectangle(cornerRadius: ModernRadius.md))
        .modernShadow()
    }
    
    private func definitionsSection(_ definitions: [String]) -> some View {
        SectionView(title: "定義", icon: "book") {
            VStack(alignment: .leading, spacing: ModernSpacing.md) {
                ForEach(Array(definitions.enumerated()), id: \.offset) { index, definition in
                    HStack(alignment: .top, spacing: ModernSpacing.md) {
                        Text("\(index + 1).")
                            .font(.appBody())
                            .fontWeight(.medium)
                            .foregroundStyle(Color.modernAccent)
                            .frame(width: ModernSpacing.lg, alignment: .leading)
                        
                        Text(definition)
                            .font(.appBody(for: definition))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func synonymsSection(_ synonyms: [String]) -> some View {
        SectionView(title: "同義詞", icon: "arrow.triangle.branch") {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: ModernSpacing.sm)
            ], spacing: ModernSpacing.sm) {
                ForEach(synonyms, id: \.self) { synonym in
                    Text(synonym)
                        .font(.appCaption(for: synonym))
                        .padding(.horizontal, ModernSpacing.sm)
                        .padding(.vertical, ModernSpacing.xs)
                        .background(Color.modernSuccess.opacity(0.1))
                        .foregroundStyle(Color.modernSuccess)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private func antonymsSection(_ antonyms: [String]) -> some View {
        SectionView(title: "反義詞", icon: "arrow.left.arrow.right") {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: ModernSpacing.sm)
            ], spacing: ModernSpacing.sm) {
                ForEach(antonyms, id: \.self) { antonym in
                    Text(antonym)
                        .font(.appCaption(for: antonym))
                        .padding(.horizontal, ModernSpacing.sm)
                        .padding(.vertical, ModernSpacing.xs)
                        .background(Color.modernError.opacity(0.1))
                        .foregroundStyle(Color.modernError)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private func etymologySection(_ etymology: String) -> some View {
        SectionView(title: "詞源", icon: "clock") {
            Text(etymology)
                .font(.appBody(for: etymology))
                .foregroundStyle(Color.modernTextSecondary)
        }
    }
    
    private func wordInfoSection(_ wordInfo: BuiltinWord) -> some View {
        SectionView(title: "單字資訊", icon: "info.circle") {
            VStack(alignment: .leading, spacing: ModernSpacing.sm) {
                InfoRow(label: "使用頻率排名", value: "\(wordInfo.frequencyRank ?? 0)")
                InfoRow(label: "瀏覽次數", value: "\(wordInfo.viewCount)次")
                InfoRow(label: "快取狀態", value: wordInfo.isCached ? "已快取" : "未快取")
            }
        }
    }
    
    private var addToVocabularyButton: some View {
        Button(action: addToVocabulary) {
            HStack {
                Image(systemName: isAddedToVocabulary ? "checkmark.circle.fill" : "plus.circle")
                Text(isAddedToVocabulary ? "已加入個人單字庫" : "加入我的單字庫")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(ModernSpacing.md)
            .background(isAddedToVocabulary ? Color.modernSuccess : Color.modernAccent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: ModernRadius.md))
        }
        .disabled(isAddedToVocabulary)
        .alert("成功加入", isPresented: $showingAddConfirmation) {
            Button("確定") { }
        } message: {
            Text("「\(word.displayName)」已成功加入您的個人單字庫")
        }
    }
    
    private var errorContent: some View {
        VStack(spacing: ModernSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.appLargeTitle())
                .foregroundStyle(Color.modernWarning)
            
            Text("載入失敗")
                .font(.appTitle2(for: "載入失敗"))
                .fontWeight(.medium)
            
            Text("無法載入單字詳細資訊")
                .font(.appBody(for: "無法載入單字詳細資訊"))
                .foregroundStyle(Color.modernTextSecondary)
            
            Button("重試") {
                Task {
                    await loadWordDetail()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(ModernSpacing.md)
    }
    
    // MARK: - Helper Methods
    
    private func loadWordDetail() async {
        loadingState = .loading
        
        do {
            let detail = try await service.getWordDetail(word: word.word)
            self.wordDetail = detail
            loadingState = .loaded
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }
    
    private func playAudio() {
        guard let detail = wordDetail,
              let audioUrlString = detail.dictionaryData.primaryAudioUrl,
              let audioUrl = URL(string: audioUrlString) else {
            return
        }
        
        Task {
            await audioPlayer.playAudio(from: audioUrl)
        }
    }
    
    private func addToVocabulary() {
        Task {
            do {
                let response = try await service.addToMyWords(word: word.word)
                if response.success {
                    isAddedToVocabulary = true
                    showingAddConfirmation = true
                }
            } catch {
                // 處理錯誤
                print("加入個人單字庫失敗: \(error)")
            }
        }
    }
    
    private func cefrLevelColor(for level: String) -> Color {
        switch level {
        case "A1", "A2": return Color.modernSuccess
        case "B1", "B2": return Color.modernWarning
        case "C1", "C2": return Color.modernError
        default: return Color.modernTextSecondary
        }
    }
}

// MARK: - Supporting Views

struct SectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.md) {
            HStack(spacing: ModernSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(Color.modernAccent)
                Text(title)
                    .font(.appHeadline(for: title))
                    .fontWeight(.semibold)
            }
            
            content()
        }
        .padding(ModernSpacing.md)
        .background(Color.modernSurface)
        .clipShape(RoundedRectangle(cornerRadius: ModernRadius.md))
        .modernShadow()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.appBody(for: label))
                .foregroundStyle(Color.modernTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.appBody(for: value))
                .fontWeight(.medium)
        }
    }
}

// MARK: - Audio Player Manager

@MainActor
class AudioPlayerManager: ObservableObject {
    @Published var isPlaying = false
    @Published var isLoading = false
    
    private var audioPlayer: AVAudioPlayer?
    private var playerDelegate: AudioPlayerDelegate?
    
    func playAudio(from url: URL) async {
        isLoading = true
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(data: data)
            playerDelegate = AudioPlayerDelegate(manager: self)
            audioPlayer?.delegate = playerDelegate
            
            isLoading = false
            
            if let player = audioPlayer {
                isPlaying = true
                player.play()
            }
        } catch {
            isLoading = false
            print("音頻播放失敗: \(error)")
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        isPlaying = false
    }
}

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private weak var manager: AudioPlayerManager?
    
    init(manager: AudioPlayerManager) {
        self.manager = manager
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            manager?.isPlaying = false
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            manager?.isPlaying = false
        }
    }
}

// MARK: - Filter View

struct BuiltinVocabularyFilterView: View {
    @ObservedObject var service: BuiltinVocabularyService
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempFilter: BuiltinVocabularyFilter
    
    init(service: BuiltinVocabularyService) {
        self.service = service
        self._tempFilter = State(initialValue: service.currentFilter)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("分類") {
                    Picker("選擇分類", selection: $tempFilter.selectedCategory) {
                        Text("全部").tag(nil as BuiltinCategory?)
                        ForEach(service.categories) { category in
                            Text(category.nameZh).tag(category as BuiltinCategory?)
                        }
                    }
                }
                
                Section("難度等級") {
                    Picker("選擇難度", selection: $tempFilter.selectedDifficulty) {
                        Text("全部").tag(nil as Int?)
                        ForEach(1...5, id: \.self) { level in
                            Text("\(level)星 - \(BuiltinVocabularyConstants.difficultyLevels[level] ?? "")").tag(level as Int?)
                        }
                    }
                }
                
                Section("CEFR 等級") {
                    Picker("選擇 CEFR", selection: $tempFilter.selectedCEFR) {
                        Text("全部").tag(nil as String?)
                        ForEach(BuiltinVocabularyConstants.cefrLevels, id: \.self) { level in
                            Text(level).tag(level as String?)
                        }
                    }
                }
            }
            .navigationTitle("篩選條件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("套用") {
                        Task {
                            try? await service.applyFilter(tempFilter)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BuiltinWordDetailView(
        word: BuiltinWord(
            id: 1,
            word: "hello",
            categoryId: 1,
            difficultyLevel: 1,
            frequencyRank: 100,
            cefrLevel: "A1",
            isCached: true,
            viewCount: 42,
            createdAt: "2024-01-01",
            updatedAt: "2024-01-01",
            categoryName: "common",
            categoryNameZh: "常用單字",
            categoryIcon: "📚"
        )
    )
}