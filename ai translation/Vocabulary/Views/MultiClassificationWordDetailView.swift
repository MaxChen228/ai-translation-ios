//
//  MultiClassificationWordDetailView.swift
//  ai translation
//
//  多分類單字詳情畫面
//

import SwiftUI

struct MultiClassificationWordDetailView: View {
    let wordId: Int
    
    @StateObject private var service = MultiClassificationService()
    @StateObject private var audioManager = AudioPlayerManager.shared
    @State private var wordDetail: MultiClassWordDetail?
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("載入中...")
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let detail = wordDetail {
                VStack(alignment: .leading, spacing: 20) {
                    // 單字標題
                    WordHeaderView(detail: detail)
                    
                    // 分類標籤
                    ClassificationTagsView(classifications: detail.classifications)
                    
                    if detail.isEnriched, let enrichedInfo = detail.enrichedInfo {
                        // 總是顯示完整的資訊框架，不論數據是否完整
                        CompleteWordInfoView(enrichedInfo: enrichedInfo)
                    } else {
                        // 未充實的單字也顯示框架，只是標示為未充實
                        EmptyWordInfoView(word: detail.word)
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
    
}

// MARK: - 單字標題視圖

struct WordHeaderView: View {
    let detail: MultiClassWordDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(detail.word)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                if detail.isEnriched, 
                   let enrichedInfo = detail.enrichedInfo,
                   let audioUrl = enrichedInfo.audioUrls.first {
                    AudioPlayerButton(audioUrl: audioUrl, word: detail.word)
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

// MARK: - 完整單字資訊視圖

struct CompleteWordInfoView: View {
    let enrichedInfo: EnrichedWordInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 定義區塊
            WordInfoSection(title: "定義", icon: "book.fill") {
                if !enrichedInfo.definitions.isEmpty {
                    ForEach(Array(enrichedInfo.definitions.enumerated()), id: \.offset) { index, definition in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            Text(definition)
                                .font(.subheadline)
                        }
                    }
                } else {
                    DataNotAvailableView(message: "定義資料整理中")
                }
            }
            
            // 同義詞區塊
            WordInfoSection(title: "同義詞", icon: "arrow.triangle.2.circlepath") {
                if !enrichedInfo.synonyms.isEmpty {
                    Text(enrichedInfo.synonyms.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    DataNotAvailableView(message: "同義詞資料整理中")
                }
            }
            
            // 反義詞區塊
            WordInfoSection(title: "反義詞", icon: "arrow.left.and.right.circle") {
                if !enrichedInfo.antonyms.isEmpty {
                    Text(enrichedInfo.antonyms.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    DataNotAvailableView(message: "反義詞資料整理中")
                }
            }
            
            // 詞源區塊
            WordInfoSection(title: "詞源", icon: "scroll.fill") {
                if let etymology = enrichedInfo.etymology, !etymology.isEmpty {
                    Text(etymology)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    DataNotAvailableView(message: "詞源資料整理中")
                }
            }
        }
    }
}

// MARK: - 空白單字資訊視圖（未充實）

struct EmptyWordInfoView: View {
    let word: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 定義區塊
            WordInfoSection(title: "定義", icon: "book.fill") {
                DataNotAvailableView(message: "單字尚未充實，定義資料待補充")
            }
            
            // 同義詞區塊
            WordInfoSection(title: "同義詞", icon: "arrow.triangle.2.circlepath") {
                DataNotAvailableView(message: "單字尚未充實，同義詞資料待補充")
            }
            
            // 反義詞區塊
            WordInfoSection(title: "反義詞", icon: "arrow.left.and.right.circle") {
                DataNotAvailableView(message: "單字尚未充實，反義詞資料待補充")
            }
            
            // 詞源區塊
            WordInfoSection(title: "詞源", icon: "scroll.fill") {
                DataNotAvailableView(message: "單字尚未充實，詞源資料待補充")
            }
            
            // 充實提示
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                Text("申請充實資料")
                    .font(.headline)
                
                Text("點擊下方按鈕申請為此單字補充完整資訊")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    // TODO: 實作申請充實功能
                }) {
                    Label("申請充實", systemImage: "arrow.up.doc.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
}

// MARK: - 資訊區塊組件

struct WordInfoSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.headline)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            content
                .padding(.leading, 4)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 資料未取得提示

struct DataNotAvailableView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.circle")
                .foregroundColor(.orange)
                .font(.subheadline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(.vertical, 4)
    }
}


// MARK: - Preview

#Preview {
    NavigationStack {
        MultiClassificationWordDetailView(wordId: 123)
    }
}