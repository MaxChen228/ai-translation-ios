// LearningCalendarView.swift - Claude風格重新設計

import SwiftUI

struct LearningCalendarView: View {
    @State private var monthData: [DateComponents: Int] = [:]
    @State private var selectedDate = Date()
    @State private var isLoading = false
    
    private var dailyGoal: Int {
        SettingsManager.shared.dailyGoal
    }
    
    // Claude風格的月份名稱格式化
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: selectedDate)
    }
    
    // 當月統計
    private var monthStats: MonthStats {
        MonthStats(from: monthData, goal: dailyGoal)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: ModernSpacing.lg) {
                    // 頂部統計卡片
                    MonthStatsCard(stats: monthStats, monthText: monthYearText)
                    
                    // 月曆主體
                    CalendarCard(
                        selectedDate: $selectedDate,
                        monthData: monthData,
                        dailyGoal: dailyGoal,
                        onMonthChange: loadDataForCurrentMonth
                    )
                }
                .padding(ModernSpacing.lg)
            }
            .background(Color.modernBackground)
            .navigationTitle("學習日曆")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadDataForCurrentMonth) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.modernAccent)
                    }
                }
            }
            .onAppear(perform: loadDataForCurrentMonth)
            .onChange(of: selectedDate) { _, _ in loadDataForCurrentMonth() }
        }
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
        do {
            let response = try await UnifiedAPIService.shared.getCalendarHeatmap(year: year, month: month)
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            
            var newMonthData: [DateComponents: Int] = [:]
            for (dateString, count) in response.heatmap_data {
                if let date = formatter.date(from: dateString) {
                    let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                    newMonthData[components] = count
                }
            }
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.monthData = newMonthData
                }
            }
        } catch APIError.serverError(let statusCode, let message) {
            print("伺服器錯誤 (\(statusCode)): \(message)")
        } catch {
            print("無法載入熱力圖數據: \(error)")
        }
    }
}

// MARK: - Claude風格組件

struct MonthStats {
    let totalDays: Int
    let activeDays: Int
    let totalQuestions: Int
    let averagePerDay: Double
    let goalAchievedDays: Int
    let currentStreak: Int
    
    init(from data: [DateComponents: Int], goal: Int) {
        let counts = Array(data.values)
        totalDays = data.count
        activeDays = counts.filter { $0 > 0 }.count
        totalQuestions = counts.reduce(0, +)
        let rawAverage = activeDays > 0 ? Double(totalQuestions) / Double(activeDays) : 0
        averagePerDay = rawAverage.isNaN || rawAverage.isInfinite ? 0 : rawAverage
        goalAchievedDays = counts.filter { $0 >= goal }.count
        
        // 計算連續學習天數（簡化版）
        currentStreak = activeDays // 這裡可以改為更精確的連續天數計算
    }
}

struct MonthStatsCard: View {
    let stats: MonthStats
    let monthText: String
    
    var body: some View {
        VStack(spacing: ModernSpacing.lg) {
            // 月份標題
            HStack {
                Text(monthText)
                    .font(.appTitle2(for: "月份"))
                    .foregroundStyle(Color.modernTextPrimary)
                Spacer()
                
                // 達成率指示器
                GoalIndicator(
                    achieved: stats.goalAchievedDays,
                    total: max(1, stats.activeDays)
                )
            }
            
            // 統計網格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: ModernSpacing.md), count: 2), spacing: ModernSpacing.md) {
                StatMini(title: "學習天數", value: "\(stats.activeDays)", icon: "calendar.badge.checkmark")
                StatMini(title: "總題數", value: "\(stats.totalQuestions)", icon: "list.number")
                StatMini(title: "日均題數", value: safeFormatDouble(stats.averagePerDay), icon: "chart.line.uptrend.xyaxis")
                StatMini(title: "達標天數", value: "\(stats.goalAchievedDays)", icon: "target")
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
        }
    }
}

struct StatMini: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: ModernSpacing.md) {
            Image(systemName: icon)
                .font(.appCallout(for: "統計標籤"))
                .foregroundStyle(Color.modernAccent)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                Text(value)
                    .font(.appCallout(for: "統計數值"))
                    .foregroundStyle(Color.modernTextPrimary)
                
                Text(title)
                    .font(.appCaption2(for: "小標籤"))
                    .foregroundStyle(Color.modernTextSecondary)
            }
            
            Spacer()
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernSurface)
        }
    }
}

struct GoalIndicator: View {
    let achieved: Int
    let total: Int
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        let result = Double(achieved) / Double(total)
        return result.isNaN || result.isInfinite ? 0 : min(1.0, max(0.0, result))
    }
    
    var body: some View {
        HStack(spacing: ModernSpacing.sm) {
            ZStack {
                Circle()
                    .stroke(Color.modernTextTertiary.opacity(0.2), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(Color.modernAccent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: percentage)
            }
            
            VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                Text("\(Int(percentage * 100))%")
                    .font(.appSubheadline(for: "星期"))
                    .foregroundStyle(Color.modernTextPrimary)
                
                Text("達標率")
                    .font(.appCaption2(for: "星期簡稱"))
                    .foregroundStyle(Color.modernTextSecondary)
            }
        }
    }
}

