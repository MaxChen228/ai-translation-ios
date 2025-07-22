//
//  MultiClassificationWordDetailView.swift
//  ai translation
//
//  多分類單字詳情畫面
//

import SwiftUI
import AVFoundation

struct MultiClassificationWordDetailView: View {
    let wordId: Int
    
    @StateObject private var service = MultiClassificationService()
    @State private var wordDetail: MultiClassWordDetail?
    @State private var isLoading = true
    @State private var audioPlayer: AVAudioPlayer?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("載入中...")
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let detail = wordDetail {
                VStack(alignment: .leading, spacing: 20) {
                    // 單字標題
                    WordHeaderView(detail: detail, playAudio: playAudio)
                    
                    // 分類標籤
                    ClassificationTagsView(classifications: detail.classifications)
                    
                    if detail.isEnriched, let enrichedInfo = detail.enrichedInfo {
                        // 檢查是否有實際內容
                        let hasContent = !enrichedInfo.definitions.isEmpty || 
                                       !enrichedInfo.pronunciation.isEmpty || 
                                       !enrichedInfo.partOfSpeech.isEmpty ||
                                       !enrichedInfo.synonyms.isEmpty ||
                                       !enrichedInfo.antonyms.isEmpty ||
                                       (enrichedInfo.etymology != nil && !enrichedInfo.etymology!.isEmpty)
                        
                        if hasContent {
                            // 充實資訊
                            EnrichedContentView(enrichedInfo: enrichedInfo)
                        } else {
                            // 數據不完整提示
                            DataIncompleteView()
                        }
                    } else {
                        // 未充實提示
                        UnenrichedPromptView()
                    }
                }
                .padding()
            } else {
                Text("無法載入單字資訊")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 300)
            }
        }
        .navigationTitle(wordDetail?.word ?? "單字詳情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
        .task {
            await loadWordDetail()
        }
    }
    
    // MARK: - 載入資料
    
    private func loadWordDetail() async {
        isLoading = true
        wordDetail = await service.fetchWordDetail(wordId: wordId)
        isLoading = false
    }
    
    // MARK: - 播放音頻
    
    private func playAudio() {
        guard let detail = wordDetail,
              let enrichedInfo = detail.enrichedInfo,
              let audioUrl = enrichedInfo.audioUrls.first,
              let url = URL(string: audioUrl) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer?.play()
            } catch {
                print("音頻播放失敗: \(error)")
            }
        }
    }
}

// MARK: - 單字標題視圖

struct WordHeaderView: View {
    let detail: MultiClassWordDetail
    let playAudio: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(detail.word)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                if detail.isEnriched {
                    Button(action: playAudio) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if let enrichedInfo = detail.enrichedInfo {
                if !enrichedInfo.pronunciation.isEmpty {
                    Text(enrichedInfo.pronunciation)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                if !enrichedInfo.partOfSpeech.isEmpty {
                    Text(enrichedInfo.partOfSpeech)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
            }
        }
    }
}

// MARK: - 分類標籤視圖

struct ClassificationTagsView: View {
    let classifications: [WordClassification]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分類標籤")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(classifications, id: \.systemCode) { classification in
                    TagView(classification: classification)
                }
            }
        }
    }
}

struct TagView: View {
    let classification: WordClassification
    
    var body: some View {
        Text(classification.displayText)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(tagColor.opacity(0.1))
            .foregroundColor(tagColor)
            .cornerRadius(12)
    }
    
    private var tagColor: Color {
        switch classification.systemCode {
        case "LEVEL": return .blue
        case "CEFR": return .green
        default: return .gray
        }
    }
}

// MARK: - 充實內容視圖

struct EnrichedContentView: View {
    let enrichedInfo: EnrichedWordInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 定義
            if !enrichedInfo.definitions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("定義")
                        .font(.headline)
                    
                    ForEach(Array(enrichedInfo.definitions.enumerated()), id: \.offset) { index, definition in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .foregroundColor(.secondary)
                            Text(definition)
                        }
                    }
                }
            }
            
            // 同義詞
            if !enrichedInfo.synonyms.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("同義詞")
                        .font(.headline)
                    
                    Text(enrichedInfo.synonyms.joined(separator: ", "))
                        .foregroundColor(.secondary)
                }
            }
            
            // 反義詞
            if !enrichedInfo.antonyms.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("反義詞")
                        .font(.headline)
                    
                    Text(enrichedInfo.antonyms.joined(separator: ", "))
                        .foregroundColor(.secondary)
                }
            }
            
            // 詞源
            if let etymology = enrichedInfo.etymology, !etymology.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("詞源")
                        .font(.headline)
                    
                    Text(etymology)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - 未充實提示視圖

struct UnenrichedPromptView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("此單字尚未充實資料")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("申請充實後可查看完整定義、發音、例句等資訊")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                // TODO: 實作申請充實功能
            }) {
                Label("申請充實資料", systemImage: "arrow.up.doc")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                maxHeight = max(maxHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: y + maxHeight)
        }
    }
}

// MARK: - 數據不完整提示視圖

struct DataIncompleteView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("單字資料不完整")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("此單字雖已標記為充實，但詳細資料尚未完整載入")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("請稍後再試或聯繫管理員")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MultiClassificationWordDetailView(wordId: 123)
    }
}