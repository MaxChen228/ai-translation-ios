// SessionResultsView.swift - AI 家教會話結果視圖

import SwiftUI

struct SessionResultsView: View {
    @ObservedObject var viewModel: AITutorViewModel
    let onDismiss: () -> Void
    
    @State private var animateProgress = false
    @State private var showingDetailedStats = false
    @State private var syncState: SyncState = .checking
    
    enum SyncState {
        case checking
        case syncing(Int, Int) // 已同步數量, 總數量
        case completed(Int) // 總同步數量
        case failed(String)
        case noDataToSync
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ModernSpacing.lg) {
                    // 完成慶祝區域
                    celebrationSection
                    
                    // 主要統計
                    mainStatsSection
                    
                    // 知識點同步狀態
                    knowledgePointSyncSection
                    
                    // 詳細統計
                    if showingDetailedStats {
                        detailedStatsSection
                    }
                    
                    // 底部按鈕
                    bottomButtonsSection
                    
                    Spacer()
                }
                .padding(ModernSpacing.lg)
            }
            .background(Color.modernBackground)
            .navigationTitle("學習完成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        onDismiss()
                    }
                    .font(.appSubheadline())
                }
            }
        }
        .task {
            await checkSyncStatus()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateProgress = true
            }
        }
    }
    
    // MARK: - 完成慶祝區域
    private var celebrationSection: some View {
        VStack(spacing: ModernSpacing.md) {
            // 慶祝圖示
            ZStack {
                Circle()
                    .fill(Color.modernAccent.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.appLargeTitle())
                    .foregroundStyle(Color.modernAccent)
            }
            .scaleEffect(animateProgress ? 1.1 : 0.8)
            .animation(.bouncy(duration: 0.6).delay(0.2), value: animateProgress)
            
            Text("學習完成！")
                .font(.appTitle2())
                .foregroundStyle(.primary)
                .opacity(animateProgress ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.4), value: animateProgress)
            
            Text(motivationalMessage)
                .font(.appBody())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(animateProgress ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.6), value: animateProgress)
        }
        .padding(.vertical, ModernSpacing.lg)
    }
    
    // MARK: - 主要統計
    private var mainStatsSection: some View {
        VStack(spacing: ModernSpacing.md) {
            HStack {
                Text("學習統計")
                    .font(.appTitle3())
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingDetailedStats.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showingDetailedStats ? "收起" : "詳細")
                            .font(.appCaption())
                        Image(systemName: showingDetailedStats ? "chevron.up" : "chevron.down")
                            .font(.appCaption())
                    }
                    .foregroundStyle(Color.modernAccent)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: ModernSpacing.md) {
                SessionStatCard(
                    title: "總題數",
                    value: "\(viewModel.sessionStats.totalAnswered)",
                    icon: "questionmark.circle",
                    color: .blue
                )
                
                SessionStatCard(
                    title: "正確率",
                    value: "\(Int(viewModel.sessionStats.accuracy))%",
                    icon: "target",
                    color: .green
                )
                
                SessionStatCard(
                    title: "學習時間",
                    value: viewModel.sessionProgress.formattedDuration,
                    icon: "clock",
                    color: .orange
                )
                
                SessionStatCard(
                    title: "平均分數",
                    value: String(format: "%.1f", viewModel.sessionStats.averageScore * 100),
                    icon: "star.fill",
                    color: .yellow
                )
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .modernShadow()
        }
    }
    
    // MARK: - 知識點同步區域
    private var knowledgePointSyncSection: some View {
        VStack(spacing: ModernSpacing.md) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.appTitle3())
                    .foregroundStyle(Color.modernAccent)
                
                Text("知識點同步")
                    .font(.appTitle3())
                    .foregroundStyle(.primary)
                
                Spacer()
                
                syncStatusIcon
            }
            
            syncStatusContent
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .modernShadow()
        }
    }
    
    // MARK: - 同步狀態圖示
    @ViewBuilder
    private var syncStatusIcon: some View {
        switch syncState {
        case .checking:
            ProgressView()
                .scaleEffect(0.8)
        case .syncing:
            ProgressView()
                .scaleEffect(0.8)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        case .noDataToSync:
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
        }
    }
    
    // MARK: - 同步狀態內容
    @ViewBuilder
    private var syncStatusContent: some View {
        switch syncState {
        case .checking:
            HStack {
                Text("檢查知識點...")
                    .font(.appBody())
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
        case .syncing(let synced, let total):
            VStack(alignment: .leading, spacing: ModernSpacing.sm) {
                HStack {
                    Text("同步中 \(synced)/\(total)")
                        .font(.appBody())
                        .foregroundStyle(.primary)
                    Spacer()
                }
                
                ProgressView(value: Double(synced), total: Double(total))
                    .progressViewStyle(.linear)
                    .tint(Color.modernAccent)
            }
            
        case .completed(let count):
            VStack(alignment: .leading, spacing: ModernSpacing.sm) {
                HStack {
                    Text("同步完成")
                        .font(.appBody())
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(count) 個知識點")
                        .font(.appCaption())
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.appCaption())
                    Text("所有錯誤分析已儲存到知識庫")
                        .font(.appCaption())
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            
        case .failed(let error):
            VStack(alignment: .leading, spacing: ModernSpacing.sm) {
                HStack {
                    Text("同步失敗")
                        .font(.appBody())
                        .foregroundStyle(.red)
                    Spacer()
                    Button("重試") {
                        Task {
                            await retrySyncKnowledgePoints()
                        }
                    }
                    .font(.appCaption())
                    .foregroundStyle(Color.modernAccent)
                }
                
                Text(error)
                    .font(.appCaption())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
        case .noDataToSync:
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.appCaption())
                Text("本次學習沒有錯誤需要記錄")
                    .font(.appBody())
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
    
    // MARK: - 詳細統計
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.md) {
            Text("詳細數據")
                .font(.appTitle3())
                .foregroundStyle(.primary)
            
            VStack(spacing: ModernSpacing.sm) {
                DetailStatRow(label: "正確答案", value: "\(viewModel.sessionStats.correctAnswers)")
                DetailStatRow(label: "跳過題目", value: "\(viewModel.sessionStats.skippedQuestions)")
                DetailStatRow(label: "完成率", value: "\(Int(viewModel.sessionStats.completionRate))%")
                DetailStatRow(label: "開始時間", value: formatTime(viewModel.sessionProgress.startedAt))
                DetailStatRow(label: "結束時間", value: formatTime(viewModel.sessionProgress.completedAt ?? Date()))
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .modernShadow()
        }
    }
    
    // MARK: - 底部按鈕
    private var bottomButtonsSection: some View {
        VStack(spacing: ModernSpacing.md) {
            // 查看知識點按鈕
            if case .completed(let count) = syncState, count > 0 {
                Button {
                    // TODO: 導航到知識點頁面
                    onDismiss()
                } label: {
                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("查看新增的知識點")
                    }
                    .font(.appSubheadline())
                    .foregroundStyle(Color.modernAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ModernSpacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: ModernRadius.md)
                            .fill(Color.modernAccent.opacity(0.1))
                            .overlay {
                                RoundedRectangle(cornerRadius: ModernRadius.md)
                                    .stroke(Color.modernAccent, lineWidth: 1)
                            }
                    }
                }
            }
            
            // 再次練習按鈕
            Button {
                onDismiss()
                Task {
                    await viewModel.startNewSession()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("再次練習")
                }
                .font(.appSubheadline())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ModernSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: ModernRadius.md)
                        .fill(Color.modernAccent)
                }
            }
        }
    }
    
    // MARK: - 計算屬性
    private var motivationalMessage: String {
        let accuracy = viewModel.sessionStats.accuracy
        if accuracy >= 90 {
            return "太棒了！你的表現非常出色！"
        } else if accuracy >= 70 {
            return "很不錯！繼續保持這個節奏！"
        } else if accuracy >= 50 {
            return "持續練習，你會越來越好！"
        } else {
            return "每一次練習都是進步的機會！"
        }
    }
    
    // MARK: - 方法
    private func checkSyncStatus() async {
        syncState = .checking
        
        let unsyncedCount = viewModel.getUnsyncedKnowledgePointsCount()
        
        if unsyncedCount == 0 {
            syncState = .noDataToSync
            return
        }
        
        // 模擬同步過程
        syncState = .syncing(0, unsyncedCount)
        
        do {
            // 這裡應該監聽實際的同步進度
            // 現在先模擬逐步同步
            for i in 1...unsyncedCount {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 秒
                syncState = .syncing(i, unsyncedCount)
            }
            
            syncState = .completed(unsyncedCount)
        } catch {
            syncState = .failed(error.localizedDescription)
        }
    }
    
    private func retrySyncKnowledgePoints() async {
        let success = await viewModel.manualSyncKnowledgePoints()
        if success {
            syncState = .completed(viewModel.getUnsyncedKnowledgePointsCount())
        } else {
            syncState = .failed("重試失敗，請檢查網路連線")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 支援視圖

struct SessionStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: ModernSpacing.sm) {
            Image(systemName: icon)
                .font(.appTitle3())
                .foregroundStyle(color)
            
            Text(value)
                .font(.appTitle2())
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.appCaption())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.md)
                .fill(Color.modernBackground)
        }
    }
}

struct DetailStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.appBody())
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.appBody())
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - 預覽
#Preview {
    SessionResultsView(
        viewModel: {
            let vm = AITutorViewModel()
            vm.sessionStats.totalAnswered = 10
            vm.sessionStats.correctAnswers = 8
            vm.sessionStats.averageScore = 0.85
            return vm
        }(),
        onDismiss: {}
    )
}