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
    let size: ButtonSize
    let iconPosition: IconPosition
    let isLoading: Bool
    let isEnabled: Bool
    let hapticFeedback: Bool
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    @State private var isHovered: Bool = false
    
    enum ButtonSize {
        case small, medium, large
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return ModernSpacing.sm
            case .medium: return ModernSpacing.md
            case .large: return ModernSpacing.lg
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return ModernSpacing.xs + 2
            case .medium: return ModernSpacing.sm + 2
            case .large: return ModernSpacing.md
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return .appCaption()
            case .medium: return .appBody()
            case .large: return .appSubheadline()
            }
        }
    }
    
    enum IconPosition {
        case leading, trailing
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ModernButtonStyle = .primary,
        size: ButtonSize = .medium,
        iconPosition: IconPosition = .leading,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        hapticFeedback: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.iconPosition = iconPosition
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.hapticFeedback = hapticFeedback
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // 觸覺反饋
            if hapticFeedback && isEnabled && !isLoading {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
            
            action()
        }) {
            HStack(spacing: ModernSpacing.sm) {
                if iconPosition == .leading {
                    iconView
                }
                
                Text(title)
                    .font(size.fontSize)
                    .fontWeight(.medium)
                
                if iconPosition == .trailing {
                    iconView
                }
            }
            .foregroundStyle(currentTextColor)
            .frame(maxWidth: style == .link ? nil : .infinity)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background {
                if style != .link {
                    RoundedRectangle(cornerRadius: ModernRadius.sm)
                        .fill(currentBackgroundColor)
                        .overlay {
                            if style.hasBorder {
                                RoundedRectangle(cornerRadius: ModernRadius.sm)
                                    .stroke(style.borderColor, lineWidth: 1)
                            }
                        }
                }
            }
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(.plain)
        
        // 增強的視覺反饋
        .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
        .opacity(isEnabled && !isLoading ? (isPressed ? 0.8 : 1.0) : 0.6)
        .brightness(isPressed ? -0.05 : 0)
        
        // 統一動畫系統
        .animation(MicroInteractions.buttonTap(), value: isPressed)
        .animation(MicroInteractions.cardHover(), value: isHovered)
        
        // 交互狀態管理
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isEnabled && !isLoading {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .onHover { hovering in
            if isEnabled && !isLoading {
                isHovered = hovering
            }
        }
        
        // 無障礙設定
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "正在處理請求" : "輕點以執行操作")
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
        .accessibilityValue(isPressed ? "已按下" : "")
    }
    
    // 動態顏色計算
    private var currentTextColor: Color {
        if isPressed && style != .link {
            return style.textColor.opacity(0.9)
        }
        return style.textColor
    }
    
    private var currentBackgroundColor: Color {
        if isPressed {
            switch style {
            case .primary:
                return Color.modernAccent.opacity(0.9)
            case .secondary:
                return Color.modernAccentSoft.opacity(1.2)
            case .special:
                return Color.modernSpecial.opacity(0.9)
            default:
                return style.backgroundColor
            }
        } else if isHovered && style != .tertiary && style != .link {
            switch style {
            case .primary:
                return Color.modernAccent.opacity(1.05)
            case .secondary:
                return Color.modernAccentSoft.opacity(1.1)
            case .special:
                return Color.modernSpecial.opacity(1.05)
            default:
                return style.backgroundColor
            }
        }
        return style.backgroundColor
    }
    
    @ViewBuilder
    private var iconView: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(size == .small ? 0.7 : 0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: style.textColor))
                .accessibilityLabel("載入中")
        } else if let icon = icon {
            Image(systemName: icon)
                .font(size.fontSize)
                .symbolEffect(.bounce.byLayer, options: .nonRepeating, value: isPressed)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - 現代輸入框組件
struct ModernInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var isMultiline: Bool = false
    var lineLimit: Int = 3
    var maxCharacters: Int?
    var errorMessage: String?
    var validator: ((String) -> String?)?
    @State private var internalShowPassword: Bool = false
    var showPassword: Binding<Bool>?
    @FocusState private var isFocused: Bool
    @State private var internalError: String?
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        isMultiline: Bool = false,
        lineLimit: Int = 3,
        maxCharacters: Int? = nil,
        errorMessage: String? = nil,
        validator: ((String) -> String?)? = nil,
        showPassword: Binding<Bool>? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.isMultiline = isMultiline
        self.lineLimit = lineLimit
        self.maxCharacters = maxCharacters
        self.errorMessage = errorMessage
        self.validator = validator
        self.showPassword = showPassword
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernSpacing.sm) {
            HStack {
                Text(title)
                    .font(.appCallout(for: "輸入欄位標題"))
                    .foregroundStyle(hasError ? Color.modernError : Color.modernTextPrimary)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                if let maxCharacters = maxCharacters {
                    Text("\(text.count)/\(maxCharacters)")
                        .font(.appCaption2())
                        .foregroundStyle(text.count > maxCharacters ? Color.modernError : Color.modernTextTertiary)
                }
            }
            
            VStack(spacing: ModernSpacing.xs) {
                if isMultiline {
                    TextEditor(text: $text)
                        .font(.appBody(for: "輸入內容"))
                        .foregroundStyle(Color.modernTextPrimary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 80, maxHeight: CGFloat(lineLimit) * 24)
                        .focused($isFocused)
                        .onChange(of: text) { newValue in
                            validateInput(newValue)
                        }
                        .modernInput(isFocused: isFocused, hasError: hasError)
                } else {
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
                        .onChange(of: text) { newValue in
                            validateInput(newValue)
                        }
                        
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
                    .modernInput(isFocused: isFocused, hasError: hasError)
                }
                
                if let error = displayedError {
                    HStack(spacing: ModernSpacing.xs) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.appCaption2())
                        Text(error)
                            .font(.appCaption(for: error))
                    }
                    .foregroundStyle(Color.modernError)
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private var hasError: Bool {
        displayedError != nil
    }
    
    private var displayedError: String? {
        errorMessage ?? internalError
    }
    
    private func validateInput(_ value: String) {
        if let validator = validator {
            internalError = validator(value)
        }
        
        if let maxCharacters = maxCharacters, value.count > maxCharacters {
            text = String(value.prefix(maxCharacters))
        }
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
    let style: LoadingStyle
    
    enum LoadingStyle {
        case card, fullscreen
    }
    
    init(_ message: String? = nil, style: LoadingStyle = .card) {
        self.message = message
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: ModernSpacing.lg) {
            ProgressView()
                .scaleEffect(style == .fullscreen ? 1.5 : 1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .modernAccent))
            
            if let message = message {
                Text(message)
                    .font(style == .fullscreen ? .appSubheadline(for: "載入訊息") : .appBody(for: "載入訊息"))
                    .foregroundStyle(Color.modernTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(style == .fullscreen ? ModernSpacing.xxl : ModernSpacing.xl)
        .frame(maxWidth: .infinity)
        .if(style == .card) { view in
            view.modernCard(.elevated)
        }
        .if(style == .fullscreen) { view in
            view.background(Color.clear)
        }
    }
}

// MARK: - View 擴展助手
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
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
                .font(.appLargeTitle())
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

// MARK: - 現代搜尋欄組件
struct ModernSearchBar: View {
    @Binding var text: String
    var placeholder: String = "搜尋..."
    var onSearch: ((String) -> Void)?
    var onClear: (() -> Void)?
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: ModernSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.appBody())
                .foregroundStyle(Color.modernTextSecondary)
            
            TextField(placeholder, text: $text)
                .font(.appBody(for: "搜尋內容"))
                .foregroundStyle(Color.modernTextPrimary)
                .focused($isFocused)
                .onSubmit {
                    onSearch?(text)
                }
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onClear?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.appBody())
                        .foregroundStyle(Color.modernTextSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清除搜尋")
            }
        }
        .padding(ModernSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.sm)
                .fill(Color.modernSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: ModernRadius.sm)
                        .stroke(isFocused ? Color.modernAccent : Color.modernBorder, lineWidth: isFocused ? 1.5 : 1)
                }
        }
        .animation(MicroInteractions.inputFocus(), value: isFocused)
    }
}

