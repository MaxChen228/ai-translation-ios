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
                VStack(spacing: ModernSpacing.lg) {
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
                .padding(ModernSpacing.lg)
            }
            .navigationTitle("單字庫")
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
        VStack(spacing: ModernSpacing.md) {
            // 主要統計
            HStack(spacing: ModernSpacing.lg) {
                VocabularyStatCard(
                    title: "總單字",
                    value: "\(stats.totalWords)",
                    color: Color.modernSpecial,
                    icon: "book.fill"
                )
                
                VocabularyStatCard(
                    title: "已掌握",
                    value: "\(stats.masteredWords)",
                    color: Color.modernSuccess,
                    icon: "checkmark.circle.fill"
                )
                
                VocabularyStatCard(
                    title: "今日複習",
                    value: "\(stats.dueToday)",
                    color: Color.modernAccent,
                    icon: "clock.fill"
                )
            }
            
            // 掌握度進度條
            VStack(alignment: .leading, spacing: ModernSpacing.sm) {
                HStack {
                    Text("整體掌握度")
                        .font(.appHeadline(for: "整體掌握度"))
                        .foregroundStyle(Color.modernTextPrimary)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", stats.masteryPercentage))%")
                        .font(.appTitle2())
                        .foregroundStyle(Color.modernSuccess)
                }
                
                ProgressView(value: stats.masteryPercentage / 100.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.modernSuccess))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                HStack {
                    Label("\(stats.newWords) 新單字", systemImage: "plus.circle")
                        .font(.appCaption())
                        .foregroundStyle(Color.modernSpecial)
                    
                    Spacer()
                    
                    Label("\(stats.learningWords) 學習中", systemImage: "clock.circle")
                        .font(.appCaption())
                        .foregroundStyle(Color.modernAccent)
                }
            }
            .padding()
            .background(Color.modernSurface)
            .cornerRadius(ModernRadius.md)
        }
    }
    
    // MARK: - 今日計劃
    
    private var dailyPlanSection: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.md) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.modernAccent)
                Text("今日復習計劃")
                    .font(.appHeadline())
                                    
                Spacer()
                
                if let stats = statistics, stats.dueToday > 0 {
                    Text("\(stats.dueToday)個單字待複習")
                        .font(.appCaption())
                        .foregroundStyle(Color.modernAccent)
                        .padding(.horizontal, ModernSpacing.sm)
                        .padding(.vertical, ModernSpacing.xs)
                        .background(Color.modernAccent.opacity(0.1))
                        .cornerRadius(ModernRadius.sm)
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
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.modernAccent)
                        .cornerRadius(ModernRadius.md)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.modernSuccess)
                        Text("今日復習已完成！")
                            .foregroundStyle(Color.modernSuccess)
                        Spacer()
                    }
                    .padding()
                    .background(Color.modernSuccess.opacity(0.1))
                    .cornerRadius(ModernRadius.md)
                }
            }
        }
        .padding()
        .background(Color.modernSurface)
        .cornerRadius(ModernRadius.lg)
        .modernShadow()
    }
    
    // MARK: - 快速學習
    
    private var quickStudySection: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.md) {
            HStack {
                Image(systemName: "bolt.circle")
                    .foregroundStyle(Color.modernSpecial)
                Text("快速學習")
                    .font(.appHeadline())
                                }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: ModernSpacing.md) {
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
                            .foregroundStyle(Color.modernTextSecondary)
                        Text("單字管理")
                            .font(.appCaption())
                                                        .foregroundStyle(Color.modernTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color.modernSurface)
                    .cornerRadius(ModernRadius.md)
                }
                
                NavigationLink(destination: MultiClassificationSystemView()) {
                    VStack {
                        Image(systemName: "square.grid.3x3")
                            .font(.appTitle2())
                            .foregroundStyle(Color.modernSpecial)
                        Text("分類單字庫")
                            .font(.appCaption())
                            .foregroundStyle(Color.modernTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color.modernSurface)
                    .cornerRadius(ModernRadius.md)
                }
            }
        }
        .padding()
        .background(Color.modernSurface)
        .cornerRadius(ModernRadius.lg)
        .modernShadow()
    }
    
    // MARK: - 進度圖表
    
    private func progressSection(_ stats: VocabularyStatistics) -> some View {
        VStack(alignment: .leading, spacing: ModernSpacing.md) {
            HStack {
                Image(systemName: "chart.pie")
                    .foregroundStyle(Color.modernAccent)
                Text("學習進度分布")
                    .font(.appHeadline())
                                }
            
            // 簡化的進度圓環
            HStack(spacing: ModernSpacing.lg) {
                VStack {
                    ZStack {
                        Circle()
                            .stroke(Color.modernBorder, lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(stats.masteredWords) / max(CGFloat(stats.totalWords), 1))
                            .stroke(Color.modernSuccess, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(stats.masteredWords)")
                            .font(.appHeadline())
                                                }
                    
                    Text("已掌握")
                        .font(.appCaption())
                        .foregroundStyle(Color.modernSuccess)
                }
                
                VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                    ProgressBar(
                        title: "新單字",
                        count: stats.newWords,
                        total: stats.totalWords,
                        color: Color.modernSpecial
                    )
                    
                    ProgressBar(
                        title: "學習中",
                        count: stats.learningWords,
                        total: stats.totalWords,
                        color: Color.modernAccent
                    )
                    
                    ProgressBar(
                        title: "已掌握",
                        count: stats.masteredWords,
                        total: stats.totalWords,
                        color: Color.modernSuccess
                    )
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.modernSurface)
        .cornerRadius(ModernRadius.lg)
        .modernShadow()
    }
    
    // MARK: - 載入和錯誤狀態
    
    private var loadingSection: some View {
        VStack(spacing: ModernSpacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text("載入統計資料中...")
                .foregroundStyle(Color.modernTextSecondary)
        }
        .frame(height: 200)
    }
    
    private var errorSection: some View {
        VStack(spacing: ModernSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.appLargeTitle())
                .foregroundStyle(Color.modernAccent)
            
            Text("載入失敗")
                .font(.appHeadline())
            
            if let error = errorMessage {
                Text(error)
                    .font(.appCaption())
                    .foregroundStyle(Color.modernTextSecondary)
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

struct VocabularyStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: ModernSpacing.sm) {
            Image(systemName: icon)
                .font(.appTitle2())
                .foregroundStyle(color)
            
            Text(value)
                .font(.appTitle2())
                                .foregroundStyle(Color.modernTextPrimary)
            
            Text(title)
                .font(.appCaption())
                .foregroundStyle(Color.modernTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ModernSpacing.md)
        .background(Color.modernSurface)
        .cornerRadius(ModernRadius.md)
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
                    .foregroundStyle(Color.modernSpecial)
                
                Text(mode.displayName)
                    .font(.appCaption())
                                        .foregroundStyle(Color.modernTextPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color.modernSurface)
            .cornerRadius(ModernRadius.md)
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
                    .foregroundStyle(Color.modernTextSecondary)
                
                Spacer()
                
                Text("\(count)")
                    .font(.appCaption())
                                        .foregroundStyle(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.modernBorder.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(ModernRadius.xs)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 4)
                        .cornerRadius(ModernRadius.xs)
                }
            }
            .frame(height: 4)
        }
    }
}
