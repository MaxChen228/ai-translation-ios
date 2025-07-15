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
                    List {
                        // 表頭
                        HStack {
                            Text("熟練度").frame(width: 120, alignment: .leading)
                            Spacer()
                            Text("錯誤").frame(width: 50)
                            Text("答對").frame(width: 50)
                        }
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        
                        // 知識點列表
                        ForEach(knowledgePoints) { point in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(point.category) → \(point.subcategory)")
                                    .font(.headline)
                                
                                HStack {
                                    // 使用 ProgressView 作為熟練度進度條
                                    ProgressView(value: point.mastery_level, total: 5.0)
                                        .frame(width: 120)
                                        .tint(masteryColor(level: point.mastery_level))
                                    
                                    Spacer()
                                    
                                    Text("\(point.mistake_count)").frame(width: 50)
                                    Text("\(point.correct_count)").frame(width: 50)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .navigationTitle("🧠 知識點儀表板")
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
    
    // 根據熟練度決定進度條顏色
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