// MARK: - 現代開關組件
struct ModernToggle: View {
    @Binding var isOn: Bool
    var label: String?
    var onColor: Color = .modernAccent
    var isEnabled: Bool = true
    
    var body: some View {
        HStack {
            if let label = label {
                Text(label)
                    .font(.appBody(for: label))
                    .foregroundStyle(isEnabled ? Color.modernTextPrimary : Color.modernTextTertiary)
            }
            
            Spacer()
            
            ZStack {
                Capsule()
                    .fill(isOn ? onColor : Color.modernBorder)
                    .frame(width: 48, height: 28)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .offset(x: isOn ? 10 : -10)
                    .animation(MicroInteractions.stateChange(), value: isOn)
            }
            .onTapGesture {
                if isEnabled {
                    isOn.toggle()
                }
            }
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? "開啟" : "關閉")
        .accessibilityHint("輕點以切換開關狀態")
    }
}

// MARK: - 現代警告對話框組件
struct ModernAlert: View {
    let title: String
    let message: String?
    let primaryButton: AlertButton
    let secondaryButton: AlertButton?
    let style: AlertStyle
    
    struct AlertButton {
        let title: String
        let action: () -> Void
        let role: ButtonRole?
        
        init(title: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
            self.title = title
            self.role = role
            self.action = action
        }
        
        enum ButtonRole {
            case cancel, destructive
        }
    }
    
