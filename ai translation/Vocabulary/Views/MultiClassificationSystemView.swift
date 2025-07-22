//
//  MultiClassificationSystemView.swift
//  ai translation
//
//  多分類系統選擇畫面
//

import SwiftUI

struct MultiClassificationSystemView: View {
    @StateObject private var service = MultiClassificationService()
    @State private var selectedSystem: ClassificationSystem?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if service.isLoading {
                        ProgressView("載入中...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    } else {
                        ForEach(service.systems) { system in
                            SystemCard(system: system)
                                .onTapGesture {
                                    selectedSystem = system
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("選擇學習方式")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .task {
                await service.fetchClassificationSystems()
            }
            .navigationDestination(item: $selectedSystem) { system in
                MultiClassificationCategoryView(system: system)
            }
            .alert("錯誤", isPresented: .constant(service.errorMessage != nil)) {
                Button("確定") {
                    service.errorMessage = nil
                }
            } message: {
                Text(service.errorMessage ?? "")
            }
        }
    }
}

// MARK: - 系統卡片

struct SystemCard: View {
    let system: ClassificationSystem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: system.iconName)
                    .font(.title2)
                    .foregroundColor(system.themeColor)
                    .frame(width: 40, height: 40)
                    .background(system.themeColor.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(system.systemName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(system.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("已學習: \(system.progressText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(system.percentageText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(system.themeColor)
                }
                
                ProgressView(value: system.enrichedPercentage / 100)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(system.themeColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    MultiClassificationSystemView()
}