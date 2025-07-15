// ContentView.swift

import SwiftUI

struct ContentView: View {
    // 從環境中讀取共享的 sessionManager
    @EnvironmentObject var sessionManager: SessionManager
    
    // 這兩個狀態變數只用於管理此畫面的載入和錯誤狀態
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("AI 老師備課中...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let errorMessage = errorMessage {
                    Text("發生錯誤：\(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // 列表的資料來源已改為 sessionManager.sessionQuestions
                    List(sessionManager.sessionQuestions) { sessionQuestion in
                        // 使用 NavigationLink 導航到作答頁面，並傳遞題目的ID
                        NavigationLink(destination: AnswerView(sessionQuestionId: sessionQuestion.id)) {
                            HStack(spacing: 15) {
                                // 根據 isCompleted 狀態顯示不同的圖示
                                Image(systemName: sessionQuestion.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(sessionQuestion.isCompleted ? .green : .gray.opacity(0.5))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(sessionQuestion.question.new_sentence)
                                        .font(.headline)
                                    Text("類型: \(sessionQuestion.question.type)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .navigationTitle("AI 英文家教")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 按下按鈕時，清空舊的錯誤訊息並開始獲取新題目
                        self.errorMessage = nil
                        Task {
                            await fetchQuestions()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise.circle")
                    }
                }
            }
            // 讓 App 啟動時自動獲取一次題目
            .onAppear {
                if sessionManager.sessionQuestions.isEmpty {
                    Task {
                        await fetchQuestions()
                    }
                }
            }
        }
    }
    
    func fetchQuestions() async {
        isLoading = true
        errorMessage = nil

        // 1. 從 SettingsManager 讀取所有使用者設定
        let reviewCount = SettingsManager.shared.reviewCount
        let newCount = SettingsManager.shared.newCount
        let difficulty = SettingsManager.shared.difficulty
        let length = SettingsManager.shared.length.rawValue // 注意要傳送 rawValue ("short", "medium", "long")
        
        // 2. 建立 URL 並附加所有參數
        guard var urlComponents = URLComponents(string: "https://ai-tutor-ikjn.onrender.com/start_session") else {
            errorMessage = "無效的網址"
            isLoading = false
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "num_review", value: String(reviewCount)),
            URLQueryItem(name: "num_new", value: String(newCount)),
            URLQueryItem(name: "difficulty", value: String(difficulty)),
            URLQueryItem(name: "length", value: length)
        ]
        
        guard let url = urlComponents.url else {
            errorMessage = "無法建立 URL"
            isLoading = false
            return
        }
        
        print("Requesting URL: \(url.absoluteString)") // 方便偵錯
        
        // 3. 發送網路請求 (後續不變)
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedResponse = try JSONDecoder().decode(QuestionsResponse.self, from: data)
            
            // 將獲取到的題目交給 sessionManager 去建立新的學習回合
            sessionManager.startNewSession(questions: decodedResponse.questions)
            
        } catch {
            self.errorMessage = "無法獲取題目，請檢查網路連線或稍後再試。\n(\(error.localizedDescription))"
            print("獲取題目時發生錯誤: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionManager()) // 在預覽中也注入一個 SessionManager
}
