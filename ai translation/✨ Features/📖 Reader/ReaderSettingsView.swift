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
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Spacer()
                                    
                                    Text("\(Int(settings.fontSize))")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                
                                HStack {
                                    Text("A")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                    
                                    Slider(
                                        value: $settings.fontSize,
                                        in: 12...24,
                                        step: 1
                                    )
                                    .tint(.orange)
                                    
                                    Text("A")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            // 行距
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("行距")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Spacer()
                                    
                                    Text("\(settings.lineSpacing, specifier: "%.1f")")
                                        .font(.system(size: 16, weight: .bold))
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
                                    .font(.system(size: 16, weight: .medium))
                                
                                HStack(spacing: 12) {
                                    ForEach(ReaderSettings.ReaderBackgroundColor.allCases, id: \.self) { bgColor in
                                        BackgroundColorOption(
                                            color: bgColor,
                                            isSelected: settings.backgroundColor == bgColor,
                                            onTap: {
                                                settings.backgroundColor = bgColor
                                            }
                                        )
                                    }
                                    
                                    Spacer()
                                }
                            }
                            
                            Divider()
                            
                            // 頁邊距
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("頁邊距")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Spacer()
                                    
                                    Text("\(Int(settings.pageMargin))")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                
                                Slider(
                                    value: $settings.pageMargin,
                                    in: 10...40,
                                    step: 5
                                )
                                .tint(.orange)
                            }
                        }
                    }
                    
                    // 功能設定
                    ReaderSettingsSection(title: "功能設定", icon: "gearshape") {
                        VStack(spacing: 16) {
                            Toggle("自動儲存閱讀進度", isOn: $settings.autoSaveProgress)
                                .font(.system(size: 16, weight: .medium))
                                .tint(.orange)
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
                    .font(.system(size: 16, weight: .semibold))
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
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.orange)
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
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
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.orange)
                        }
                    }
                
                Text(color.rawValue)
                    .font(.system(size: 12, weight: .medium))
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
    
    This book will guide you through complex grammatical structures that are essential for advanced English proficiency.
    """
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.orange)
                
                Text("預覽效果")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
            }
            
            // 預覽區域
            VStack {
                Text(previewText)
                    .font(.system(size: CGFloat(settings.fontSize)))
                    .lineSpacing(CGFloat(settings.lineSpacing - 1.0) * CGFloat(settings.fontSize))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
