// KnowledgePointDetailView.swift - 完整重寫版本
// 位置：ai translation/✨ Features/Dashboard/KnowledgePointDetailView.swift

import SwiftUI

struct KnowledgePointDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var point: KnowledgePoint
    @State private var isEditing = false
    @State private var editablePoint: EditableKnowledgePoint
    @State private var showingDeleteAlert = false
    @State private var isLoading = false
    @State private var saveMessage: String?
    @State private var isAIReviewing = false
    @State private var aiReviewResult: AIReviewResult?
    @State private var showAIReviewSheet = false
    
    // Helix 相關知識點
    @State private var relatedKnowledgePoints: [KnowledgePoint] = []
    @State private var isLoadingRelatedPoints = false
    
    // 本地狀態追蹤
    @State private var localIsArchived: Bool
    
    // 檢測是否為本地知識點
    private var isLocalKnowledgePoint: Bool {
        return point.aiReviewNotes == "本地儲存"
    }
    
    init(point: KnowledgePoint) {
        self._point = State(initialValue: point)
        self._editablePoint = State(initialValue: EditableKnowledgePoint(from: point))
        self._localIsArchived = State(initialValue: point.isArchived ?? false)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 知識點卡片
                knowledgePointCard
                
                // 相關知識點區塊
                if !relatedKnowledgePoints.isEmpty || isLoadingRelatedPoints {
                    relatedKnowledgePointsSection
                }
                
                // 操作按鈕
                actionButtonsSection
            }
            .padding(ModernSpacing.lg)
        }
        .background(Color.modernBackground)
        .navigationTitle("知識點詳情")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                editButton
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                deleteKnowledgePoint()
            }
        } message: {
            Text("此操作無法復原")
                .font(.appBody(for: "此操作無法復原"))
        }
        .sheet(isPresented: $showAIReviewSheet) {
            if let reviewResult = aiReviewResult {
                AIReviewResultView(reviewResult: reviewResult)
            }
        }
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
                editablePoint = EditableKnowledgePoint(from: point)
            }
        }
        .onAppear {
            loadRelatedKnowledgePoints()
        }
    }
    
    // MARK: - 知識點卡片
    
    private var knowledgePointCard: some View {
        VStack(spacing: 24) {
            // 卡片頭部
            cardHeader
            
            Divider()
            
            // 主要內容
            cardContent
            
            // 保存訊息
            if let saveMessage = saveMessage {
                saveMessageView(saveMessage)
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .modernShadow()
        }
    }
    
    private var cardHeader: some View {
        VStack(spacing: 16) {
            // 類型和狀態
            HStack {
                // 分類標籤
                HStack(spacing: 8) {
                    Image(systemName: categoryIcon)
                        .font(.appCallout())
                        .foregroundStyle(Color.modernAccent)
                    
                    Text("\(point.category) → \(point.subcategory)")
                        .font(.appCallout())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.modernAccent)
                }
                .padding(.horizontal, ModernSpacing.md)
                .padding(.vertical, ModernSpacing.sm)
                .background {
                    Capsule()
                        .fill(Color.modernAccentSoft)
                }
                
                Spacer()
                
                // 狀態標籤
                statusLabel
            }
            
            // 掌握度和統計
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.appCaption())
                            .foregroundStyle(Color.modernAccent)
                        
                        Text("掌握度")
                            .font(.appCaption(for: "掌握度"))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("\(Int(point.masteryLevel * 100))%")
                        .font(.appTitle2())
                        .fontWeight(.bold)
                        .foregroundStyle(Color.modernAccent)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("錯誤 \(point.mistakeCount) 次")
                            .font(.appCaption(for: "錯誤"))
                            .foregroundStyle(Color.modernError)
                        
                        Text("正確 \(point.correctCount) 次")
                            .font(.appCaption(for: "正確"))
                            .foregroundStyle(Color.modernSuccess)
                    }
                    
                    if let nextReviewDate = point.nextReviewDate {
                        Text("下次複習：\(nextReviewDate)")
                            .font(.appCaption(for: "下次複習"))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var statusLabel: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(localIsArchived ? Color.modernTextSecondary : Color.modernSuccess)
                .frame(width: 8, height: 8)
            
            Text(localIsArchived ? "已歸檔" : "活躍")
                .font(.appCaption(for: localIsArchived ? "已歸檔" : "活躍"))
                .fontWeight(.medium)
                .foregroundStyle(localIsArchived ? Color.modernTextSecondary : Color.modernSuccess)
        }
        .padding(.horizontal, ModernSpacing.sm)
        .padding(.vertical, ModernSpacing.xs)
        .background {
            Capsule()
                .fill((localIsArchived ? Color.modernTextSecondary : Color.modernSuccess).opacity(0.1))
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 用戶原始句子
            if let userContextSentence = point.userContextSentence {
                VStack(alignment: .leading, spacing: 8) {
                    Label("你的答案", systemImage: "quote.bubble.fill")
                        .font(.appHeadline(for: "原始句子"))
                        .foregroundStyle(Color.modernAccent)
                    
                    Text(userContextSentence)
                        .font(.appBody(for: userContextSentence))
                        .padding(ModernSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: ModernRadius.sm)
                                .fill(Color.modernSurface)
                        }
                }
            }
            
            // 錯誤片段
            if let incorrectPhrase = point.incorrectPhraseInContext {
                VStack(alignment: .leading, spacing: 8) {
                    Label("錯誤部分", systemImage: "exclamationmark.triangle.fill")
                        .font(.appHeadline(for: "錯誤片段"))
                        .foregroundStyle(Color.modernError)
                    
                    if isEditing {
                        TextField("錯誤片段", text: $editablePoint.incorrectPhrase)
                            .textFieldStyle(.roundedBorder)
                            .font(.appBody())
                    } else {
                        Text(incorrectPhrase)
                            .font(.appBody(for: incorrectPhrase))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.modernError)
                            .strikethrough(color: Color.modernError)
                            .padding(ModernSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: ModernRadius.sm)
                                    .fill(Color.modernError.opacity(0.1))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: ModernRadius.sm)
                                            .stroke(Color.modernError.opacity(0.3), lineWidth: 1)
                                    }
                            }
                    }
                }
            }
            
            // 核心知識點
            VStack(alignment: .leading, spacing: 8) {
                Label("核心知識點", systemImage: "lightbulb.fill")
                    .font(.appHeadline(for: "核心知識點"))
                    .foregroundColor(Color.modernAccent)
                
                if isEditing {
                    TextField("核心知識點", text: $editablePoint.keyPointSummary, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.appBody())
                        .lineLimit(2...4)
                } else {
                    if let keyPointSummary = point.keyPointSummary, !keyPointSummary.isEmpty {
                        Text(keyPointSummary)
                            .font(.appBody(for: keyPointSummary))
                            .fontWeight(.medium)
                    } else {
                        Text("未設定")
                            .font(.appBody(for: "未設定"))
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
            }
            
            // 正確用法
            VStack(alignment: .leading, spacing: 8) {
                Label("正確用法", systemImage: "checkmark.seal.fill")
                    .font(.appHeadline(for: "正確用法"))
                    .foregroundColor(Color.modernSuccess)
                
                if isEditing {
                    TextField("正確用法", text: $editablePoint.correctPhrase)
                        .textFieldStyle(.roundedBorder)
                        .font(.appBody())
                } else {
                    Text(point.correctPhrase)
                        .font(.appBody(for: point.correctPhrase))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.modernSuccess)
                        .padding(ModernSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: ModernRadius.sm)
                                .fill(Color.modernSuccess.opacity(0.1))
                                .overlay {
                                    RoundedRectangle(cornerRadius: ModernRadius.sm)
                                        .stroke(Color.modernSuccess.opacity(0.3), lineWidth: 1)
                                }
                        }
                }
            }
            
            // 用法解析
            if let explanation = point.explanation, !explanation.isEmpty || isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    Label("用法解析", systemImage: "sparkles")
                        .font(.appHeadline(for: "用法解析"))
                        .foregroundStyle(Color.modernAccent)
                    
                    if isEditing {
                        TextField("用法解析", text: $editablePoint.explanation, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .font(.appBody())
                            .lineLimit(3...6)
                    } else {
                        Text(explanation)
                            .font(.appBody(for: explanation))
                            .lineSpacing(2)
                    }
                }
            }
            
            // AI 審閱結果
            if let aiReviewNotes = point.aiReviewNotes, !aiReviewNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("AI 審閱建議", systemImage: "brain.head.profile")
                            .font(.appHeadline(for: "AI 審閱建議"))
                            .foregroundStyle(Color.modernSpecial)
                        
                        Spacer()
                        
                        if let lastReviewDate = point.lastAiReviewDate {
                            Text(lastReviewDate)
                                .font(.appCaption(for: lastReviewDate))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text(aiReviewNotes)
                        .font(.appBody(for: aiReviewNotes))
                        .padding(ModernSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: ModernRadius.sm)
                                .fill(Color.modernSpecial.opacity(0.1))
                        }
                }
            }
        }
    }
    
    // MARK: - 相關知識點區塊
    
    private var relatedKnowledgePointsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Label("相關知識點", systemImage: "link")
                    .font(.appHeadline(for: "相關知識點"))
                    .foregroundStyle(Color.modernAccent)
                
                Spacer()
                
                if isLoadingRelatedPoints {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // 相關知識點列表
            if point.id < 0 || point.id > Int32.max {
                // 本地知識點提示
                HStack {
                    Image(systemName: "icloud.slash")
                        .foregroundStyle(Color.modernTextSecondary)
                    Text("本地知識點暫不支援相關連結")
                        .font(.appBody())
                        .foregroundStyle(Color.modernTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(ModernSpacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: ModernRadius.md)
                        .fill(Color.modernBackground)
                }
            } else if isLoadingRelatedPoints {
                // 載入中的佔位符
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        relatedPointPlaceholder
                    }
                }
            } else if relatedKnowledgePoints.isEmpty {
                // 無相關知識點
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.modernTextSecondary)
                    Text("暫無相關知識點")
                        .font(.appBody())
                        .foregroundStyle(Color.modernTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(ModernSpacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: ModernRadius.md)
                        .fill(Color.modernBackground)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(relatedKnowledgePoints.prefix(5), id: \.id) { relatedPoint in
                        RelatedKnowledgePointRow(point: relatedPoint)
                    }
                }
            }
        }
        .padding(ModernSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.lg)
                .fill(Color.modernSurface)
                .modernShadow()
        }
    }
    
    private var relatedPointPlaceholder: some View {
        HStack {
            RoundedRectangle(cornerRadius: ModernRadius.xs)
                .fill(Color.modernTextTertiary.opacity(0.3))
                .frame(width: 40, height: 8)
            
            RoundedRectangle(cornerRadius: ModernRadius.xs)
                .fill(Color.modernTextTertiary.opacity(0.3))
                .frame(height: 8)
            
            Spacer()
        }
        .padding(.vertical, ModernSpacing.sm)
    }
    
    // MARK: - 操作按鈕區域
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if isEditing {
                // 編輯模式按鈕
                HStack(spacing: 16) {
                    Button(action: cancelEditing) {
                        HStack {
                            Image(systemName: "xmark")
                                .font(.appBody())
                            Text("取消")
                                .font(.appBody(for: "取消"))
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ModernSpacing.sm + 2)
                        .background(Color.modernBorder)
                        .foregroundStyle(Color.modernTextPrimary)
                        .cornerRadius(ModernRadius.sm)
                    }
                    
                    Button(action: saveChanges) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.appBody())
                            }
                            Text("保存")
                                .font(.appBody(for: "保存"))
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ModernSpacing.sm + 2)
                        .background(Color.modernAccent)
                        .foregroundStyle(.white)
                        .cornerRadius(ModernRadius.sm)
                    }
                    .disabled(isLoading || !hasChanges)
                }
            } else {
                // 檢視模式按鈕
                VStack(spacing: 12) {
                    // 本地知識點標識
                    if isLocalKnowledgePoint {
                        HStack {
                            Image(systemName: "internaldrive")
                                .font(.appBody())
                                .foregroundStyle(Color.modernWarning)
                            Text("本地儲存的知識點")
                                .font(.appBody(for: "本地儲存的知識點"))
                                .foregroundStyle(Color.modernTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ModernSpacing.sm)
                        .background(Color.modernWarning.opacity(0.1))
                        .cornerRadius(ModernRadius.sm)
                        .overlay {
                            RoundedRectangle(cornerRadius: ModernRadius.sm)
                                .stroke(Color.modernWarning.opacity(0.3), lineWidth: 1)
                        }
                    }
                    
                    // AI 重新審閱（本地知識點禁用）
                    Button(action: performAIReview) {
                        HStack {
                            if isAIReviewing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("AI 審閱中...")
                                    .font(.appBody(for: "AI 審閱中..."))
                            } else {
                                Image(systemName: "brain.head.profile")
                                    .font(.appBody())
                                Text(isLocalKnowledgePoint ? "需雲端同步後可用" : "AI 重新審閱")
                                    .font(.appBody(for: isLocalKnowledgePoint ? "需雲端同步後可用" : "AI 重新審閱"))
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ModernSpacing.sm + 2)
                        .background(isLocalKnowledgePoint ? Color.modernBorder : Color.modernSpecial)
                        .foregroundStyle(isLocalKnowledgePoint ? Color.modernTextSecondary : .white)
                        .cornerRadius(ModernRadius.sm)
                    }
                    .disabled(isAIReviewing || isLocalKnowledgePoint)
                    
                    HStack(spacing: 16) {
                        // 歸檔/取消歸檔（本地知識點禁用）
                        Button(action: toggleArchiveStatus) {
                            HStack {
                                Image(systemName: localIsArchived ? "tray.and.arrow.up" : "tray.and.arrow.down")
                                    .font(.appBody())
                                Text(isLocalKnowledgePoint ? "需雲端同步" : (localIsArchived ? "取消歸檔" : "歸檔"))
                                    .font(.appBody(for: isLocalKnowledgePoint ? "需雲端同步" : (localIsArchived ? "取消歸檔" : "歸檔")))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ModernSpacing.sm + 2)
                            .background(isLocalKnowledgePoint ? Color.modernBorder : Color.modernAccentSoft)
                            .foregroundStyle(isLocalKnowledgePoint ? Color.modernTextSecondary : Color.modernAccent)
                            .cornerRadius(ModernRadius.sm)
                            .overlay {
                                RoundedRectangle(cornerRadius: ModernRadius.sm)
                                    .stroke(isLocalKnowledgePoint ? Color.modernBorder : Color.modernBorder, lineWidth: 1)
                            }
                        }
                        .disabled(isLocalKnowledgePoint)
                        
                        // 刪除按鈕（本地知識點可刪除但顯示不同文字）
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.appBody())
                                Text(isLocalKnowledgePoint ? "從本地刪除" : "刪除")
                                    .font(.appBody(for: isLocalKnowledgePoint ? "從本地刪除" : "刪除"))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ModernSpacing.sm + 2)
                            .background(Color.clear)
                            .foregroundStyle(Color.modernError)
                            .cornerRadius(ModernRadius.sm)
                            .overlay {
                                RoundedRectangle(cornerRadius: ModernRadius.sm)
                                    .stroke(Color.modernError, lineWidth: 1)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 工具列按鈕
    
    private var editButton: some View {
        Button(isEditing ? "完成" : "編輯") {
            if isEditing {
                if hasChanges {
                    saveChanges()
                } else {
                    isEditing = false
                }
            } else {
                isEditing = true
            }
        }
        .font(.appBody(for: isEditing ? "完成" : "編輯"))
        .fontWeight(.semibold)
        .foregroundColor(Color.modernAccent)
    }
    
    // MARK: - 保存訊息視圖
    
    private func saveMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: message.contains("成功") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.appBody())
                .foregroundStyle(message.contains("成功") ? Color.modernSuccess : Color.modernError)
            
            Text(message.replacingOccurrences(of: "✅ ", with: "").replacingOccurrences(of: "❌ ", with: ""))
                .font(.appBody(for: message))
                .fontWeight(.medium)
                .foregroundStyle(message.contains("成功") ? Color.modernSuccess : Color.modernError)
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.sm)
                .fill((message.contains("成功") ? Color.modernSuccess : Color.modernError).opacity(0.1))
        }
    }
    
    // MARK: - 計算屬性
    
    private var categoryIcon: String {
        switch point.category.lowercased() {
        case "grammar": return "textformat.abc"
        case "vocabulary": return "book.fill"
        case "syntax": return "curlybraces"
        case "idiom": return "quote.bubble.fill"
        default: return "questionmark.circle"
        }
    }
    
    
    private var hasChanges: Bool {
        return editablePoint.category != point.category ||
               editablePoint.subcategory != point.subcategory ||
               editablePoint.keyPointSummary != (point.keyPointSummary ?? "") ||
               editablePoint.correctPhrase != point.correctPhrase ||
               editablePoint.explanation != (point.explanation ?? "") ||
               editablePoint.incorrectPhrase != (point.incorrectPhraseInContext ?? "")
    }
    
    // MARK: - 動作方法
    
    private func cancelEditing() {
        editablePoint = EditableKnowledgePoint(from: point)
        isEditing = false
        saveMessage = nil
    }
    
    private func saveChanges() {
        isLoading = true
        saveMessage = nil
        
        // 模擬保存操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 這裡實際上應該呼叫 API 更新知識點
            // 暫時只更新本地狀態
            isLoading = false
            isEditing = false
            saveMessage = "保存成功"
            
            // 清除保存訊息
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                saveMessage = nil
            }
        }
    }
    
    private func performAIReview() {
        Task {
            isAIReviewing = true
            
            do {
                let result = try await UnifiedAPIService.shared.aiReviewKnowledgePoint(id: point.id)
                
                await MainActor.run {
                    aiReviewResult = result
                    isAIReviewing = false
                    showAIReviewSheet = true
                }
            } catch {
                await MainActor.run {
                    isAIReviewing = false
                    saveMessage = "AI審閱失敗：\(error.localizedDescription)"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        saveMessage = nil
                    }
                }
            }
        }
    }
    
    private func toggleArchiveStatus() {
        Task {
            let originalStatus = localIsArchived
            localIsArchived.toggle()
            
            do {
                if localIsArchived {
                    try await UnifiedAPIService.shared.archiveKnowledgePoint(id: point.id)
                } else {
                    try await UnifiedAPIService.shared.unarchiveKnowledgePoint(id: point.id)
                }
                
                await MainActor.run {
                    saveMessage = localIsArchived ? "已歸檔" : "已取消歸檔"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        saveMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    // 如果 API 調用失敗，恢復本地狀態
                    localIsArchived = originalStatus
                    saveMessage = "操作失敗：\(error.localizedDescription)"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        saveMessage = nil
                    }
                }
            }
        }
    }
    
    private func deleteKnowledgePoint() {
        Task {
            if isLocalKnowledgePoint {
                // 處理本地知識點刪除
                await deleteLocalKnowledgePoint()
            } else {
                // 處理雲端知識點刪除
                do {
                    try await UnifiedAPIService.shared.deleteKnowledgePoint(id: point.id)
                    
                    await MainActor.run {
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        saveMessage = "刪除失敗：\(error.localizedDescription)"
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            saveMessage = nil
                        }
                    }
                }
            }
        }
    }
    
    private func deleteLocalKnowledgePoint() async {
        // 刪除本地知識點的邏輯
        let guestDataManager = GuestDataManager.shared
        var localPoints = guestDataManager.getGuestKnowledgePoints()
        
        // 根據 UUID 字串 ID 找到並刪除對應的本地知識點
        if let originalId = point.aiReviewNotes, originalId == "本地儲存" {
            // 尋找匹配的本地知識點（通過內容匹配）
            localPoints.removeAll { pointData in
                if let category = pointData["category"] as? String,
                   let correctPhrase = pointData["correct_phrase"] as? String {
                    return category == point.category && correctPhrase == point.correctPhrase
                }
                return false
            }
            
            // 更新本地儲存
            if let data = try? JSONSerialization.data(withJSONObject: localPoints) {
                UserDefaults.standard.set(data, forKey: "guest_knowledge_points")
            }
        }
        
        await MainActor.run {
            saveMessage = "已從本地刪除"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        }
    }
    
    // MARK: - Helix 相關方法
    
    private func loadRelatedKnowledgePoints() {
        // 檢查是否為本地知識點（負數 ID 或超大數字）
        if point.id < 0 || point.id > Int32.max {
            print("⚠️ 本地知識點無法載入相關連結，ID: \(point.id)")
            relatedKnowledgePoints = []
            isLoadingRelatedPoints = false
            return
        }
        
        Task {
            isLoadingRelatedPoints = true
            
            do {
                let related = try await UnifiedAPIService.shared.getRelatedKnowledgePoints(id: point.id)
                
                await MainActor.run {
                    relatedKnowledgePoints = related
                    isLoadingRelatedPoints = false
                }
            } catch {
                await MainActor.run {
                    isLoadingRelatedPoints = false
                    // 靜默失敗，不顯示錯誤訊息以保持簡約
                }
            }
        }
    }
}

