//
//  MultiClassificationCategoryView.swift
//  ai translation
//
//  多分類類別選擇畫面
//

import SwiftUI

struct MultiClassificationCategoryView: View {
    let system: ClassificationSystem
    @StateObject private var service = MultiClassificationService()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            if service.isLoading {
                ProgressView("載入中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if let errorMessage = service.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("載入失敗")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("重試") {
                        Task {
                            await service.fetchCategoryInfo(systemCode: system.systemCode)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else if let categoryInfo = service.categoryInfo {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(categoryInfo.availableCategories, id: \.self) { category in
                        NavigationLink(destination: MultiClassificationWordListView(
                            system: system,
                            category: category
                        )) {
                            CategoryCard(
                                category: category,
                                systemCode: system.systemCode,
                                stats: categoryInfo.categoryStats[category]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            } else {
                // 空狀態
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("沒有找到類別")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            }
        }
        .navigationTitle(system.systemName)
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .task {
            print("🔵 MultiClassificationCategoryView: 正在載入類別資訊，系統代碼: \(system.systemCode)")
            await service.fetchCategoryInfo(systemCode: system.systemCode)
            print("🔵 載入完成，categoryInfo: \(service.categoryInfo != nil ? "有資料" : "無資料")")
            if let categoryInfo = service.categoryInfo {
                print("🔵 可用類別: \(categoryInfo.availableCategories)")
            }
        }
    }
}

// MARK: - 類別卡片

struct CategoryCard: View {
    let category: String
    let systemCode: String
    let stats: CategoryStats?
    
    var body: some View {
        VStack(spacing: 8) {
            Text(category.categoryEmoji(for: systemCode))
                .font(.largeTitle)
            
            Text(category.categoryDisplayName(for: systemCode))
                .font(.headline)
            
            if let stats = stats {
                Text("\(stats.wordCount) 詞")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("已學: \(stats.enrichedCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MultiClassificationCategoryView(
            system: ClassificationSystem(
                systemId: 1,
                systemName: "Level System",
                systemCode: "LEVEL",
                description: "傳統1-6級別分類",
                categories: ["1", "2", "3", "4", "5", "6"],
                totalWords: 6009,
                enrichedWords: 708,
                displayOrder: 1
            )
        )
    }
}