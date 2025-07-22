// AI-tutor-v1.0/ai translation/📚 Vocabulary/Views/StudySummaryView.swift

import SwiftUI

struct StudySummaryView: View {
    let summary: StudySummary
    let onDismiss: () -> Void
    
    @State private var showingDetailedStats = false
    @State private var animateProgress = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ModernSpacing.lg) {
                    // 頂部成就區域
                    achievementSection
                    
                    // 主要統計
                    mainStatsSection
                    
                    // 詳細統計
                    if showingDetailedStats {
                        detailedStatsSection
                    }
                    
                    // 單字列表
                    wordsListSection
                    
                    // 新掌握單字
                    if !summary.newMasteryAchievements.isEmpty {
                        newMasterySection
                    }
                    
                    // 底部按鈕
                    bottomButtonsSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("學習總結")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        onDismiss()
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                animateProgress = true
            }
        }
    }
    
    // MARK: - 簡約總結區域
    
    private var achievementSection: some View {
        VStack(spacing: ModernSpacing.md) {
            // 簡化的結果指示器
            ZStack {
                Circle()
                    .fill(Color.modernSurface)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Circle()
                            .stroke(achievementColor, lineWidth: 3)
                    }
                
                Image(systemName: achievementIcon)
                    .font(.appTitle2())
                    .foregroundStyle(achievementColor)
            }
            
            // 簡化標題
            Text(achievementTitle)
                .font(.appTitle2())
                .foregroundStyle(Color.modernTextPrimary)
                .multilineTextAlignment(.center)
            
            // 簡化描述
            Text(achievementDescription)
                .font(.appSubheadline())
                .foregroundStyle(Color.modernTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.modernSurface)
        .cornerRadius(ModernRadius.md)
    }
    
    // MARK: - 主要統計
    
    private var mainStatsSection: some View {
        VStack(spacing: ModernSpacing.md) {
            HStack {
                Text("學習成果")
                    .font(.appHeadline())
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(showingDetailedStats ? "收起" : "查看詳細") {
                    withAnimation(.easeInOut) {
                        showingDetailedStats.toggle()
                    }
                }
                .font(.appCaption())
                .foregroundStyle(Color.modernAccent)
            }
            
            // 進度圓環
            HStack(spacing: ModernSpacing.xl) {
                // 正確率圓環
                VStack(spacing: ModernSpacing.sm) {
                    ZStack {
                        Circle()
                            .stroke(Color.modernTextTertiary.opacity(0.3), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: animateProgress ? CGFloat(summary.accuracyRate / 100) : 0)
                            .stroke(accuracyColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.5).delay(0.3), value: animateProgress)
                        
                        Text("\(safeIntFromDouble(summary.accuracyRate))%")
                            .font(.appHeadline())
                            .fontWeight(.bold)
                            .foregroundStyle(accuracyColor)
                    }
                    
                    Text("正確率")
                        .font(.appCaption())
                        .foregroundStyle(Color.modernTextSecondary)
                }
                
                // 統計數字
                VStack(alignment: .leading, spacing: ModernSpacing.md) {
                    StatRow(
                        icon: "checkmark.circle.fill",
                        label: "答對題數",
                        value: "\(summary.correctAnswers)/\(summary.totalQuestions)",
                        color: Color.modernSuccess
                    )
                    
                    StatRow(
                        icon: "clock.fill",
                        label: "學習時間",
                        value: formatTime(summary.studyTime),
                        color: Color.modernAccent
                    )
                    
                    StatRow(
                        icon: "book.fill",
                        label: "學習單字",
                        value: "\(summary.wordsStudied.count)",
                        color: Color.modernSpecial
                    )
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.modernSurface)
        .cornerRadius(ModernRadius.md)
        .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
    }
    
    // MARK: - 詳細統計
    
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("詳細分析")
                .font(.appHeadline())
                .fontWeight(.semibold)
            
            VStack(spacing: ModernSpacing.md) {
                DetailedStatRow(
                    title: "平均回答時間",
                    value: "\(safeAverageTime)秒/題",
                    progress: safeTimeProgress,
                    color: Color.modernSuccess
                )
                
                DetailedStatRow(
                    title: "學習效率",
                    value: efficiency,
                    progress: safeAccuracyProgress,
                    color: Color.modernSuccess
                )
                
                if !summary.newMasteryAchievements.isEmpty {
                    DetailedStatRow(
                        title: "新掌握單字",
                        value: "\(summary.newMasteryAchievements.count)個",
                        progress: safeMasteryProgress,
                        color: Color.modernAccent
                    )
                }
            }
        }
        .padding()
        .background(Color.modernSurface)
        .cornerRadius(ModernRadius.md)
        .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
    }
    
    // MARK: - 單字列表
    
    private var wordsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("學習的單字")
                    .font(.appHeadline())
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("共 \(summary.wordsStudied.count) 個")
                    .font(.appCaption())
                    .foregroundStyle(Color.modernTextSecondary)
            }
            
            LazyVStack(spacing: ModernSpacing.sm) {
                ForEach(Array(summary.wordsStudied.enumerated()), id: \.offset) { index, word in
                    WordSummaryRow(word: word, index: index)
                        .opacity(animateProgress ? 1.0 : 0.0)
                        .offset(y: animateProgress ? 0 : 20)
                        .animation(
                            .easeOut(duration: 0.4)
                            .delay(Double(index) * 0.1),
                            value: animateProgress
                        )
                }
            }
        }
        .padding()
        .background(Color.modernSurface)
        .cornerRadius(ModernRadius.md)
        .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
    }
    
    // MARK: - 新掌握單字
    
    private var newMasterySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("新掌握單字")
                .font(.appHeadline())
                .fontWeight(.semibold)
                .foregroundStyle(Color.modernTextPrimary)
            
            LazyVStack(spacing: ModernSpacing.sm) {
                ForEach(summary.newMasteryAchievements, id: \.id) { word in
                    HStack {
                        VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                            Text(word.word)
                                .font(.appHeadline())
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.modernTextPrimary)
                            
                            Text(word.definitionZH)
                                .font(.appCaption())
                                .foregroundStyle(Color.modernTextSecondary)
                        }
                        
                        Spacer()
                        
                        Text("掌握")
                            .font(.appCaption())
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, ModernSpacing.sm)
                            .padding(.vertical, ModernSpacing.xs)
                            .background(Color.modernSuccess)
                            .cornerRadius(ModernRadius.sm)
                    }
                    .padding()
                    .background(Color.modernSurface)
                    .cornerRadius(ModernRadius.sm)
                }
            }
        }
        .padding()
        .background(Color.modernSurface)
        .cornerRadius(ModernRadius.md)
        .shadow(color: ModernShadow.soft.color, radius: ModernShadow.soft.radius, x: ModernShadow.soft.x, y: ModernShadow.soft.y)
    }
    
    // MARK: - 底部按鈕
    
    private var bottomButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                // 繼續學習
                onDismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("繼續學習")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.modernAccent)
                .cornerRadius(ModernRadius.md)
            }
            
            Button(action: {
                // 查看單字庫
                onDismiss()
            }) {
                HStack {
                    Image(systemName: "book.circle")
                    Text("查看單字庫")
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.modernAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.modernAccent.opacity(0.1))
                .cornerRadius(ModernRadius.md)
            }
        }
    }
    
    // MARK: - 計算屬性
    
    private var achievementColor: Color {
        if summary.accuracyRate >= 90 { return Color.modernSuccess }
        else if summary.accuracyRate >= 70 { return Color.modernWarning }
        else { return Color.modernAccent }
    }
    
    private var achievementIcon: String {
        if summary.accuracyRate >= 90 { return "star.fill" }
        else if summary.accuracyRate >= 70 { return "hand.thumbsup.fill" }
        else { return "book.fill" }
    }
    
    private var achievementTitle: String {
        if summary.accuracyRate >= 90 { return "優秀表現！" }
        else if summary.accuracyRate >= 70 { return "表現良好！" }
        else { return "繼續努力！" }
    }
    
    private var achievementDescription: String {
        if summary.accuracyRate >= 90 {
            return "你的正確率超過90%，表現非常出色！"
        } else if summary.accuracyRate >= 70 {
            return "你的正確率達到70%以上，學習效果不錯！"
        } else {
            return "繼續練習，你會越來越進步的！"
        }
    }
    
    private var accuracyColor: Color {
        if summary.accuracyRate >= 80 { return Color.modernSuccess }
        else if summary.accuracyRate >= 60 { return Color.modernWarning }
        else { return Color.modernError }
    }
    
    private var efficiency: String {
        guard summary.studyTime > 0 else { return "無數據" }
        let wordsPerMinute = Double(summary.correctAnswers) / (summary.studyTime / 60.0)
        if wordsPerMinute.isNaN || wordsPerMinute.isInfinite { return "無數據" }
        if wordsPerMinute >= 2.0 { return "高效" }
        else if wordsPerMinute >= 1.0 { return "良好" }
        else { return "需加強" }
    }
    
    // MARK: - 安全計算方法
    
    private func safeIntFromDouble(_ value: Double) -> Int {
        if value.isNaN || value.isInfinite {
            return 0
        }
        return max(0, min(100, Int(value.rounded())))
    }
    
    private var safeAverageTime: String {
        guard summary.totalQuestions > 0, summary.studyTime > 0 else { return "0.0" }
        let average = summary.studyTime / Double(summary.totalQuestions)
        if average.isNaN || average.isInfinite {
            return "0.0"
        }
        return String(format: "%.1f", average)
    }
    
    private var safeTimeProgress: Double {
        guard summary.totalQuestions > 0, summary.studyTime > 0 else { return 0.0 }
        let average = summary.studyTime / Double(summary.totalQuestions)
        if average.isNaN || average.isInfinite {
            return 0.0
        }
        return min(average / 30.0, 1.0) // 假設30秒為滿分
    }
    
    private var safeAccuracyProgress: Double {
        if summary.accuracyRate.isNaN || summary.accuracyRate.isInfinite {
            return 0.0
        }
        return max(0.0, min(1.0, summary.accuracyRate / 100.0))
    }
    
    private var safeMasteryProgress: Double {
        guard summary.totalQuestions > 0 else { return 0.0 }
        let progress = Double(summary.newMasteryAchievements.count) / Double(summary.totalQuestions)
        if progress.isNaN || progress.isInfinite {
            return 0.0
        }
        return max(0.0, min(1.0, progress))
    }
    
    // MARK: - 輔助方法
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d分%02d秒", minutes, seconds)
    }
}

