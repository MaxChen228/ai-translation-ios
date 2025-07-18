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
                VStack(spacing: 24) {
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
                    
                    // 成就獎章
                    if !summary.newMasteryAchievements.isEmpty {
                        masteryAchievementsSection
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
    
    // MARK: - 成就區域
    
    private var achievementSection: some View {
        VStack(spacing: 16) {
            // 主要成就圖示
            ZStack {
                Circle()
                    .fill(achievementColor)
                    .frame(width: 100, height: 100)
                    .shadow(color: achievementColor.opacity(0.3), radius: 10)
                
                Image(systemName: achievementIcon)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(animateProgress ? 1.0 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateProgress)
            
            // 成就標題
            Text(achievementTitle)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // 成就描述
            Text(achievementDescription)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
    
    // MARK: - 主要統計
    
    private var mainStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("學習成果")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(showingDetailedStats ? "收起" : "查看詳細") {
                    withAnimation(.easeInOut) {
                        showingDetailedStats.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // 進度圓環
            HStack(spacing: 30) {
                // 正確率圓環
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: animateProgress ? CGFloat(summary.accuracyRate / 100) : 0)
                            .stroke(accuracyColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.5).delay(0.3), value: animateProgress)
                        
                        Text("\(Int(summary.accuracyRate))%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(accuracyColor)
                    }
                    
                    Text("正確率")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // 統計數字
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(
                        icon: "checkmark.circle.fill",
                        label: "答對題數",
                        value: "\(summary.correctAnswers)/\(summary.totalQuestions)",
                        color: .green
                    )
                    
                    StatRow(
                        icon: "clock.fill",
                        label: "學習時間",
                        value: formatTime(summary.studyTime),
                        color: .blue
                    )
                    
                    StatRow(
                        icon: "book.fill",
                        label: "學習單字",
                        value: "\(summary.wordsStudied.count)",
                        color: .purple
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
    
    // MARK: - 詳細統計
    
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("詳細分析")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DetailedStatRow(
                    title: "平均回答時間",
                    value: "\(String(format: "%.1f", summary.studyTime / Double(summary.totalQuestions)))秒/題",
                    progress: min(summary.studyTime / Double(summary.totalQuestions) / 30.0, 1.0), // 假設30秒為滿分
                    color: .orange
                )
                
                DetailedStatRow(
                    title: "學習效率",
                    value: efficiency,
                    progress: summary.accuracyRate / 100.0,
                    color: .green
                )
                
                if !summary.newMasteryAchievements.isEmpty {
                    DetailedStatRow(
                        title: "新掌握單字",
                        value: "\(summary.newMasteryAchievements.count)個",
                        progress: Double(summary.newMasteryAchievements.count) / Double(summary.totalQuestions),
                        color: .blue
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 單字列表
    
    private var wordsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("學習的單字")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("共 \(summary.wordsStudied.count) 個")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            LazyVStack(spacing: 8) {
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
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 掌握成就
    
    private var masteryAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.orange)
                
                Text("新掌握成就")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text("恭喜！你在這次學習中掌握了以下單字：")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            LazyVStack(spacing: 8) {
                ForEach(summary.newMasteryAchievements, id: \.id) { word in
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(word.word)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(word.definitionZH)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("已掌握")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.blue)
                .cornerRadius(16)
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
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 計算屬性
    
    private var achievementColor: Color {
        if summary.accuracyRate >= 90 { return .green }
        else if summary.accuracyRate >= 70 { return .orange }
        else { return .blue }
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
        if summary.accuracyRate >= 80 { return .green }
        else if summary.accuracyRate >= 60 { return .orange }
        else { return .red }
    }
    
    private var efficiency: String {
        let wordsPerMinute = Double(summary.correctAnswers) / (summary.studyTime / 60.0)
        if wordsPerMinute >= 2.0 { return "高效" }
        else if wordsPerMinute >= 1.0 { return "良好" }
        else { return "需加強" }
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
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

struct DetailedStatRow: View {
    let title: String
    let value: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
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
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
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
        HStack(spacing: 12) {
            // 序號
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            // 單字資訊
            VStack(alignment: .leading, spacing: 2) {
                Text(word.word)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(word.definitionZH)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 掌握度指示器
            HStack(spacing: 4) {
                Image(systemName: masteryIcon(for: word.masteryLevel))
                    .font(.caption)
                    .foregroundColor(masteryColor(for: word.masteryLevel))
                
                Text(String(format: "%.1f", word.masteryLevel))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(masteryColor(for: word.masteryLevel))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func masteryIcon(for level: Double) -> String {
        if level >= 4.0 { return "checkmark.circle.fill" }
        else if level >= 2.0 { return "clock.circle.fill" }
        else { return "plus.circle.fill" }
    }
    
    private func masteryColor(for level: Double) -> Color {
        if level >= 4.0 { return .green }
        else if level >= 2.0 { return .orange }
        else { return .blue }
    }
}
