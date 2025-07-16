// LearningCalendarView.swift

import SwiftUI

struct LearningCalendarView: View {
    // 【核心修正 1】: 將 monthData 的 Key 從 Date 改為 DateComponents
    @State private var monthData: [DateComponents: Int] = [:]
    
    @State private var selectedDate = Date()
    @State private var isLoading = false
    
    private var dailyGoal: Int {
        SettingsManager.shared.dailyGoal
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 月份切換器和星期標頭... (此處省略以保持簡潔，您的原碼無誤)
                HStack {
                    Button(action: { changeMonth(by: -1) }) { Image(systemName: "chevron.left.circle.fill") }.font(.title2)
                    Text(selectedDate, style: .date).font(.title2.bold()).frame(maxWidth: .infinity)
                    Button(action: { changeMonth(by: 1) }) { Image(systemName: "chevron.right.circle.fill") }.font(.title2)
                }.padding()
                HStack {
                    ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                        Text(day).frame(maxWidth: .infinity).font(.headline).foregroundColor(.secondary)
                    }
                }.padding(.horizontal)

                // 月曆網格
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(fetchDaysInMonth(), id: \.self) { date in
                        if let date = date {
                            dayCell(for: date)
                        } else {
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
    
    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        // 【第 1 處】: 將 Date 轉換為 DateComponents
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        // 【第 2 處】: 用 DateComponents 作為 Key 來查詢，現在類型匹配了
        let count = monthData[components] ?? 0
        
        let intensity = min(1.0, Double(count) / Double(dailyGoal))
        let isToday = Calendar.current.isDateInToday(date)

        NavigationLink(destination: DailyDetailView(selectedDate: date)) {
            VStack(spacing: 4) {
                Text("\(dayNumber(from: date))")
                    .font(.system(size: 14))
                    .fontWeight(isToday ? .bold : .regular)
                    .frame(width: 24, height: 24)
                    .background(isToday ? Color.blue.opacity(0.3) : Color.clear)
                    .clipShape(Circle())
                    .foregroundColor(.primary)

                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 45, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(intensity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(count == 0)
    }

    private func loadDataForCurrentMonth() {
        isLoading = true
        let components = Calendar.current.dateComponents([.year, .month], from: selectedDate)
        guard let year = components.year, let month = components.month else { return }
        
        Task {
            await fetchHeatmapData(year: year, month: month)
            isLoading = false
        }
    }
    
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
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            
            // 【核心修正 3】: 將 API 回傳的資料轉換為 [DateComponents: Int] 字典
            var newMonthData: [DateComponents: Int] = [:]
            for (dateString, count) in response.heatmap_data {
                if let date = formatter.date(from: dateString) {
                    let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                    newMonthData[components] = count
                }
            }
            
            await MainActor.run {
                self.monthData = newMonthData
            }
        } catch {
            print("無法載入熱力圖數據: \(error)")
        }
    }
    
    private func fetchDaysInMonth() -> [Date?] {
        guard let _ = Calendar.current.dateInterval(of: .month, for: selectedDate),
              let firstDayOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: selectedDate))
        else { return [] }

        let firstWeekday = Calendar.current.component(.weekday, from: firstDayOfMonth)
        var days: [Date?] = []
        for _ in 0..<(firstWeekday - 1) {
            days.append(nil)
        }
        
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

struct HeatmapResponse: Codable {
    let heatmap_data: [String: Int]
}