// MARK: - 輔助元件

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: ModernSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 16)
            
            Text(label)
                .font(.appCaption())
                .foregroundStyle(Color.modernTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.appCaption())
                .fontWeight(.semibold)
                .foregroundStyle(Color.modernTextPrimary)
        }
    }
}

struct DetailedStatRow: View {
    let title: String
    let value: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.sm) {
            HStack {
                Text(title)
                    .font(.appSubheadline())
                    .foregroundStyle(Color.modernTextPrimary)
                
                Spacer()
                
                Text(value)
                    .font(.appSubheadline())
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.modernTextTertiary.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(ModernRadius.xs)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(ModernRadius.xs)
                }
            }
            .frame(height: 4)
        }
    }
}

struct WordSummaryRow: View {
    let word: VocabularyWord
    let index: Int
    
    var body: some View {
        HStack(spacing: ModernSpacing.md) {
            // 序號
            Text("\(index + 1)")
                .font(.appCaption())
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color.modernAccent)
                .clipShape(Circle())
            
            // 單字資訊
            VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                Text(word.word)
                    .font(.appSubheadline())
                    .fontWeight(.semibold)
                
                Text(word.definitionZH)
                    .font(.appCaption())
                    .foregroundStyle(Color.modernTextSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 掌握度指示器
            HStack(spacing: ModernSpacing.xs) {
                Image(systemName: masteryIcon(for: word.masteryLevel))
                    .font(.appCaption())
                    .foregroundStyle(masteryColor(for: word.masteryLevel))
                
                Text(String(format: "%.1f", word.masteryLevel))
                    .font(.appCaption())
                    .fontWeight(.medium)
                    .foregroundStyle(masteryColor(for: word.masteryLevel))
            }
        }
        .padding(.vertical, ModernSpacing.sm)
        .padding(.horizontal, ModernSpacing.md)
        .background(Color.modernSurface.opacity(0.7))
        .cornerRadius(ModernRadius.sm)
    }
    
    private func masteryIcon(for level: Double) -> String {
        if level >= 4.0 { return "checkmark.circle.fill" }
        else if level >= 2.0 { return "clock.circle.fill" }
        else { return "plus.circle.fill" }
    }
    
    private func masteryColor(for level: Double) -> Color {
        if level >= 4.0 { return Color.modernSuccess }
        else if level >= 2.0 { return Color.modernWarning }
        else { return Color.modernAccent }
    }
}
