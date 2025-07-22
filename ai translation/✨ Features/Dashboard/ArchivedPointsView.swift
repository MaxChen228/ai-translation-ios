// ArchivedPointsView.swift

import SwiftUI

struct ArchivedPointsView: View {
    @State private var archivedPoints: [KnowledgePoint] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: ModernSpacing.md) {
                    ProgressView()
                    Text("正在載入...")
                        .font(.appSubheadline(for: "正在載入..."))
                }
            } else if let errorMessage = errorMessage {
                VStack(spacing: ModernSpacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.appLargeTitle())
                        .foregroundStyle(Color.modernWarning)
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
                    .foregroundStyle(Color.modernTextSecondary)
            } else {
                List {
                    ForEach(archivedPoints) { point in
                        VStack(alignment: .leading, spacing: ModernSpacing.sm) {
                            Text(point.correctPhrase)
                                .font(.appCallout(for: point.correctPhrase))
                                .fontWeight(.medium)
                            Text(point.keyPointSummary ?? "核心觀念")
                                .font(.appCaption(for: point.keyPointSummary ?? "核心觀念"))
                                .foregroundStyle(Color.modernTextSecondary)
                        }
                        .padding(.vertical, ModernSpacing.sm)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                Task {
                                    await unarchivePoint(id: point.id)
                                }
                            } label: {
                                Label("取消封存", systemImage: "arrow.uturn.backward.circle.fill")
                            }
                            .tint(Color.modernSpecial)
                        }
                    }
                }
            }
        }
        .navigationTitle("封存區")
        .onAppear(perform: fetchArchivedPoints)
    }
    
    private func fetchArchivedPoints() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                self.archivedPoints = try await UnifiedAPIService.shared.fetchArchivedKnowledgePoints()
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
            try await UnifiedAPIService.shared.unarchiveKnowledgePoint(id: id)
            // 重新載入資料
            fetchArchivedPoints()
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
