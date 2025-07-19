// AuthenticationComponents.swift

import SwiftUI

// MARK: - 認證專用卡片組件
struct ClaudeAuthCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        ModernCard(title: title, icon: icon, style: .elevated) {
            content
        }
    }
}

// MARK: - 輸入欄位組件
struct ClaudeAuthInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        ModernInputField(
            title: title,
            placeholder: placeholder,
            text: $text,
            keyboardType: keyboardType
        )
    }
}

// MARK: - 密碼輸入欄位組件
struct ClaudeAuthPasswordField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    
    var body: some View {
        ModernInputField(
            title: title,
            placeholder: placeholder,
            text: $text,
            isSecure: true,
            showPassword: $showPassword
        )
    }
}

// MARK: - 選擇器欄位組件
struct ClaudeAuthPickerField: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        ModernPickerField(
            title: title,
            selection: $selection,
            options: options
        )
    }
}

// MARK: - 認證按鈕組件
struct ClaudeAuthButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        ModernButton(
            title,
            style: .primary,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
        .padding(.horizontal, ModernSpacing.md)
    }
}

// MARK: - 錯誤訊息組件
struct ClaudeErrorBox: View {
    let message: String
    
    var body: some View {
        ModernStatusBox(message: message, type: .error)
    }
}

// MARK: - 警告訊息組件
struct ClaudeWarningBox: View {
    let message: String
    
    var body: some View {
        ModernStatusBox(message: message, type: .warning)
    }
}

// MARK: - 認證容器視圖
struct AuthenticationContainerView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingRegister = false
    
    var body: some View {
        NavigationView {
            VStack {
                if showingRegister {
                    RegisterView()
                        .transition(.slide)
                } else {
                    LoginView()
                        .transition(.slide)
                }
            }
            .animation(.easeInOut, value: showingRegister)
        }
        .environmentObject(authManager)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowRegister"))) { _ in
            showingRegister = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowLogin"))) { _ in
            showingRegister = false
        }
    }
}

#Preview("登入畫面") {
    LoginView()
        .environmentObject(AuthenticationManager())
}

#Preview("註冊畫面") {
    RegisterView()
        .environmentObject(AuthenticationManager())
}

#Preview("認證容器") {
    AuthenticationContainerView()
}