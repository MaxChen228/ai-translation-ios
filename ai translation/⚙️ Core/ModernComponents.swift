// ModernComponents.swift - 現代美學組件庫

import SwiftUI

// MARK: - 現代卡片組件
struct ModernCard<Content: View>: View {
    let title: String?
    let icon: String?
    let style: ModernCardStyle
    @ViewBuilder let content: Content
    
    init(
        title: String? = nil,
        icon: String? = nil,
        style: ModernCardStyle = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.lg) {
            if let title = title {
                HStack(spacing: ModernSpacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.appHeadline(for: "卡片圖示"))
                            .foregroundStyle(Color.modernAccent)
                    }
                    
                    Text(title)
                        .font(.appTitle3(for: "卡片標題"))
                        .foregroundStyle(Color.modernTextPrimary)
                }
            }
            
            content
        }
        .padding(ModernSpacing.lg)
        .modernCard(style)
        .padding(.horizontal, ModernSpacing.md)
    }
}

// MARK: - 現代按鈕組件
struct ModernButton: View {
    let title: String
    let icon: String?
    let style: ModernButtonStyle
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ModernButtonStyle = .primary,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ModernSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.textColor))
                        .accessibilityLabel("載入中")
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.appBody())
                        .accessibilityHidden(true) // 避免重複讀取圖示
                }
                
                Text(title)
                    .font(.appBody(for: "按鈕文字"))
                    .fontWeight(.medium)
            }
            .foregroundStyle(style.textColor)
            .frame(maxWidth: .infinity)
            .modernButton(style)
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled && !isLoading ? 1.0 : 0.6)
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "正在處理請求" : "輕點以執行操作")
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
    }
}

// MARK: - 現代輸入框組件
struct ModernInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    @State private var internalShowPassword: Bool = false
    var showPassword: Binding<Bool>?
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        showPassword: Binding<Bool>? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.showPassword = showPassword
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.sm) {
            Text(title)
                .font(.appCallout(for: "輸入欄位標題"))
                .foregroundStyle(Color.modernTextPrimary)
                .accessibilityAddTraits(.isHeader)
            
            HStack {
                Group {
                    if isSecure && !(showPassword?.wrappedValue ?? internalShowPassword) {
                        SecureField(placeholder, text: $text)
                            .accessibilityLabel("\(title)，安全輸入欄位")
                            .accessibilityHint("請輸入您的\(title.lowercased())")
                    } else {
                        TextField(placeholder, text: $text)
                            .accessibilityLabel("\(title)，輸入欄位")
                            .accessibilityHint("請輸入您的\(title.lowercased())")
                    }
                }
                .font(.appBody(for: "輸入內容"))
                .foregroundStyle(Color.modernTextPrimary)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .accessibilityValue(text.isEmpty ? "空白" : text)
                
                if isSecure {
                    Button(action: {
                        if let showPasswordBinding = showPassword {
                            showPasswordBinding.wrappedValue.toggle()
                        } else {
                            internalShowPassword.toggle()
                        }
                    }) {
                        let isShowing = showPassword?.wrappedValue ?? internalShowPassword
                        Image(systemName: isShowing ? "eye.slash" : "eye")
                            .font(.appCallout())
                            .foregroundStyle(Color.modernTextSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel((showPassword?.wrappedValue ?? internalShowPassword) ? "隱藏密碼" : "顯示密碼")
                    .accessibilityHint("輕點以切換密碼顯示狀態")
                    .accessibilityAddTraits(.isButton)
                }
            }
            .modernInput(isFocused: isFocused)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - 現代選擇器組件
struct ModernPickerField: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.sm) {
            Text(title)
                .font(.appCallout(for: "選擇器標題"))
                .foregroundStyle(Color.modernTextPrimary)
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection)
                        .font(.appBody(for: "選擇內容"))
                        .foregroundStyle(Color.modernTextPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.appCaption())
                        .foregroundStyle(Color.modernTextSecondary)
                }
                .padding(ModernSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: ModernRadius.sm)
                        .fill(Color.modernSurface)
                        .overlay {
                            RoundedRectangle(cornerRadius: ModernRadius.sm)
                                .stroke(Color.modernBorder, lineWidth: 1)
                        }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 現代狀態組件
struct ModernStatusBox: View {
    let message: String
    let type: StatusType
    
    enum StatusType {
        case success, warning, error, info
        
        var color: Color {
            switch self {
            case .success: return .modernSuccess
            case .warning: return .modernWarning
            case .error: return .modernError
            case .info: return .modernSpecial
            }
        }
        
        var backgroundColor: Color {
            return color.opacity(0.1)
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: ModernSpacing.sm) {
            Image(systemName: type.icon)
                .font(.appSubheadline())
                .foregroundStyle(type.color)
            
            Text(message)
                .font(.appSubheadline(for: "狀態訊息"))
                .foregroundStyle(type.color)
                .lineSpacing(2)
        }
        .padding(ModernSpacing.sm + 2)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.xs)
                .fill(type.backgroundColor)
                .overlay {
                    RoundedRectangle(cornerRadius: ModernRadius.xs)
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

// MARK: - 現代分隔器組件
struct ModernDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.modernDivider)
            .frame(height: 1)
    }
}

// MARK: - 現代載入指示器
struct ModernLoadingView: View {
    let message: String?
    
    init(_ message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: ModernSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .modernAccent))
            
            if let message = message {
                Text(message)
                    .font(.appBody(for: "載入訊息"))
                    .foregroundStyle(Color.modernTextSecondary)
            }
        }
        .padding(ModernSpacing.xl)
        .modernCard(.elevated)
    }
}

// MARK: - 現代空狀態組件
struct ModernEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: ModernSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.modernTextTertiary)
            
            VStack(spacing: ModernSpacing.sm) {
                Text(title)
                    .font(.appTitle3(for: "空狀態標題"))
                    .foregroundStyle(Color.modernTextPrimary)
                
                Text(message)
                    .font(.appBody(for: "空狀態訊息"))
                    .foregroundStyle(Color.modernTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                ModernButton(actionTitle, style: .secondary, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(ModernSpacing.xl)
    }
}