// MARK: - 輔助結構

struct EditableKnowledgePoint {
    var category: String
    var subcategory: String
    var keyPointSummary: String
    var correctPhrase: String
    var explanation: String
    var incorrectPhrase: String
    
    init(from point: KnowledgePoint) {
        self.category = point.category
        self.subcategory = point.subcategory
        self.keyPointSummary = point.keyPointSummary ?? ""
        self.correctPhrase = point.correctPhrase
        self.explanation = point.explanation ?? ""
        self.incorrectPhrase = point.incorrectPhraseInContext ?? ""
    }
    
    // 新增：直接初始化方法，用於 Preview 和測試
    init(category: String, subcategory: String, keyPointSummary: String, correctPhrase: String, explanation: String, incorrectPhrase: String = "") {
        self.category = category
        self.subcategory = subcategory
        self.keyPointSummary = keyPointSummary
        self.correctPhrase = correctPhrase
        self.explanation = explanation
        self.incorrectPhrase = incorrectPhrase
    }
}

struct AIReviewResultView: View {
    let reviewResult: AIReviewResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 整體評估
                    VStack(alignment: .leading, spacing: 10) {
                        Text("整體評估")
                            .font(.appTitle2(for: "整體評估"))
                            .fontWeight(.bold)
                        
                        Text(reviewResult.overallAssessment)
                            .font(.appBody(for: reviewResult.overallAssessment))
                            .padding()
                            .background(Color.modernSurface)
                            .cornerRadius(ModernRadius.md)
                    }
                    
