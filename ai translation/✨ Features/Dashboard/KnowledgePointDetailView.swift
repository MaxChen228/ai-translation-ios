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
    
    // 本地狀態追蹤
    @State private var localIsArchived: Bool
    
    init(point: KnowledgePoint) {
        self._point = State(initialValue: point)
        self._editablePoint = State(initialValue: EditableKnowledgePoint(from: point))
        self._localIsArchived = State(initialValue: point.is_archived ?? false)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 知識點卡片
                knowledgePointCard
                
                // 操作按鈕
                actionButtonsSection
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
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
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                        .foregroundStyle(categoryColor)
                    
                    Text("\(point.category) → \(point.subcategory)")
                        .font(.appCallout())
                        .fontWeight(.semibold)
                        .foregroundStyle(categoryColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(categoryColor.opacity(0.15))
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
                            .foregroundStyle(.blue)
                        
                        Text("掌握度")
                            .font(.appCaption(for: "掌握度"))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("\(Int(point.mastery_level * 100))%")
                        .font(.appTitle2())
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("錯誤 \(point.mistake_count) 次")
                            .font(.appCaption(for: "錯誤"))
                            .foregroundStyle(.red)
                        
                        Text("正確 \(point.correct_count) 次")
                            .font(.appCaption(for: "正確"))
                            .foregroundStyle(.green)
                    }
                    
                    if let nextReviewDate = point.next_review_date {
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
                .fill(localIsArchived ? Color.gray : Color.green)
                .frame(width: 8, height: 8)
            
            Text(localIsArchived ? "已歸檔" : "活躍")
                .font(.appCaption(for: localIsArchived ? "已歸檔" : "活躍"))
                .fontWeight(.medium)
                .foregroundStyle(localIsArchived ? .gray : .green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill((localIsArchived ? Color.gray : Color.green).opacity(0.1))
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 用戶原始句子
            if let userContextSentence = point.user_context_sentence {
                VStack(alignment: .leading, spacing: 8) {
                    Label("原始句子", systemImage: "quote.bubble.fill")
                        .font(.appHeadline(for: "原始句子"))
                        .foregroundColor(.orange)
                    
                    Text(userContextSentence)
                        .font(.appBody(for: userContextSentence))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        }
                }
            }
            
            // 錯誤片段
            if let incorrectPhrase = point.incorrect_phrase_in_context {
                VStack(alignment: .leading, spacing: 8) {
                    Label("錯誤片段", systemImage: "exclamationmark.triangle.fill")
                        .font(.appHeadline(for: "錯誤片段"))
                        .foregroundColor(.red)
                    
                    if isEditing {
                        TextField("錯誤片段", text: $editablePoint.incorrect_phrase)
                            .textFieldStyle(.roundedBorder)
                            .font(.appBody())
                    } else {
                        Text(incorrectPhrase)
                            .font(.appBody(for: incorrectPhrase))
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                            .strikethrough(color: .red)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    }
                            }
                    }
                }
            }
            
            // 核心知識點
            VStack(alignment: .leading, spacing: 8) {
                Label("核心知識點", systemImage: "lightbulb.fill")
                    .font(.appHeadline(for: "核心知識點"))
                    .foregroundColor(.blue)
                
                if isEditing {
                    TextField("核心知識點", text: $editablePoint.key_point_summary, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.appBody())
                        .lineLimit(2...4)
                } else {
                    if let keyPointSummary = point.key_point_summary, !keyPointSummary.isEmpty {
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
                    .foregroundColor(.green)
                
                if isEditing {
                    TextField("正確用法", text: $editablePoint.correct_phrase)
                        .textFieldStyle(.roundedBorder)
                        .font(.appBody())
                } else {
                    Text(point.correct_phrase)
                        .font(.appBody(for: point.correct_phrase))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                }
                        }
                }
            }
            
            // 用法解析
            if let explanation = point.explanation, !explanation.isEmpty || isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    Label("用法解析", systemImage: "sparkles")
                        .font(.appHeadline(for: "用法解析"))
                        .foregroundColor(.accentColor)
                    
                    if isEditing {
                        TextField("用法解析", text: $editablePoint.explanation, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .font(.appBody())
                            .lineLimit(3...6)
                    } else {
                        Text(explanation ?? "")
                            .font(.appBody(for: explanation ?? ""))
                            .lineSpacing(2)
                    }
                }
            }
            
            // AI 審閱結果
            if let aiReviewNotes = point.ai_review_notes, !aiReviewNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("AI 審閱建議", systemImage: "brain.head.profile")
                            .font(.appHeadline(for: "AI 審閱建議"))
                            .foregroundColor(.purple)
                        
                        Spacer()
                        
                        if let lastReviewDate = point.last_ai_review_date {
                            Text(lastReviewDate)
                                .font(.appCaption(for: lastReviewDate))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text(aiReviewNotes)
                        .font(.appBody(for: aiReviewNotes))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.1))
                        }
                }
            }
        }
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
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
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
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading || !hasChanges)
                }
            } else {
                // 檢視模式按鈕
                VStack(spacing: 12) {
                    // AI 重新審閱
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
                                Text("AI 重新審閱")
                                    .font(.appBody(for: "AI 重新審閱"))
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isAIReviewing)
                    
                    HStack(spacing: 16) {
                        // 歸檔/取消歸檔
                        Button(action: toggleArchiveStatus) {
                            HStack {
                                Image(systemName: localIsArchived ? "tray.and.arrow.up" : "tray.and.arrow.down")
                                    .font(.appBody())
                                Text(localIsArchived ? "取消歸檔" : "歸檔")
                                    .font(.appBody(for: localIsArchived ? "取消歸檔" : "歸檔"))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(localIsArchived ? Color.green : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // 刪除按鈕
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.appBody())
                                Text("刪除")
                                    .font(.appBody(for: "刪除"))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
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
        .foregroundColor(.orange)
    }
    
    // MARK: - 保存訊息視圖
    
    private func saveMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: message.contains("✅") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.appBody())
                .foregroundStyle(message.contains("✅") ? .green : .red)
            
            Text(message)
                .font(.appBody(for: message))
                .fontWeight(.medium)
                .foregroundStyle(message.contains("✅") ? .green : .red)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill((message.contains("✅") ? Color.green : Color.red).opacity(0.1))
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
    
    private var categoryColor: Color {
        switch point.category.lowercased() {
        case "grammar": return .blue
        case "vocabulary": return .green
        case "syntax": return .purple
        case "idiom": return .orange
        default: return .gray
        }
    }
    
    private var hasChanges: Bool {
        return editablePoint.category != point.category ||
               editablePoint.subcategory != point.subcategory ||
               editablePoint.key_point_summary != (point.key_point_summary ?? "") ||
               editablePoint.correct_phrase != point.correct_phrase ||
               editablePoint.explanation != (point.explanation ?? "") ||
               editablePoint.incorrect_phrase != (point.incorrect_phrase_in_context ?? "")
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
            saveMessage = "✅ 保存成功"
            
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
                let result = try await KnowledgePointAPIService.aiReviewKnowledgePoint(id: point.id)
                
                await MainActor.run {
                    aiReviewResult = result
                    isAIReviewing = false
                    showAIReviewSheet = true
                }
            } catch {
                await MainActor.run {
                    isAIReviewing = false
                    saveMessage = "❌ AI審閱失敗：\(error.localizedDescription)"
                    
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
                    try await KnowledgePointAPIService.archiveKnowledgePoint(id: point.id)
                } else {
                    try await KnowledgePointAPIService.unarchiveKnowledgePoint(id: point.id)
                }
                
                await MainActor.run {
                    saveMessage = localIsArchived ? "✅ 已歸檔" : "✅ 已取消歸檔"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        saveMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    // 如果 API 調用失敗，恢復本地狀態
                    localIsArchived = originalStatus
                    saveMessage = "❌ 操作失敗：\(error.localizedDescription)"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        saveMessage = nil
                    }
                }
            }
        }
    }
    
    private func deleteKnowledgePoint() {
        Task {
            do {
                try await KnowledgePointAPIService.deleteKnowledgePoint(id: point.id)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    saveMessage = "❌ 刪除失敗：\(error.localizedDescription)"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        saveMessage = nil
                    }
                }
            }
        }
    }
}

