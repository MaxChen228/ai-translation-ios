// ReaderSettingsView.swift - 修正版本

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
                        FontSettingsContent(settings: $settings)
                    }
                    
                    // 閱讀環境設定
                    ReaderSettingsSection(title: "閱讀環境", icon: "eye") {
                        EnvironmentSettingsContent(settings: $settings)
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

// MARK: - 字體設定內容

struct FontSettingsContent: View {
    @Binding var settings: ReaderSettings
    
    var body: some View {
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
            
            // 中文字體
            VStack(alignment: .leading, spacing: 12) {
                Text("中文字體")
                    .font(.appCallout(for: "設定選項"))
                
                HStack(spacing: 12) {
                    ForEach(ReaderSettings.ChineseFontFamily.allCases, id: \.self) { fontFamily in
                        FontOption(
                            fontFamily: fontFamily.displayName,
                            sampleText: "文字",
                            fontName: fontFamily.fontName,
                            isSelected: settings.chineseFontFamily == fontFamily,
                            onTap: { settings.chineseFontFamily = fontFamily }
                        )
                    }
                    
                    Spacer()
                }
            }
            
            Divider()
            
            // 英文字體
            VStack(alignment: .leading, spacing: 12) {
                Text("英文字體")
                    .font(.appCallout(for: "設定選項"))
                
                HStack(spacing: 12) {
                    ForEach(ReaderSettings.EnglishFontFamily.allCases, id: \.self) { fontFamily in
                        FontOption(
                            fontFamily: fontFamily.displayName,
                            sampleText: "Text",
                            fontName: fontFamily.fontName,
                            isSelected: settings.englishFontFamily == fontFamily,
                            onTap: { settings.englishFontFamily = fontFamily }
                        )
                    }
                    
                    Spacer()
                }
            }
            
            Divider()
            
            // 行距
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("行距")
                        .font(.appCallout(for: "設定選項"))
                    
                    Spacer()
                    
                    Text(String(format: "%.1f", settings.lineSpacing))
                        .font(.appCallout())
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
}

// MARK: - 環境設定內容

struct EnvironmentSettingsContent: View {
    @Binding var settings: ReaderSettings
    
    var body: some View {
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

// MARK: - 預覽區段 (簡化版本)

struct ReaderPreviewSection: View {
    let settings: ReaderSettings
    
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
            
            // 簡化的預覽區域
            PreviewTextContent(settings: settings)
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct PreviewTextContent: View {
    let settings: ReaderSettings
    
    var body: some View {
        VStack(spacing: 0) {
            // 英文段落
            Text("Learning English grammar can be challenging, but with the right approach, it becomes much more manageable.")
                .font(.custom(settings.englishFontFamily.fontName, size: CGFloat(settings.fontSize)))
                .lineSpacing(CGFloat(settings.lineSpacing - 1.0) * CGFloat(settings.fontSize))
                .foregroundStyle(settings.backgroundColor.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, CGFloat(settings.fontSize) * 0.5)
            
            // 中文段落
            Text("學習英語語法雖然具有挑戰性，但只要方法得當，就會變得更加容易掌握。")
                .font(.custom(settings.chineseFontFamily.fontName, size: CGFloat(settings.fontSize)))
                .lineSpacing(CGFloat(settings.lineSpacing - 1.0) * CGFloat(settings.fontSize))
                .foregroundStyle(settings.backgroundColor.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, CGFloat(settings.fontSize) * 0.5)
            
            // 混合段落
            Text("This book will guide you through complex grammatical structures.")
                .font(.custom(settings.englishFontFamily.fontName, size: CGFloat(settings.fontSize)))
                .lineSpacing(CGFloat(settings.lineSpacing - 1.0) * CGFloat(settings.fontSize))
                .foregroundStyle(settings.backgroundColor.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
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

#Preview {
    @Previewable @State var settings = ReaderSettings()
    
    ReaderSettingsView(settings: $settings)
}