struct CalendarCard: View {
    @Binding var selectedDate: Date
    let monthData: [DateComponents: Int]
    let dailyGoal: Int
    let onMonthChange: () -> Void
    
    var body: some View {
        VStack(spacing: ModernSpacing.lg) {
            // 月份導航
            MonthNavigation(selectedDate: $selectedDate, onMonthChange: onMonthChange)
            
            // 星期標頭
            WeekdayHeader()
            
            // 日期網格
            DateGrid(
                selectedDate: selectedDate,
                monthData: monthData,
                dailyGoal: dailyGoal
            )
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
        }
    }
}

struct MonthNavigation: View {
    @Binding var selectedDate: Date
    let onMonthChange: () -> Void
    
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.appCallout(for: "統計數值"))
                    .foregroundStyle(Color.modernTextPrimary)
                    .frame(width: 32, height: 32)
                    .background {
                        Circle()
                            .fill(Color.modernSurface)
                    }
            }
            
            Spacer()
            
            Text(monthYearText)
                .font(.appTitle3(for: "詳細標題"))
                .foregroundStyle(Color.modernTextPrimary)
            
            Spacer()
            
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.appCallout(for: "統計數值"))
                    .foregroundStyle(Color.modernTextPrimary)
                    .frame(width: 32, height: 32)
                    .background {
                        Circle()
                            .fill(Color.modernSurface)
                    }
            }
        }
    }
    
    private func changeMonth(by amount: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: amount, to: selectedDate) {
            selectedDate = newDate
            onMonthChange()
        }
    }
}

struct WeekdayHeader: View {
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
    
    var body: some View {
        HStack(spacing: ModernSpacing.xs) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.appCaption(for: "日期數字"))
                    .foregroundStyle(Color.modernTextSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct DateGrid: View {
    let selectedDate: Date
    let monthData: [DateComponents: Int]
    let dailyGoal: Int
    
    private var dateRange: [Date?] {
        fetchDaysInMonth()
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: ModernSpacing.sm), count: 7), spacing: ModernSpacing.sm) {
            ForEach(0..<dateRange.count, id: \.self) { index in
                if let date = dateRange[index] {
                    DateCell(
                        date: date,
                        count: getCountForDate(date),
                        dailyGoal: dailyGoal
                    )
                } else {
                    Color.clear
                        .frame(height: 48)
                }
            }
        }
    }
    
    private func getCountForDate(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return monthData[components] ?? 0
    }
    
    private func fetchDaysInMonth() -> [Date?] {
        guard let firstDayOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: selectedDate))
        else { return [] }

        let firstWeekday = Calendar.current.component(.weekday, from: firstDayOfMonth)
        var days: [Date?] = []
        
        // 前置空白
        for _ in 0..<(firstWeekday - 1) {
            days.append(nil)
        }
        
        // 當月日期
        let numberOfDays = Calendar.current.range(of: .day, in: .month, for: selectedDate)!.count
        for dayOffset in 0..<numberOfDays {
            if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
}

struct DateCell: View {
    let date: Date
    let count: Int
    let dailyGoal: Int
    
    private var dayNumber: String {
        String(Calendar.current.component(.day, from: date))
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var intensity: Double {
        dailyGoal > 0 ? min(1.0, Double(count) / Double(dailyGoal)) : 0
    }
    
    private var backgroundOpacity: Double {
        if count == 0 { return 0 }
        return 0.15 + (intensity * 0.85) // 0.15 到 1.0 的範圍
    }
    
    var body: some View {
        NavigationLink(destination: DailyDetailView(selectedDate: date)) {
            VStack(spacing: ModernSpacing.xs) {
                Text(dayNumber)
                    .font(.appSubheadline(for: "日期"))
                    .foregroundStyle(isToday ? Color.modernAccent : .primary)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.appCaption2(for: "進度點"))
                        .foregroundStyle(Color.modernAccent)
                        .padding(.horizontal, ModernSpacing.sm)
                        .padding(.vertical, ModernSpacing.xs)
                        .background {
                            Capsule()
                                .fill(Color.modernAccent.opacity(0.15))
                        }
                }
            }
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: ModernRadius.sm)
                    .fill(count > 0 ? Color.modernAccent.opacity(backgroundOpacity) : Color.clear)
                    .overlay {
                        if isToday {
                            RoundedRectangle(cornerRadius: ModernRadius.sm)
                                .stroke(Color.modernAccent, lineWidth: 2)
                        }
                    }
            }
        }
        .disabled(count == 0)
        .buttonStyle(.plain)
    }
}

struct HeatmapResponse: Codable {
    let heatmap_data: [String: Int]
}

// MARK: - 安全的格式化輔助函數

private func safeFormatDouble(_ value: Double) -> String {
    if value.isNaN || value.isInfinite {
        return "0.0"
    }
    return String(format: "%.1f", value)
}
