//  DashboardView.swift

import SwiftUI

// 【新增】定義儀表板的兩種顯示模式
enum DashboardMode: String, CaseIterable, Identifiable {
    case byCategory = "分類檢視"
    case bySchedule = "複習排程"
    var id: Self { self }
}

struct DashboardView: View {
    
    @State private var knowledgePoints: [KnowledgePoint] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // 【新增】用來控制當前顯示模式的狀態變數
    @State private var selectedMode: DashboardMode = .byCategory
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 【新增】模式切換選單
                Picker("檢視模式", selection: $selectedMode) {
                    ForEach(DashboardMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // 根據選擇的模式，顯示對應的內容
                if isLoading {
                    Spacer()
                    ProgressView("正在載入儀表板數據...")
                    Spacer()
                } else if let errorMessage = errorMessage {
                    Spacer()
                    Text("錯誤：\(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                } else if knowledgePoints.isEmpty {
                    Spacer()
                    Text("太棒了！目前沒有任何弱點紀錄。\n開始練習來建立您的分析報告吧！")
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
                    // 【新增】使用 switch 來切換視圖
                    switch selectedMode {
                    case .byCategory:
                        CategoryListView(points: knowledgePoints)
                    case .bySchedule:
                        ReviewScheduleView(points: knowledgePoints)
                    }
                }
            }
            .navigationTitle("🧠 知識點儀表板")
            .toolbar {
                // 【新增】ToolbarItemGroup 來放置多個按鈕
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 原有的刷新按鈕
                    Button(action: {
                        Task {
                            await fetchDashboardData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    
                    // 新增的封存區按鈕
                    Button(action: {
                        // TODO: 導航到封存區視圖
                    }) {
                        Image(systemName: "archivebox")
                    }
                }
            }
            .onAppear {
                if knowledgePoints.isEmpty {
                    Task {
                        await fetchDashboardData()
                    }
                }
            }
        }
    }

    
    // 網路請求函式 (維持不變)
    func fetchDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://ai-tutor-ikjn.onrender.com/get_dashboard") else {
            errorMessage = "無效的網址"
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedResponse = try JSONDecoder().decode(DashboardResponse.self, from: data)
            self.knowledgePoints = decodedResponse.knowledge_points
        } catch {
            self.errorMessage = "無法獲取數據，請稍後再試。\n(\(error.localizedDescription))"
            print("獲取儀表板數據時發生錯誤: \(error)")
        }
        
        isLoading = false
    }
}

// 【新增】將原本的「分類列表」邏輯，封裝成獨立的子視圖
struct CategoryListView: View {
    let points: [KnowledgePoint]
    
    private var groupedPoints: [String: [KnowledgePoint]] {
        Dictionary(grouping: points, by: { $0.category })
    }
    
    var body: some View {
        List {
            ForEach(groupedPoints.keys.sorted(), id: \.self) { category in
                NavigationLink(destination: KnowledgePointGridView(points: groupedPoints[category]!, categoryTitle: category)) {
                    HStack {
                        Text(category)
                            .font(.headline)
                        Spacer()
                        Text("\(groupedPoints[category]!.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

// 【新增】全新的「複習排程」子視圖
struct ReviewScheduleView: View {
    let points: [KnowledgePoint]
    
    // 將知識點按日期排序
    private var scheduledPoints: [KnowledgePoint] {
        points.filter { $0.next_review_date != nil }
              .sorted { $0.next_review_date! < $1.next_review_date! }
    }
    
    // 日期格式化工具
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy 年 M 月 d 日"
            return outputFormatter.string(from: date)
        }
        return dateString
    }
    
    var body: some View {
        List {
            ForEach(scheduledPoints) { point in
                NavigationLink(destination: KnowledgePointDetailView(point: point)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(point.key_point_summary ?? "核心觀念")
                                .font(.headline)
                                .lineLimit(1)
                            Text(point.correct_phrase)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // 標註複習日期
                        Text(formatDate(point.next_review_date ?? ""))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }
}
