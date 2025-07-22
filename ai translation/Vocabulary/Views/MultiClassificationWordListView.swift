//
//  MultiClassificationWordListView.swift
//  ai translation
//
//  多分類單字列表畫面
//

import SwiftUI

struct MultiClassificationWordListView: View {
    let system: ClassificationSystem
    let category: String
    
    @StateObject private var service = MultiClassificationService()
    @State private var alphabetData: AlphabetData?
    @State private var selectedWord: MultiClassWord?
    @State private var searchText = ""
    
    // 字母選擇
    private let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    
    var body: some View {
        VStack(spacing: 0) {
            // 字母導航
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(alphabet, id: \.self) { letter in
                        LetterButton(
                            letter: String(letter),
                            isSelected: service.selectedLetter == String(letter),
                            count: alphabetData?.alphabetDistribution[String(letter)] ?? 0
                        ) {
                            service.selectedLetter = String(letter)
                            service.resetWords()
                            Task {
                                await service.fetchWords(
                                    systemCode: system.systemCode,
                                    category: category,
                                    letter: String(letter)
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            
            Divider()
            
            // 單字列表
            if service.isLoading && service.words.isEmpty {
                ProgressView("載入中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(service.words) { word in
                        Button(action: {
                            selectedWord = word
                        }) {
                            WordRow(word: word)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // 載入更多
                    if service.hasMorePages {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding()
                        .onAppear {
                            Task {
                                await service.loadMoreWords(
                                    systemCode: system.systemCode,
                                    category: category
                                )
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("\(system.systemName) - \(category)")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "搜尋單字")
        .task {
            // 載入字母分布
            alphabetData = await service.fetchAlphabetDistribution(
                systemCode: system.systemCode,
                category: category
            )
            
            // 載入第一批單字
            await service.fetchWords(
                systemCode: system.systemCode,
                category: category,
                letter: service.selectedLetter
            )
        }
        .sheet(item: $selectedWord) { word in
            NavigationStack {
                MultiClassificationWordDetailView(wordId: word.wordId)
            }
        }
    }
}

// MARK: - 字母按鈕

struct LetterButton: View {
    let letter: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(letter)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .frame(width: 36, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
            .opacity(count > 0 ? 1 : 0.5)
        }
        .disabled(count == 0)
    }
}

// MARK: - 單字列

struct WordRow: View {
    let word: MultiClassWord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.word)
                    .font(.headline)
                
                if let pronunciation = word.pronunciation {
                    Text(pronunciation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: word.statusIcon)
                .foregroundColor(word.statusColor)
                .imageScale(.small)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MultiClassificationWordListView(
            system: ClassificationSystem(
                systemId: 1,
                systemName: "Level System",
                systemCode: "LEVEL",
                description: "傳統1-6級別分類",
                categories: ["1", "2", "3", "4", "5", "6"],
                totalWords: 6009,
                enrichedWords: 708,
                displayOrder: 1
            ),
            category: "3"
        )
    }
}