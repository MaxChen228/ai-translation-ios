// ReaderView.swift - Apple Books風格的閱讀器

import SwiftUI

struct ReaderView: View {
    let book: ReaderBook
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPage: Int = 1
    @State private var showingMenu = false
    @State private var showingSettings = false
    @State private var selectedText: String = ""
    @State private var showingTextMenu = false
    @State private var textMenuPosition: CGPoint = .zero
    @State private var settings = ReaderSettings()
    
    // 模擬書籍內容（將來會從實際文件中讀取）
    private let sampleContent = """
    Chapter 1: Introduction to Advanced Grammar
    
    Learning English grammar can be challenging, but with the right approach, it becomes much more manageable. This book will guide you through complex grammatical structures that are essential for advanced English proficiency.
    
    The key to mastering grammar is understanding the underlying patterns and practicing them in context. We'll explore various sentence structures, from simple declarative sentences to complex conditional statements.
    
    One of the most important aspects of advanced grammar is the proper use of tenses. English has a rich tense system that allows speakers to express subtle differences in timing and aspect.
    
    For example, the present perfect continuous tense (have been doing) indicates an action that started in the past and continues to the present moment, often with emphasis on the duration or ongoing nature of the action.
    
    Another crucial element is the subjunctive mood, which is used to express hypothetical situations, suggestions, or contrary-to-fact conditions. While less common in modern English, it still appears in formal writing and certain fixed expressions.
    
    Understanding these advanced concepts will significantly improve your ability to communicate complex ideas clearly and precisely in English.
    """
    
    var body: some View {
        ZStack {
            // 背景
            settings.backgroundColor.color
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 頂部工具列
                if showingMenu {
                    ReaderTopToolbar(
                        bookTitle: book.title,
                        onClose: { dismiss() },
                        onSettings: { showingSettings = true }
                    )
                    .transition(.move(edge: .top))
                }
                
                // 主要內容區域
                GeometryReader { geometry in
                    ZStack {
                        // 可選取的文字內容
                        SelectableTextView(
                            content: sampleContent,
                            settings: settings,
                            onTextSelected: { text, position in
                                selectedText = text
                                textMenuPosition = position
                                showingTextMenu = true
                            }
                        )
                        .padding(.horizontal, settings.pageMargin)
                        .padding(.vertical, 40)
                        
                        // 文字選取工具列
                        if showingTextMenu && !selectedText.isEmpty {
                            TextSelectionMenu(
                                selectedText: selectedText,
                                position: textMenuPosition,
                                onHighlight: {
                                    // TODO: 新增螢光筆功能
                                    showingTextMenu = false
                                },
                                onAddNote: {
                                    // TODO: 新增筆記功能
                                    showingTextMenu = false
                                },
                                onCreateKnowledgePoint: {
                                    // TODO: 創建知識點
                                    showingTextMenu = false
                                },
                                onDismiss: {
                                    showingTextMenu = false
                                    selectedText = ""
                                }
                            )
                        }
                    }
                }
                
                // 底部工具列
                if showingMenu {
                    ReaderBottomToolbar(
                        currentPage: currentPage,
                        totalPages: book.totalPages,
                        progress: Double(currentPage) / Double(book.totalPages),
                        onPageChange: { page in
                            currentPage = page
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingMenu.toggle()
            }
        }
        .sheet(isPresented: $showingSettings) {
            ReaderSettingsView(settings: $settings)
        }
        .onAppear {
            currentPage = book.currentPage
        }
    }
}

// MARK: - 工具列組件

struct ReaderTopToolbar: View {
    let bookTitle: String
    let onClose: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.appHeadline(for: "✕"))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            Text(bookTitle)
                .font(.appCallout(for: bookTitle))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Button(action: onSettings) {
                Image(systemName: "textformat.size")
                    .font(.appHeadline(for: "🖄"))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

struct ReaderBottomToolbar: View {
    let currentPage: Int
    let totalPages: Int
    let progress: Double
    let onPageChange: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 進度條
            HStack {
                Text("\(currentPage)")
                    .font(.appSubheadline())
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
                
                Slider(
                    value: Binding(
                        get: { Double(currentPage) },
                        set: { onPageChange(Int($0)) }
                    ),
                    in: 1...Double(totalPages),
                    step: 1
                )
                .tint(.orange)
                
                Text("\(totalPages)")
                    .font(.appSubheadline())
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
            }
            
            // 操作按鈕
            HStack(spacing: 40) {
                Button(action: {}) {
                    Image(systemName: "bookmark")
                        .font(.appTitle3(for: "🔖"))
                        .foregroundStyle(.primary)
                }
                
                Button(action: {}) {
                    Image(systemName: "note.text")
                        .font(.appTitle3(for: "📝"))
                        .foregroundStyle(.primary)
                }
                
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.appTitle3(for: "🔍"))
                        .foregroundStyle(.primary)
                }
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.appTitle3(for: "📤"))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
}

// MARK: - 文字選取相關組件

struct SelectableTextView: UIViewRepresentable {
    let content: String
    let settings: ReaderSettings
    let onTextSelected: (String, CGPoint) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = UIColor.clear
        textView.delegate = context.coordinator
        
