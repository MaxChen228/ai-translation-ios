// ReaderSettingsView.swift

import SwiftUI

struct ReaderSettingsView: View {
    @Binding var settings: ReaderSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // 字體設定
                    ReaderSettingsSection(title: "字體設定", icon: "textformat.size") {
                        VStack(spacing: 20) {
                            // 字體大小
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("字體大小")
                                        .font(.appCallout(for: "字體大小"))
                                    
                                    Spacer()
                                    
                                    Text("\(Int(settings.fontSize))")
                                        .font(.appCallout())
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                
                                HStack {
                                    Text("A")
                                        .font(.appCaption(for: "A"))
                                        .foregroundStyle(.secondary)
                                    
                                    Slider(
                                        value: $settings.fontSize,
                                        in: 12...24,
                                        step: 1
                                    )
                                    .tint(.orange)
                                    
                                    Text("A")
                                        .font(.appTitle3(for: "A"))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            // 中文字體選擇
                            VStack(alignment: .leading, spacing: 12) {
                                Text("中文字體")
                                    .font(.appCallout(for: "設定選項"))
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(ReaderSettings.ChineseFontFamily.allCases, id: \.self) { font in
                                        FontOption(
                                            fontFamily: font.displayName,
                                            sampleText: "中文字體預覽",
                                            fontName: font.fontName,
                                            isSelected: settings.chineseFontFamily == font,
                                            onTap: { settings.chineseFontFamily = font }
                                        )
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // 英文字體選擇
                            VStack(alignment: .leading, spacing: 12) {
                                Text("英文字體")
                                    .font(.appCallout(for: "設定選項"))
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(ReaderSettings.EnglishFontFamily.allCases, id: \.self) { font in
                                        FontOption(
                                            fontFamily: font.displayName,
                                            sampleText: "English Font",
                                            fontName: font.fontName,
                                            isSelected: settings.englishFontFamily == font,
                                            onTap: { settings.englishFontFamily = font }
                                        )
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // 行距
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("行距")
                                        .font(.appCallout(for: "設定選項"))
                                    
                                    Spacer()
                                    
                                    Text("\(settings.lineSpacing, specifier: "%.1f")")
                                        .font(.appCallout(for: "設定值"))
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                
                                Slider(
                                    value: $settings.lineSpacing,
                                    in: 1.0...2.5,
                                    step: 0.1
                                )
                                .tint(.orange)
                            }
                        }
                    }
                    
                    // 閱讀環境設定
                    ReaderSettingsSection(title: "閱讀環境", icon: "eye") {
                        VStack(spacing: 16) {
                            // 背景色選擇
                            VStack(alignment: .leading, spacing: 12) {
                                Text("背景顏色")
                                    .font(.appCallout(for: "設定選項"))
                                
                                HStack(spacing: 12) {
                                    ForEach(ReaderSettings.ReaderBackgroundColor.allCases, id: \.self) { bgColor in
                                        BackgroundColorOption(
                                            color: bgColor,
                                            isSelected: settings.backgroundColor == bgColor,
                                            onTap: { settings.backgroundColor = bgColor }
                                        )
                                    }
                                    
                                    Spacer()
                                }
                            }
                            
                            Divider()
                            
                            // 自動儲存進度
                            HStack {
                                Text("自動儲存閱讀進度")
                                    .font(.appCallout(for: "設定選項"))
                                
                                Spacer()
                                
                                Toggle("", isOn: $settings.autoSaveProgress)
                                    .toggleStyle(SwitchToggleStyle())
                                    .font(.appCallout(for: "設定選項"))
                                    .tint(.orange)
                            }
                        }
                    }
                    
                    // 文字預覽
                    ReaderPreviewSection(settings: settings)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("閱讀設定")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(.appCallout(for: "完成"))
                    .foregroundStyle(.orange)
                }
            }
        }
    }
}

// MARK: - 組件

struct ReaderSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.appHeadline(for: "設定標題"))
                    .foregroundStyle(.orange)
                
                Text(title)
                    .font(.appTitle3(for: "設定標題"))
                    .foregroundStyle(.primary)
            }
            
            content
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct FontOption: View {
    let fontFamily: String
    let sampleText: String
    let fontName: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(sampleText)
                    .font(.custom(fontName, size: 14))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                    .frame(height: 20)
                
                Text(fontFamily)
                    .font(.appCaption(for: "小標題"))
                    .foregroundStyle(isSelected ? .orange : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color.orange : Color.clear,
                                lineWidth: 2
                            )
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

struct BackgroundColorOption: View {
    let color: ReaderSettings.ReaderBackgroundColor
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.color)
                    .frame(width: 60, height: 40)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color.orange : Color(.systemGray4),
                                lineWidth: isSelected ? 3 : 1
                            )
                    }
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.appCaption(for: "顏色名稱"))
                                .foregroundStyle(.orange)
                        }
                    }
                
                Text(color.rawValue)
                    .font(.appCaption(for: "小標題"))
                    .foregroundStyle(isSelected ? .orange : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ReaderPreviewSection: View {
    let settings: ReaderSettings
    
    private let previewText = """
    Learning English grammar can be challenging, but with the right approach, it becomes much more manageable.
    
    學習英語語法雖然具有挑戰性，但只要方法得當，就會變得更加容易掌握。
    
    This book will guide you through complex grammatical structures that are essential for advanced English proficiency.
    """
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "eye.fill")
                    .font(.appHeadline(for: "設定標題"))
                    .foregroundStyle(.orange)
                
                Text("預覽效果")
                    .font(.appTitle3(for: "設定標題"))
                    .foregroundStyle(.primary)
            }
            
            // 預覽區域
            VStack {
                // 混合文字預覽，使用新的字體系統
                VStack(alignment: .leading, spacing: CGFloat(settings.lineSpacing - 1.0) * CGFloat(settings.fontSize)) {
                    ForEach(previewText.components(separatedBy: "\n\n"), id: \.self) { paragraph in
                        if !paragraph.isEmpty {
                            Text(paragraph)
                                .font(settings.getFont(size: CGFloat(settings.fontSize), for: paragraph))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(settings.pageMargin)
                .background(settings.backgroundColor.color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                }
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    @Previewable @State var settings = ReaderSettings()
    
    ReaderSettingsView(settings: $settings)
}