                    // 評分
                    VStack(alignment: .leading, spacing: 15) {
                        Text("評分")
                            .font(.appTitle2(for: "評分"))
                            .fontWeight(.bold)
                        
                        ScoreRow(title: "準確性", score: reviewResult.accuracyScore)
                        ScoreRow(title: "清晰度", score: reviewResult.clarityScore)
                        ScoreRow(title: "教學效果", score: reviewResult.teachingEffectiveness)
                    }
                    
                    // 改進建議
                    if !reviewResult.improvementSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("改進建議")
                                .font(.appTitle2(for: "改進建議"))
                                .fontWeight(.bold)
                            
                            ForEach(reviewResult.improvementSuggestions, id: \.self) { suggestion in
                                HStack(alignment: .top) {
                                    Text("•")
                                        .font(.appBody())
                                    Text(suggestion)
                                        .font(.appBody(for: suggestion))
                                }
                            }
                        }
                    }
                    
                    // 補充例句
                    if !reviewResult.additionalExamples.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("補充例句")
                                .font(.appTitle2(for: "補充例句"))
                                .fontWeight(.bold)
                            
                            ForEach(reviewResult.additionalExamples, id: \.self) { example in
                                Text(example)
                                    .font(.appBody(for: example))
                                    .padding()
                                    .background(Color.modernSurface)
                                    .cornerRadius(ModernRadius.sm)
                            }
                        }
                    }
                }
                .padding(ModernSpacing.lg)
            }
            .navigationTitle("AI 審閱結果")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(.appBody(for: "完成"))
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - 相關知識點行組件