        // 設定字體和樣式
        updateTextView(textView)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        updateTextView(uiView)
    }
    
    private func updateTextView(_ textView: UITextView) {
        let fontSize = CGFloat(settings.fontSize)
        
        // 分析文字內容並決定字體
        let font = settings.getUIFont(size: fontSize, for: content)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CGFloat(settings.lineSpacing - 1.0) * fontSize
        paragraphStyle.paragraphSpacing = fontSize * 0.5
        
        let attributedString = NSAttributedString(
            string: content,
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.label
            ]
        )
        
        textView.attributedText = attributedString
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let parent: SelectableTextView
        
        init(_ parent: SelectableTextView) {
            self.parent = parent
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            guard let selectedRange = textView.selectedTextRange,
                  !selectedRange.isEmpty else { return }
            
            let selectedText = textView.text(in: selectedRange) ?? ""
            
            if !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // 計算選取文字的位置
                let rect = textView.firstRect(for: selectedRange)
                let position = CGPoint(x: rect.midX, y: rect.minY)
                
                parent.onTextSelected(selectedText, position)
            }
        }
    }
}

struct TextSelectionMenu: View {
    let selectedText: String
    let position: CGPoint
    let onHighlight: () -> Void
    let onAddNote: () -> Void
    let onCreateKnowledgePoint: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 選取的文字預覽
            Text("\"\(selectedText.prefix(50))\(selectedText.count > 50 ? "..." : "")\"")
                .font(.appSubheadline(for: selectedText))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            Divider()
            
            // 操作按鈕
            VStack(spacing: 8) {
                Button(action: onHighlight) {
                    HStack {
                        Image(systemName: "highlighter")
                            .frame(width: 20)
                        Text("螢光筆")
                        Spacer()
                    }
                    .font(.appCallout(for: "功能選項"))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                Button(action: onAddNote) {
                    HStack {
                        Image(systemName: "note.text")
                            .frame(width: 20)
                        Text("新增筆記")
                        Spacer()
                    }
                    .font(.appCallout(for: "功能選項"))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                Button(action: onCreateKnowledgePoint) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .frame(width: 20)
                        Text("建立知識點")
                        Spacer()
                    }
                    .font(.appCallout(for: "功能選項"))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .padding(.bottom, 8)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        .position(x: position.x, y: max(120, position.y - 50))
        .onTapGesture {
            // 防止點擊菜單時關閉
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }
        )
    }
}

#Preview {
    ReaderView(book: ReaderBook(
        title: "英語語法大全",
        author: "示範作者",
        totalPages: 200
    ))
}
