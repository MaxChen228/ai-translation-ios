// DailyDetailView.swift

import SwiftUI

struct DailyDetailView: View {
    // 從月曆頁面接收傳過來的日期
    let selectedDate: Date
    
    // 狀態變數
    @State private var details: DailyDetailResponse?
    @State private var isLoading = false
    
    // 將秒數格式化為 "X 分 Y 秒"
    private var formattedLearningTime: String {
        guard let totalSeconds = details?.total_learning_time_seconds else { return "0 分 0 秒" }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes) 分 \(seconds) 秒"
    }
    
    // 將 Date 物件格式化為 "YYYY-MM-DD" 字串，用於 API 請求
    private var dateStringForAPI: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }

    // 【新增】一個專門用來格式化導航欄標題的計算屬性
    private var navigationTitleString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long // 例如 "July 16, 2025"
        formatter.timeStyle = .none
        // 為了符合本地習慣，可以設定地區
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("正在載入學習紀錄...")
            } else if let details = details {
                // 如果成功載入數據，顯示內容
                List {
                    // 區塊一：總學習時間 (維持不變)
                    Section(header: Text("學習時長統計")) {
                        HStack {
                            Image(systemName: "timer")
                                .font(.title)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("總學習時間")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formattedLearningTime)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 【核心修改】區塊二：當日「已複習」的知識點
                    Section(header: Text("當日已複習的知識點")) {
                        if details.reviewed_knowledge_points.isEmpty {
                            Text("今天沒有複習舊的知識點。")
                                .padding(.vertical, 10)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(details.reviewed_knowledge_points) { point in
                                HStack {
                                    Text(point.summary)
                                    Spacer()
                                    Text("x\(point.count)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .background(Color.green.opacity(0.2)) // 用不同顏色區分
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // 【核心修改】區塊三：當日「新學習」的知識點
                    Section(header: Text("當日新學習的知識點")) {
                        if details.new_knowledge_points.isEmpty {
                            Text("今天沒有記錄到新的錯誤知識點，繼續保持！")
                                .padding(.vertical, 10)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(details.new_knowledge_points) { point in
                                HStack {
                                    Text(point.summary)
                                    Spacer()
                                    Text("x\(point.count)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .background(Color.orange.opacity(0.2)) // 用不同顏色區分
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            } else {
                // 如果沒有數據或載入失敗
                Text("無法載入該日期的學習紀錄。")
            }
        }
        .navigationTitle(navigationTitleString) // 使用我們之前修正過的版本
        .onAppear(perform: loadDailyDetails)
    }
    
    // 網路請求函式
    private func loadDailyDetails() {
        isLoading = true
        Task {
            guard var urlComponents = URLComponents(string: "https://ai-tutor-ikjn.onrender.com/api/get_daily_details") else { return }
            urlComponents.queryItems = [
                URLQueryItem(name: "date", value: dateStringForAPI)
            ]
            guard let url = urlComponents.url else { return }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decodedResponse = try JSONDecoder().decode(DailyDetailResponse.self, from: data)
                await MainActor.run {
                    self.details = decodedResponse
                }
            } catch {
                print("無法載入單日詳情: \(error)")
            }
            isLoading = false
        }
    }
}