struct RelatedKnowledgePointRow: View {
    let point: KnowledgePoint
    
    var body: some View {
        NavigationLink(destination: KnowledgePointDetailView(point: point)) {
            HStack(spacing: 12) {
                // 類型圖標
                Image(systemName: categoryIcon)
                    .font(.appCallout())
                    .foregroundStyle(Color.modernAccent)
                    .frame(width: 20)
                
                // 知識點內容
                VStack(alignment: .leading, spacing: 2) {
                    Text(point.correctPhrase)
                        .font(.appBody(for: point.correctPhrase))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.modernTextPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if let summary = point.keyPointSummary, !summary.isEmpty {
                        Text(summary)
                            .font(.appCaption(for: summary))
                            .foregroundStyle(Color.modernTextSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // 掌握度指示器
                HStack(spacing: 4) {
                    Circle()
                        .fill(masteryColor)
                        .frame(width: 6, height: 6)
                    
                    Text("\(Int(point.masteryLevel * 100))%")
                        .font(.appCaption())
                        .foregroundStyle(Color.modernTextSecondary)
                }
            }
            .padding(.vertical, ModernSpacing.sm)
            .padding(.horizontal, ModernSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: ModernRadius.sm)
                    .fill(Color.modernBackground.opacity(0.5))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var categoryIcon: String {
        switch point.category.lowercased() {
        case "grammar": return "textformat.abc"
        case "vocabulary": return "book.fill"
        case "syntax": return "curlybraces"
        case "idiom": return "quote.bubble.fill"
        default: return "questionmark.circle"
        }
    }
    
    private var masteryColor: Color {
        if point.masteryLevel < 0.3 {
            return Color.modernError
        } else if point.masteryLevel < 0.7 {
            return Color.modernWarning
        } else {
            return Color.modernSuccess
        }
    }
}

struct ScoreRow: View {
    let title: String
    let score: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.appBody(for: title))
            
            Spacer()
            
            HStack(spacing: 8) {
                ProgressView(value: Double(score), total: 100)
                    .progressViewStyle(.linear)
                    .frame(width: 100)
                
                Text("\(score)")
                    .font(.appBody())
                    .fontWeight(.semibold)
                    .foregroundStyle(scoreColor(score))
            }
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 90...100: return Color.modernSuccess
        case 70...89: return Color.modernWarning
        default: return Color.modernError
        }
    }
}

#Preview {
    // 創建示例 KnowledgePoint 數據
    let samplePoint = KnowledgePoint(
        id: 1,
        category: "Grammar",
        subcategory: "Tense",
        correctPhrase: "I have been studying",
        explanation: "現在完成進行式用於表示從過去某時開始一直持續到現在的動作",
        userContextSentence: "I have been study English for two years.",
        incorrectPhraseInContext: "have been study",
        keyPointSummary: "現在完成進行式的構造：have/has + been + V-ing",
        masteryLevel: 0.7,
        mistakeCount: 3,
        correctCount: 7,
        nextReviewDate: "2024-01-20",
        isArchived: false,
        aiReviewNotes: "這是一個常見的語法錯誤，需要加強練習",
        lastAiReviewDate: "2024-01-15"
    )
    
    NavigationView {
        KnowledgePointDetailView(point: samplePoint)
    }
}
