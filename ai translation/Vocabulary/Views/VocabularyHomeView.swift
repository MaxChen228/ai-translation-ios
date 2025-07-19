// AI-tutor-v1.0/ai translation/📚 Vocabulary/Views/VocabularyHomeView.swift

import SwiftUI

struct VocabularyHomeView: View {
    @StateObject private var vocabularyService = VocabularyService()
    @State private var statistics: VocabularyStatistics?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingStudyModeSelection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 頂部統計卡片
                    if let stats = statistics {
                        statisticsSection(stats)
                    } else if isLoading {
                        loadingSection
                    } else {
                        errorSection
                    }
                    
                    // 今日復習計劃
                    dailyPlanSection
                    
                    // 快速學習模式選擇
                    quickStudySection
                    
                    // 進度圖表
                    if let stats = statistics {
                        progressSection(stats)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("📚 單字庫")
            .refreshable {
                await loadStatistics()
            }
        }
        .task {
            await loadStatistics()
        }
        .sheet(isPresented: $showingStudyModeSelection) {
            StudyModeSelectionView()
        }
    }
    
    // MARK: - 統計區域
    
    private func statisticsSection(_ stats: VocabularyStatistics) -> some View {
        VStack(spacing: 16) {
            // 主要統計
            HStack(spacing: 20) {
                StatCard(
                    title: "總單字",
                    value: "\(stats.totalWords)",
                    color: Color.blue,
                    icon: "book.fill"
                )
                
                StatCard(
                    title: "已掌握",
                    value: "\(stats.masteredWords)",
                    color: Color.green,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "今日複習",
                    value: "\(stats.dueToday)",
                    color: Color.orange,
                    icon: "clock.fill"
                )
            }
            
            // 掌握度進度條
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("整體掌握度")
                        .font(.appHeadline(for: "整體掌握度"))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", stats.masteryPercentage))%")
                        .font(.appTitle2())
                        .foregroundColor(.green)
                }
                
                ProgressView(value: stats.masteryPercentage / 100.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                HStack {
                    Label("\(stats.newWords) 新單字", systemImage: "plus.circle")
                        .font(.appCaption())
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Label("\(stats.learningWords) 學習中", systemImage: "clock.circle")
                        .font(.appCaption())
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 今日計劃
    
    private var dailyPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                Text("今日復習計劃")
                    .font(.appHeadline())
                                    
                Spacer()
                
                if let stats = statistics, stats.dueToday > 0 {
                    Text("\(stats.dueToday)個單字待複習")
                        .font(.appCaption())
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if let stats = statistics {
                if stats.dueToday > 0 {
                    Button(action: {
                        // 直接開始複習模式
                        showingStudyModeSelection = true
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("開始今日複習")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("🎉 今日復習已完成！")
                            .foregroundColor(.green)
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 快速學習
    
    private var quickStudySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.circle")
                    .foregroundColor(.blue)
                Text("快速學習")
                    .font(.appHeadline())
                                }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StudyModeButton(
                    mode: .review,
                    action: { showingStudyModeSelection = true }
                )
                
                StudyModeButton(
                    mode: .newLearning,
                    action: { showingStudyModeSelection = true }
                )
                
                StudyModeButton(
                    mode: .targeted,
                    action: { showingStudyModeSelection = true }
                )
                
                NavigationLink(destination: Text("單字管理")) {
                    VStack {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.appTitle2())
                            .foregroundColor(.gray)
                        Text("單字管理")
                            .font(.appCaption())
                                                        .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 進度圖表
    
    private func progressSection(_ stats: VocabularyStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie")
                    .foregroundColor(.purple)
                Text("學習進度分布")
                    .font(.appHeadline())
                                }
            
            // 簡化的進度圓環
            HStack(spacing: 20) {
                VStack {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(stats.masteredWords) / max(CGFloat(stats.totalWords), 1))
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(stats.masteredWords)")
                            .font(.appHeadline())
                                                }
                    
                    Text("已掌握")
                        .font(.appCaption())
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    ProgressBar(
                        title: "新單字",
                        count: stats.newWords,
                        total: stats.totalWords,
                        color: .blue
                    )
                    
                    ProgressBar(
                        title: "學習中",
                        count: stats.learningWords,
                        total: stats.totalWords,
                        color: .orange
                    )
                    
                    ProgressBar(
                        title: "已掌握",
                        count: stats.masteredWords,
                        total: stats.totalWords,
                        color: .green
                    )
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 載入和錯誤狀態
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("載入統計資料中...")
                .foregroundColor(.gray)
        }
        .frame(height: 200)
    }
    
    private var errorSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.appLargeTitle())
                .foregroundColor(.orange)
            
            Text("載入失敗")
                .font(.appHeadline())
            
            if let error = errorMessage {
                Text(error)
                    .font(.appCaption())
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button("重新載入") {
                Task {
                    await loadStatistics()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(height: 200)
    }
    
    // MARK: - 方法
    
    private func loadStatistics() async {
        isLoading = true
        errorMessage = nil
        
        do {
            statistics = try await vocabularyService.getStatistics()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - 輔助元件

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.appTitle2())
                .foregroundColor(color)
            
            Text(value)
                .font(.appTitle2())
                                .foregroundColor(.primary)
            
            Text(title)
                .font(.appCaption())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StudyModeButton: View {
    let mode: StudyMode
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: mode.systemImageName)
                    .font(.appTitle2())
                    .foregroundColor(.blue)
                
                Text(mode.displayName)
                    .font(.appCaption())
                                        .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct ProgressBar: View {
    let title: String
    let count: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.appCaption())
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(count)")
                    .font(.appCaption())
                                        .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
    }
}