    enum AlertStyle {
        case info, warning, error, success
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .info: return .modernSpecial
            case .warning: return .modernWarning
            case .error: return .modernError
            case .success: return .modernSuccess
            }
        }
    }
    
    var body: some View {
        VStack(spacing: ModernSpacing.lg) {
            Image(systemName: style.icon)
                .font(.appLargeTitle())
                .foregroundStyle(style.color)
            
            VStack(spacing: ModernSpacing.sm) {
                Text(title)
                    .font(.appTitle3(for: title))
                    .foregroundStyle(Color.modernTextPrimary)
                    .multilineTextAlignment(.center)
                
                if let message = message {
                    Text(message)
                        .font(.appBody(for: message))
                        .foregroundStyle(Color.modernTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            HStack(spacing: ModernSpacing.md) {
                if let secondaryButton = secondaryButton {
                    ModernButton(
                        secondaryButton.title,
                        style: .secondary,
                        action: secondaryButton.action
                    )
                }
                
                ModernButton(
                    primaryButton.title,
                    style: primaryButton.role == .destructive ? .primary : .primary,
                    action: primaryButton.action
                )
            }
        }
        .padding(ModernSpacing.xl)
        .background(Color.modernSurfaceElevated)
        .cornerRadius(ModernRadius.lg)
        .modernShadow(ModernShadow.medium)
        .frame(maxWidth: 320)
    }
}

// MARK: - 現代輕量級提示組件
struct ModernToast: View {
    let message: String
    let type: ToastType
    let position: ToastPosition
    @Binding var isShowing: Bool
    
    enum ToastType {
        case success, info, warning, error
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .modernSuccess
            case .info: return .modernSpecial
            case .warning: return .modernWarning
            case .error: return .modernError
            }
        }
    }
    
    enum ToastPosition {
        case top, bottom
    }
    
    var body: some View {
        HStack(spacing: ModernSpacing.sm) {
            Image(systemName: type.icon)
                .font(.appBody())
                .foregroundStyle(type.color)
            
            Text(message)
                .font(.appBody(for: message))
                .foregroundStyle(Color.modernTextPrimary)
            
            Spacer()
            
            Button(action: {
                withAnimation(MicroInteractions.stateChange()) {
                    isShowing = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.appCaption())
                    .foregroundStyle(Color.modernTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(ModernSpacing.md)
        .background(Color.modernSurfaceElevated)
        .cornerRadius(ModernRadius.sm)
        .modernShadow(ModernShadow.medium)
        .padding(.horizontal, ModernSpacing.md)
        .transition(.move(edge: position == .top ? .top : .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(MicroInteractions.stateChange()) {
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - 現代列表項目組件
struct ModernListItem<Accessory: View>: View {
    let icon: String?
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let accessory: (() -> Accessory)?
    let action: (() -> Void)?
    
    init(
        icon: String? = nil,
        title: String,
        subtitle: String? = nil,
        isSelected: Bool = false,
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() },
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.accessory = accessory
        self.action = action
    }
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: ModernSpacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.appBody())
                        .foregroundStyle(Color.modernAccent)
                        .frame(width: 24)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.appBody(for: title))
                        .foregroundStyle(Color.modernTextPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.appCaption(for: subtitle))
                            .foregroundStyle(Color.modernTextSecondary)
                    }
                }
                
                Spacer()
                
                if let accessory = accessory {
                    accessory()
                }
            }
            .padding(ModernSpacing.md)
            .background(isSelected ? Color.modernAccentSoft : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 現代徽章組件
struct ModernBadge: View {
    let value: String
    let style: BadgeStyle
    
    enum BadgeStyle {
        case standard, accent, success, warning, error
        
        var backgroundColor: Color {
            switch self {
            case .standard: return .modernTextSecondary
            case .accent: return .modernAccent
            case .success: return .modernSuccess
            case .warning: return .modernWarning
            case .error: return .modernError
            }
        }
    }
    
    var body: some View {
        Text(value)
            .font(.appCaption2())
            .foregroundStyle(.white)
            .padding(.horizontal, ModernSpacing.sm)
            .padding(.vertical, 2)
            .background(style.backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
    }
}

// MARK: - 現代分段控制器組件
struct ModernSegmentedControl<SelectionValue: Hashable>: View {
    @Binding var selection: SelectionValue
    let options: [(value: SelectionValue, label: String, icon: String?)]
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                Button(action: {
                    withAnimation(AnimationCurves.gentleSpring) {
                        selection = option.value
                    }
                }) {
                    HStack(spacing: ModernSpacing.xs) {
                        if let icon = option.icon {
                            Image(systemName: icon)
                                .font(.appCaption())
                        }
                        
                        Text(option.label)
                            .font(.appBody(for: option.label))
                    }
                    .foregroundStyle(selection == option.value ? Color.white : Color.modernTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ModernSpacing.sm)
                    .background {
                        if selection == option.value {
                            RoundedRectangle(cornerRadius: ModernRadius.sm - 2)
                                .fill(Color.modernAccent)
                                .matchedGeometryEffect(id: "selection", in: animation)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.modernSurface)
        .cornerRadius(ModernRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: ModernRadius.sm)
                .stroke(Color.modernBorder, lineWidth: 1)
        )
    }
}