// MARK: - 輔助結構

struct EditableKnowledgePoint {
    var category: String
    var subcategory: String
    var key_point_summary: String
    var correct_phrase: String
    var explanation: String
    var incorrect_phrase: String
    
    init(from point: KnowledgePoint) {
        self.category = point.category
        self.subcategory = point.subcategory
        self.key_point_summary = point.key_point_summary ?? ""
        self.correct_phrase = point.correct_phrase
        self.explanation = point.explanation ?? ""
        self.incorrect_phrase = point.incorrect_phrase_in_context ?? ""
    }
    
    // 新增：直接初始化方法，用於 Preview 和測試
    init(category: String, subcategory: String, key_point_summary: String, correct_phrase: String, explanation: String, incorrect_phrase: String = "") {
        self.category = category
        self.subcategory = subcategory
        self.key_point_summary = key_point_summary
        self.correct_phrase = correct_phrase
        self.explanation = explanation
        self.incorrect_phrase = incorrect_phrase
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
                        
                        Text(reviewResult.overall_assessment)
                            .font(.appBody(for: reviewResult.overall_assessment))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    // 評分
                    VStack(alignment: .leading, spacing: 15) {
                        Text("評分")
                            .font(.appTitle2(for: "評分"))
                            .fontWeight(.bold)
                        
                        ScoreRow(title: "準確性", score: reviewResult.accuracy_score)
                        ScoreRow(title: "清晰度", score: reviewResult.clarity_score)
                        ScoreRow(title: "教學效果", score: reviewResult.teaching_effectiveness)
                    }
                    
                    // 改進建議
                    if !reviewResult.improvement_suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("改進建議")
                                .font(.appTitle2(for: "改進建議"))
                                .fontWeight(.bold)
                            
                            ForEach(reviewResult.improvement_suggestions, id: \.self) { suggestion in
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
                    if !reviewResult.additional_examples.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("補充例句")
                                .font(.appTitle2(for: "補充例句"))
                                .fontWeight(.bold)
                            
                            ForEach(reviewResult.additional_examples, id: \.self) { example in
                                Text(example)
                                    .font(.appBody(for: example))
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(20)
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
                    .foregroundColor(scoreColor(score))
            }
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 90...100: return .green
        case 70...89: return .orange
        default: return .red
        }
    }
}

#Preview {
    // 創建示例 KnowledgePoint 數據
    let samplePoint = KnowledgePoint(
        id: 1,
        category: "Grammar",
        subcategory: "Tense",
        correct_phrase: "I have been studying",
        explanation: "現在完成進行式用於表示從過去某時開始一直持續到現在的動作",
        user_context_sentence: "I have been study English for two years.",
        incorrect_phrase_in_context: "have been study",
        key_point_summary: "現在完成進行式的構造：have/has + been + V-ing",
        mastery_level: 0.7,
        mistake_count: 3,
        correct_count: 7,
        next_review_date: "2024-01-20",
        is_archived: false,
        ai_review_notes: "這是一個常見的語法錯誤，需要加強練習",
        last_ai_review_date: "2024-01-15"
    )
    
    NavigationView {
        KnowledgePointDetailView(point: samplePoint)
    }
}
