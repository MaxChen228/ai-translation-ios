// FlashcardView.swift

import SwiftUI

struct FlashcardView: View {
    // 從上一個頁面接收傳過來的單字卡數據
    let flashcards: [Flashcard]
    
    // 追蹤目前顯示的是第幾張卡片
    @State private var currentIndex = 0
    // 追蹤卡片是否被翻轉
    @State private var isFlipped = false
    // 用於卡片翻轉動畫
    @State private var rotation: Double = 0
    
    // 安全地獲取當前的卡片，避免閃退
    private var currentCard: Flashcard? {
        guard !flashcards.isEmpty, flashcards.indices.contains(currentIndex) else {
            return nil
        }
        return flashcards[currentIndex]
    }
    
    var body: some View {
        VStack(spacing: 30) {
            if let card = currentCard {
                // 卡片主體
                ZStack {
                    // 卡片正面
                    FlashcardSide(content: card.front, title: "當時的錯誤", color: .blue)
                        .opacity(isFlipped ? 0 : 1)
                    
                    // 卡片背面
                    FlashcardSide(content: "\(card.back_correction)\n\n說明：\(card.back_explanation)", title: "正確用法", color: .green)
                        .opacity(isFlipped ? 1 : 0)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                }
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
                .onTapGesture {
                    // 點擊時，執行翻轉動畫
                    withAnimation(.spring()) {
                        rotation += 180
                        isFlipped.toggle()
                    }
                }
                
                // 進度指示器
                Text("\(currentIndex + 1) / \(flashcards.count)")
                    .font(.appHeadline())
                
                // 控制按鈕
                HStack {
                    Button("上一張") {
                        goToPreviousCard()
                    }
                    .disabled(currentIndex == 0)
                    
                    Spacer()
                    
                    Button("下一張") {
                        goToNextCard()
                    }
                    .disabled(currentIndex == flashcards.count - 1)
                }
                .padding(.horizontal)
                
            } else {
                Text("沒有可複習的卡片。")
            }
        }
        .padding()
        .navigationTitle("單字卡複習")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 切換到下一張卡片
    func goToNextCard() {
        if currentIndex < flashcards.count - 1 {
            currentIndex += 1
            resetCardState()
        }
    }
    
    // 切換到上一張卡片
    func goToPreviousCard() {
        if currentIndex > 0 {
            currentIndex -= 1
            resetCardState()
        }
    }
    
    // 重置卡片的翻轉狀態
    func resetCardState() {
        if isFlipped {
            rotation += 180
            isFlipped = false
        }
    }
}

// 用於顯示單字卡單面的輔助視圖
struct FlashcardSide: View {
    let content: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.appCaption(for: title))
                .foregroundColor(.white)
                .padding(5)
                .background(color.opacity(0.8))
                .cornerRadius(5)
            
            Spacer()
            
            Text(content)
                .font(.appTitle2(for: content))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color, lineWidth: 2)
        )
    }
}

#Preview {
    // 提供一些假資料讓預覽可以運作
    NavigationView {
        FlashcardView(flashcards: [
            Flashcard(front: "in the other hand", back_correction: "on the other hand", back_explanation: "'on the other hand' 是正確的慣用語，表示另一方面。", category: "慣用語不熟")
        ])
    }
}
