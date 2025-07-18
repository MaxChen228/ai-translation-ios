// ArchivedPointsView.swift

import SwiftUI

struct ArchivedPointsView: View {
    @State private var archivedPoints: [KnowledgePoint] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("正在載入...")
                        .font(.appSubheadline(for: "正在載入..."))
                }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.appLargeTitle(for: "⚠️"))
                        .foregroundColor(.yellow)
                    Text("載入失敗")
                        .font(.appHeadline(for: "載入失敗"))
                    Text(errorMessage)
                        .font(.appCaption(for: errorMessage))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else if archivedPoints.isEmpty {
                Text("封存區是空的")
                    .font(.appHeadline(for: "封存區是空的"))
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(archivedPoints) { point in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(point.correct_phrase)
                                .font(.appCallout(for: point.correct_phrase))
                                .fontWeight(.medium)
                            Text(point.key_point_summary ?? "核心觀念")
                                .font(.appCaption(for: point.key_point_summary ?? "核心觀念"))
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
                    case .invalidURL:
                        self.errorMessage = "無效的網址"
                    case .invalidResponse:
                        self.errorMessage = "伺服器回應無效"
                    case .decodingError:
                        self.errorMessage = "資料解析失敗"
                    default:
                        self.errorMessage = "發生未知網路錯誤"
                    }
                } else {
                    self.errorMessage = "發生未知錯誤"
                }
            }
            isLoading = false
        }
    }
    
    private func unarchivePoint(id: Int) async {
        do {
            try await KnowledgePointAPIService.unarchivePoint(id: id)
            // 重新載入資料
            await fetchArchivedPoints()
        } catch {
            print("取消封存失敗: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        ArchivedPointsView()
    }
}
