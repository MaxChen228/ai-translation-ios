//  KnowledgePointDetailView.swift

import SwiftUI

struct KnowledgePointDetailView: View {
    let point: KnowledgePoint
    
    @Environment(\.presentationMode) var presentationMode
    
    // 編輯相關狀態
    @State private var isEditing = false
    @State private var editablePoint: EditableKnowledgePoint
    
    // AI 審閱相關狀態
    @State private var isAIReviewing = false
    @State private var aiReviewResult: AIReviewResult?
    @State private var showAIReviewSheet = false
    
    // Alert 相關狀態
    @State private var showingConfirmationAlert = false
    @State private var alertConfig: AlertConfig?
    
    // 初始化時設定可編輯的知識點
    init(point: KnowledgePoint) {
        self.point = point
        self._editablePoint = State(initialValue: EditableKnowledgePoint(from: point))
    }
    
    struct AlertConfig {
        let title: String
        let message: String
        let primaryAction: () -> Void
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 編輯模式切換按鈕
                HStack {
                    Spacer()
                    Button(action: {
                        if isEditing {
                            Task {
                                await saveChanges()
                            }
                        } else {
                            isEditing = true
                        }
                    }) {
                        if isEditing {
                            Label("儲存", systemImage: "checkmark")
                        } else {
                            Label("編輯", systemImage: "pencil")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAIReviewing)
                    
                    if isEditing {
                        Button("取消") {
                            cancelEditing()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
                
                // AI 審閱按鈕
                HStack {
                    Spacer()
                    Button(action: {
                        Task {
                            await performAIReview()
                        }
                    }) {
                        HStack {
                            if isAIReviewing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("AI 審閱中...")
                            } else {
                                Image(systemName: "sparkles")
                                Text("AI 重新審閱")
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isAIReviewing || isEditing)
                    Spacer()
                }
                .padding(.horizontal)
                
                // 主要內容
                VStack(alignment: .leading, spacing: 24) {
                    // 學習狀態區塊
                    learningStatusSection
                    
                    // 錯誤上下文區塊
                    if let sentence = point.user_context_sentence, !sentence.isEmpty,
                       let incorrectPhrase = point.incorrect_phrase_in_context {
                        errorContextSection(sentence: sentence, incorrectPhrase: incorrectPhrase)
                    }
                    
                    // 核心知識點區塊
                    knowledgePointSection
                    
                    // AI 審閱歷史
                    if let reviewNotes = point.ai_review_notes, !reviewNotes.isEmpty {
                        aiReviewHistorySection(reviewNotes: reviewNotes)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(point.key_point_summary ?? "知識點詳情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        self.alertConfig = AlertConfig(
                            title: "確認封存",
                            message: "您確定要封存「\(point.correct_phrase)」嗎？您之後可以在封存區找到它。",
                            primaryAction: {
                                archivePoint()
                            }
                        )
                        self.showingConfirmationAlert = true
                    }) {
                        Label("封存此點", systemImage: "archivebox")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        self.alertConfig = AlertConfig(
                            title: "確認刪除",
                            message: "您確定要永久刪除「\(point.correct_phrase)」嗎？此操作無法復原。",
                            primaryAction: {
                                deletePoint()
                            }
                        )
                        self.showingConfirmationAlert = true
                    }) {
                        Label("永久刪除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert(isPresented: $showingConfirmationAlert) {
            Alert(
                title: Text(alertConfig?.title ?? "確認"),
                message: Text(alertConfig?.message ?? ""),
                primaryButton: .destructive(Text("確定")) {
                    alertConfig?.primaryAction()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .sheet(isPresented: $showAIReviewSheet) {
            if let reviewResult = aiReviewResult {
                AIReviewResultView(reviewResult: reviewResult)
            }
        }
    }
    
    // MARK: - 視圖組件
    
    private var learningStatusSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeader(title: "學習狀態", icon: "chart.bar.fill")
            
            VStack(alignment: .leading, spacing: 12) {
                Text("熟練度")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                MasteryBarView(masteryLevel: point.mastery_level)
            }
            .padding(.vertical, 8)
            
            HStack {
                Label("錯誤次數", systemImage: "xmark.circle")
                Spacer()
                Text("\(point.mistake_count) 次")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("答對次數", systemImage: "checkmark.circle")
                Spacer()
                Text("\(point.correct_count) 次")
                    .foregroundColor(.secondary)
            }
            
            if let nextReviewDateString = point.next_review_date,
               let nextReviewDate = ISO8601DateFormatter().date(from: nextReviewDateString) {
                HStack {
                    Label("下次複習", systemImage: "calendar.badge.clock")
                    Spacer()
                    Text(nextReviewDate, style: .date)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func errorContextSection(sentence: String, incorrectPhrase: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "錯誤上下文", icon: "text.quote")
            
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 4)
                    .padding(.trailing, 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("你翻譯的句子", systemImage: "text.quote")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    
                    Text(sentence)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.vertical, 12)
            .background(Color.accentColor.opacity(0.05))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("你的錯誤片語：")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(incorrectPhrase)
                    .font(.system(.body, design: .monospaced).bold())
                    .foregroundStyle(.red)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var knowledgePointSection: some View {
            VStack(alignment: .leading, spacing: 15) {
                SectionHeader(title: "核心知識點", icon: "lightbulb.fill")
                
                VStack(alignment: .leading, spacing: 15) {
                    // 分類資訊
                    if isEditing {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("分類")
                                .font(.headline)
                            TextField("分類", text: $editablePoint.category)
                                .textFieldStyle(.roundedBorder)
                            TextField("子分類", text: $editablePoint.subcategory)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else {
                        HStack {
                            Label("分類", systemImage: "folder.fill")
                                .font(.headline)
                            Spacer()
                            Text("\(point.category) → \(point.subcategory)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // 核心觀念
                    VStack(alignment: .leading, spacing: 8) {
                        Label("核心觀念", systemImage: "brain.head.profile")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        if isEditing {
                            TextField("核心觀念", text: $editablePoint.key_point_summary)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            Text(point.key_point_summary ?? "未設定")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // 正確用法
                    VStack(alignment: .leading, spacing: 8) {
                        Label("正確用法", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        if isEditing {
                            TextField("正確用法", text: $editablePoint.correct_phrase)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            Text(point.correct_phrase)
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .padding(.leading, 8)
                        }
                    }
                    
                    // 用法解析
                    if let explanation = point.explanation, !explanation.isEmpty || isEditing {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("用法解析", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                            
                            if isEditing {
                                TextField("用法解析", text: $editablePoint.explanation, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)
                            } else {
                                Text(explanation ?? "")
                                    .font(.body)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        
        private func aiReviewHistorySection(reviewNotes: String) -> some View {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    SectionHeader(title: "AI 審閱歷史", icon: "sparkles")
                    Spacer()
                    if let lastReviewDate = point.last_ai_review_date,
                       let date = ISO8601DateFormatter().date(from: lastReviewDate) {
                        Text("最後審閱：\(date, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button("查看完整審閱報告") {
                    parseAndShowAIReview(reviewNotes)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        
        // MARK: - 輔助函式
        
        private func saveChanges() async {
            let updates: [String: Any] = [
                "category": editablePoint.category,
                "subcategory": editablePoint.subcategory,
                "key_point_summary": editablePoint.key_point_summary,
                "correct_phrase": editablePoint.correct_phrase,
                "explanation": editablePoint.explanation
            ]
            
            do {
                try await KnowledgePointAPIService.updateKnowledgePoint(id: point.id, updates: updates)
                isEditing = false
                // 可以在這裡添加成功提示
            } catch {
                // 處理錯誤，可以顯示 Alert
                print("更新失敗: \(error)")
            }
        }
        
        private func cancelEditing() {
            editablePoint = EditableKnowledgePoint(from: point)
            isEditing = false
        }
        
        private func performAIReview() async {
            isAIReviewing = true
            
            do {
                let reviewResult = try await KnowledgePointAPIService.aiReviewKnowledgePoint(
                    id: point.id,
                    modelName: SettingsManager.shared.generationModel.rawValue
                )
                
                self.aiReviewResult = reviewResult
                self.showAIReviewSheet = true
            } catch {
                // 處理錯誤
                print("AI 審閱失敗: \(error)")
            }
            
            isAIReviewing = false
        }
        
        private func parseAndShowAIReview(_ reviewNotes: String) {
            if let data = reviewNotes.data(using: .utf8),
               let reviewResult = try? JSONDecoder().decode(AIReviewResult.self, from: data) {
                self.aiReviewResult = reviewResult
                self.showAIReviewSheet = true
            }
        }
        
        private func archivePoint() {
            Task {
                do {
                    try await KnowledgePointAPIService.archivePoint(id: point.id)
                    await MainActor.run {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                } catch {
                    print("封存失敗: \(error)")
                }
            }
        }

        private func deletePoint() {
            Task {
                do {
                    try await KnowledgePointAPIService.deletePoint(id: point.id)
                    await MainActor.run {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                } catch {
                    print("刪除失敗: \(error)")
                }
            }
        }
    }

    // MARK: - 輔助結構和視圖

    struct EditableKnowledgePoint {
        var category: String
        var subcategory: String
        var key_point_summary: String
        var correct_phrase: String
        var explanation: String
        
        init(from point: KnowledgePoint) {
            self.category = point.category
            self.subcategory = point.subcategory
            self.key_point_summary = point.key_point_summary ?? ""  // 恢復 ?? ""
            self.correct_phrase = point.correct_phrase
            self.explanation = point.explanation ?? ""  // 恢復 ?? ""
        }
        
        // 【在這裡添加新的初始化方法】
        init(category: String, subcategory: String, key_point_summary: String, correct_phrase: String, explanation: String) {
            self.category = category
            self.subcategory = subcategory
            self.key_point_summary = key_point_summary
            self.correct_phrase = correct_phrase
            self.explanation = explanation
        }
    }

    struct SectionHeader: View {
        let title: String
        let icon: String
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
    }

    struct AIReviewResultView: View {
        let reviewResult: AIReviewResult
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 整體評估
                        VStack(alignment: .leading, spacing: 10) {
                            Text("整體評估")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(reviewResult.overall_assessment)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        // 評分
                        VStack(alignment: .leading, spacing: 15) {
                            Text("評分")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            ScoreRow(title: "準確性", score: reviewResult.accuracy_score)
                            ScoreRow(title: "清晰度", score: reviewResult.clarity_score)
                            ScoreRow(title: "教學效果", score: reviewResult.teaching_effectiveness)
                        }
                        
                        // 改進建議
                        if !reviewResult.improvement_suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("改進建議")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                ForEach(reviewResult.improvement_suggestions, id: \.self) { suggestion in
                                    HStack(alignment: .top) {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(.yellow)
                                            .padding(.top, 2)
                                        Text(suggestion)
                                            .font(.body)
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                        }
                        
                        // 潛在困惑點
                        if !reviewResult.potential_confusions.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("潛在困惑點")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                ForEach(reviewResult.potential_confusions, id: \.self) { confusion in
                                    HStack(alignment: .top) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .padding(.top, 2)
                                        Text(confusion)
                                            .font(.body)
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                        }
                        
                        // 額外例句
                        if !reviewResult.additional_examples.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("建議補充例句")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                ForEach(reviewResult.additional_examples, id: \.self) { example in
                                    Text("• \(example)")
                                        .font(.body)
                                        .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("AI 審閱報告")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            presentationMode.wrappedValue.dismiss()
                        }
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
                    .font(.body)
                Spacer()
                HStack(spacing: 2) {
                    ForEach(1...10, id: \.self) { index in
                        Circle()
                            .fill(index <= score ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }
                Text("\(score)/10")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    #Preview {
        let samplePoint = KnowledgePoint(
            id: 1,
            category: "文法結構錯誤",
            subcategory: "動詞時態",
            correct_phrase: "has been studying",
            explanation: "當描述一個從過去持續到現在的動作時，應該使用現在完成進行式，以強調動作的持續性。",
            user_context_sentence: "He is studying English for three years.",
            incorrect_phrase_in_context: "is studying",
            key_point_summary: "現在完成進行式",
            mastery_level: 0.35,
            mistake_count: 3,
            correct_count: 1,
            next_review_date: "2025-07-20T10:00:00Z",
            is_archived: false,
            ai_review_notes: nil,
            last_ai_review_date: nil
        )
        
        return NavigationView {
            KnowledgePointDetailView(point: samplePoint)
        }
    }
