// ArchivedPointsView.swift

import SwiftUI

struct ArchivedPointsView: View {
    @State private var archivedPoints: [KnowledgePoint] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("正在載入...")
            } else if let errorMessage = errorMessage {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                    Text("載入失敗")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else if archivedPoints.isEmpty {
                Text("封存區是空的")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(archivedPoints) { point in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(point.correct_phrase)
                                .fontWeight(.bold)
                            Text(point.key_point_summary ?? "核心觀念")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 5)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                Task {
                                    await unarchivePoint(id: point.id)
                                }
                            } label: {
                                Label("取消封存", systemImage: "arrow.uturn.backward.circle.fill")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("🗄️ 封存區")
        .onAppear(perform: fetchArchivedPoints)
    }
    
    private func fetchArchivedPoints() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                self.archivedPoints = try await KnowledgePointAPIService.fetchArchivedPoints()
            } catch {
                if let apiError = error as? APIError {
                    switch apiError {
                    case .serverError(_, let message):
                        self.errorMessage = message
                    default:
                        self.errorMessage = "發生未知網路錯誤，請稍後再試。"
                    }
                } else {
                    self.errorMessage = error.localizedDescription
                }
            }
            isLoading = false
        }
    }

    private func unarchivePoint(id: Int) async {
        do {
            try await KnowledgePointAPIService.unarchivePoint(id: id)
            // 從列表中移除，製造即時反饋
            archivedPoints.removeAll { $0.id == id }
        } catch {
            // 在此可以加入錯誤處理的 Alert
            print("取消封存失敗: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        ArchivedPointsView()
    }
}
