// KnowledgePointEditView.swift

import SwiftUI

struct KnowledgePointEditView: View {
    @Binding var point: EditableKnowledgePoint
    let onSave: (EditableKnowledgePoint) -> Void
    let onCancel: () -> Void
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("分類資訊")) {
                    TextField("主分類", text: $point.category)
                    TextField("子分類", text: $point.subcategory)
                }
                
                Section(header: Text("核心知識點")) {
                    TextField("核心觀念", text: $point.key_point_summary)
                    TextField("正確用法", text: $point.correct_phrase)
                }
                
                Section(header: Text("詳細說明")) {
                    TextField("用法解析", text: $point.explanation, axis: .vertical)
                        .lineLimit(3...8)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("編輯知識點")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onCancel()
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveChanges()
                    }
                    .disabled(isSaving || !isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !point.category.isEmpty &&
        !point.subcategory.isEmpty &&
        !point.key_point_summary.isEmpty &&
        !point.correct_phrase.isEmpty
    }
    
    private func saveChanges() {
        isSaving = true
        errorMessage = nil
        
        // 這裡可以添加驗證邏輯
        if isValid {
            onSave(point)
        } else {
            errorMessage = "請填寫所有必填欄位"
        }
        
        isSaving = false
    }
}

#Preview {
    @State var samplePoint = EditableKnowledgePoint(
        category: "文法結構錯誤",
        subcategory: "動詞時態",
        key_point_summary: "現在完成進行式",
        correct_phrase: "has been studying",
        explanation: "當描述一個從過去持續到現在的動作時，應該使用現在完成進行式。"
    )
    
    KnowledgePointEditView(
        point: $samplePoint,
        onSave: { _ in },
        onCancel: { }
    )
}
