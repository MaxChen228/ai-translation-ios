//  DashboardView.swift

import SwiftUI

struct DashboardView: View {
    
    @State private var knowledgePoints: [KnowledgePoint] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("正在載入儀表板數據...")
                } else if let errorMessage = errorMessage {
                    Text("錯誤：\(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else if knowledgePoints.isEmpty {
                    Text("太棒了！目前沒有任何弱點紀錄。\n開始練習來建立您的分析報告吧！")
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    // 【核心修改處】: 將原來的長列表改為顯示分類列表
                    List {
                        ForEach(groupedPoints.keys.sorted(), id: \.self) { category in
                            // 每個分類都是一個導航連結，點擊後進入雙欄網格頁面
                            NavigationLink(destination: KnowledgePointGridView(points: groupedPoints[category]!, categoryTitle: category)) {
                                HStack {
                                    Text(category)
                                        .font(.headline)
                                    Spacer()
                                    // 顯示該分類下有多少個知識點
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
            .navigationTitle("知識點儀表板")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await fetchDashboardData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            // 讓頁面出現時自動載入一次數據
            .onAppear {
                Task {
                    await fetchDashboardData()
                }
            }
        }
    }
    
    // 【新增】一個計算屬性，用來將扁平的知識點陣列，轉換為按 category 分組的字典
    private var groupedPoints: [String: [KnowledgePoint]] {
        Dictionary(grouping: knowledgePoints, by: { $0.category })
    }
    
    // 根據熟練度決定進度條顏色 (此函式在 GridView 中也會用到)
    private func masteryColor(level: Double) -> Color {
        if level < 1.5 {
            return .red
        } else if level < 3.5 {
            return .orange
        } else {
            return .green
        }
    }
    
    // 獲取儀表板數據的網路請求函式
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

#Preview {
    DashboardView()
}
