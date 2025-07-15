// DeckSelectionView.swift

import SwiftUI

struct DeckSelectionView: View {
    // 所有可選的錯誤類型 (您可以未來從 API 獲取或在此處擴充)
    let allErrorTypes = ["慣用語不熟", "介系詞搭配", "單字選擇", "文法錯誤", "句構問題"]
    
    // 使用 @State 追蹤使用者勾選了哪些類型
    @State private var selectedTypes: Set<String> = []
    
    // 用於控制是否跳轉到單字卡複習頁面
    @State private var navigateToFlashcards = false
    // 用於儲存從 API 獲取到的單字卡
    @State private var fetchedFlashcards: [Flashcard] = []
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        // --- 修改開始：使用新的 NavigationStack ---
        NavigationStack {
            VStack {
                List(allErrorTypes, id: \.self) { type in
                    Button(action: {
                        // 點擊時，切換選中狀態
                        if selectedTypes.contains(type) {
                            selectedTypes.remove(type)
                        } else {
                            selectedTypes.insert(type)
                        }
                    }) {
                        HStack {
                            // 根據是否被選中，顯示不同的圖示
                            Image(systemName: selectedTypes.contains(type) ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedTypes.contains(type) ? .blue : .gray)
                            Text(type)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())

                Spacer()

                // "開始複習" 按鈕
                Button(action: {
                    Task {
                        await fetchFlashcards()
                    }
                }) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("開始複習 (\(selectedTypes.count))")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(selectedTypes.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(selectedTypes.isEmpty || isLoading)
                .padding()
                
                if let errorMessage = errorMessage {
                    Text("錯誤: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                // --- 修改：舊的 NavigationLink 已被移除 ---
            }
            .navigationTitle("選擇複習卡集")
            // --- 修改開始：加上新的 .navigationDestination 修飾符 ---
            .navigationDestination(isPresented: $navigateToFlashcards) {
                FlashcardView(flashcards: fetchedFlashcards)
            }
        }
    }
    
    func fetchFlashcards() async {
        isLoading = true
        errorMessage = nil
        
        // 將使用者選擇的類型集合，轉換成用逗號分隔的字串
        let typesString = selectedTypes.joined(separator: ",")
        
        // 使用 URLComponents 來安全地建立包含查詢參數的 URL
        var components = URLComponents(string: "https://ai-tutor-ikjn.onrender.com/get_flashcards")!
        components.queryItems = [
            URLQueryItem(name: "types", value: typesString)
        ]
        
        guard let url = components.url else {
            errorMessage = "無法建立請求網址"
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedResponse = try JSONDecoder().decode(FlashcardsResponse.self, from: data)
            
            if decodedResponse.flashcards.isEmpty {
                errorMessage = "找不到符合條件的卡片，多練習一些題目再來吧！"
            } else {
                self.fetchedFlashcards = decodedResponse.flashcards
                self.navigateToFlashcards = true // 觸發跳轉
            }
            
        } catch {
            self.errorMessage = "無法獲取單字卡: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    DeckSelectionView()
}
