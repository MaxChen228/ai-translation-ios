// LearningCalendarView.swift

import SwiftUI

// 先定義一個儲存單日活動數據的結構體，讓程式碼更清晰
struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let activityCount: Int
}

struct LearningCalendarView: View {
    // 狀態變數
    @State private var monthData: [Date: Int] = [:] // 儲存從 API 獲取的數據 {日期: 題數}
    @State private var selectedDate = Date() // 當前顯示的月份
    @State private var isLoading = false
    
    // 從設定管理器讀取每日目標
    private var dailyGoal: Int {
        SettingsManager.shared.dailyGoal
    }

    var body: some View {
        NavigationView {
            VStack {
                // 月份切換器
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left.circle.fill")
                    }
                    .font(.title2)
                    
                    Text(selectedDate, style: .date)
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right.circle.fill")
                    }
                    .font(.title2)
                }
                .padding()

                // 星期標頭 (日、一、二...)
                HStack {
                    ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                        Text(day)
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // 月曆網格
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(fetchDaysInMonth(), id: \.self) { date in
                        if let date = date {
                            dayCell(for: date)
                        } else {
                            // 用於佔位的空白視圖
                            Rectangle().fill(Color.clear)
                        }
                    }
                }
                .padding(10)
                
                Spacer()
            }
            .navigationTitle("🗓️ 學習日曆")
            .onAppear(perform: loadDataForCurrentMonth)
            .onChange(of: selectedDate) { _, _ in loadDataForCurrentMonth() }
        }
    }
    
    // 單一日期格子的視圖
    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let count = monthData[date] ?? 0
        let intensity = min(1.0, Double(count) / Double(dailyGoal)) // 計算顏色強度
        let isToday = Calendar.current.isDateInToday(date)

        VStack(spacing: 4) {
            Text("\(dayNumber(from: date))")
                .font(.system(size: 14))
                .fontWeight(isToday ? .bold : .regular)
                .frame(width: 24, height: 24)
                .background(isToday ? Color.blue.opacity(0.3) : Color.clear)
                .clipShape(Circle())

            // 顯示當日題數，如果為 0 則不顯示
            if count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 45, height: 50)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(intensity)) // 根據強度填滿顏色
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1) // 加上淡淡的邊框
        )
    }

    // --- 輔助函式 ---

    private func loadDataForCurrentMonth() {
        isLoading = true
        let components = Calendar.current.dateComponents([.year, .month], from: selectedDate)
        guard let year = components.year, let month = components.month else { return }
        
        Task {
            await fetchHeatmapData(year: year, month: month)
            isLoading = false
        }
    }
    
    // 網路請求函式
    private func fetchHeatmapData(year: Int, month: Int) async {
        guard var urlComponents = URLComponents(string: "https://ai-tutor-ikjn.onrender.com/get_calendar_heatmap") else { return }
        urlComponents.queryItems = [
            URLQueryItem(name: "year", value: String(year)),
            URLQueryItem(name: "month", value: String(month))
        ]
        guard let url = urlComponents.url else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(HeatmapResponse.self, from: data)
            
            // 將 API 回傳的 ["YYYY-MM-DD": count] 轉換為 [Date: count]
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            
            var newMonthData: [Date: Int] = [:]
            for (dateString, count) in response.heatmap_data {
                if let date = formatter.date(from: dateString) {
                    newMonthData[date] = count
                }
            }
            
            // 在主執行緒上更新 UI
            await MainActor.run {
                self.monthData = newMonthData
            }
        } catch {
            print("無法載入熱力圖數據: \(error)")
        }
    }
    
    // 計算指定月份的所有日期，並包含開頭的空白
    private func fetchDaysInMonth() -> [Date?] {
        // 【核心修正】: 將 let monthInterval 改為 let _
        guard let _ = Calendar.current.dateInterval(of: .month, for: selectedDate),
              let firstDayOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: selectedDate))
        else { return [] }

        let firstWeekday = Calendar.current.component(.weekday, from: firstDayOfMonth)
        
        var days: [Date?] = []
        // 1. 填入月份第一天前的空白
        for _ in 0..<(firstWeekday - 1) {
            days.append(nil)
        }
        
        // 2. 填入該月份的所有日期
        let numberOfDays = Calendar.current.range(of: .day, in: .month, for: selectedDate)!.count
        for dayOffset in 0..<numberOfDays {
            if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func dayNumber(from date: Date) -> Int {
        Calendar.current.component(.day, from: date)
    }
    
    private func changeMonth(by amount: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: amount, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// 為了讓 JSONDecoder 能解析 API 回應，我們需要一個對應的結構
struct HeatmapResponse: Codable {
    let heatmap_data: [String: Int]
}
