// AuthenticationComponents.swift

import SwiftUI

// MARK: - 認證專用卡片組件
struct ClaudeAuthCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.appHeadline(for: "認證圖示"))
                    .foregroundStyle(Color.orange)
                
                Text(title)
                    .font(.appTitle3(for: "認證標題"))
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
        .padding(.horizontal, 20)
    }
}

// MARK: - 輸入欄位組件
struct ClaudeAuthInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appCallout(for: "輸入欄位標題"))
                .foregroundStyle(.primary)
            
            TextField(placeholder, text: $text)
                .font(.appBody(for: "輸入內容"))
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: text.isEmpty ? 0 : 1)
                        }
                }
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }
}

// MARK: - 密碼輸入欄位組件
struct ClaudeAuthPasswordField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appCallout(for: "密碼欄位標題"))
                .foregroundStyle(.primary)
            
            HStack {
                Group {
                    if showPassword {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .font(.appBody(for: "密碼內容"))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.appCallout(for: "密碼顯示"))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: text.isEmpty ? 0 : 1)
                    }
            }
        }
    }
}

// MARK: - 選擇器欄位組件
struct ClaudeAuthPickerField: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appCallout(for: "選擇器標題"))
                .foregroundStyle(.primary)
            
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
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.appCaption(for: "下拉箭頭"))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 認證按鈕組件
struct ClaudeAuthButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                Text(title)
                    .font(.appHeadline(for: "認證按鈕"))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? Color.orange : Color(.systemGray4))
            }
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
}

// MARK: - 錯誤訊息組件
struct ClaudeErrorBox: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.appSubheadline(for: "錯誤圖示"))
                .foregroundStyle(.red)
            
            Text(message)
                .font(.appSubheadline(for: "錯誤訊息"))
                .foregroundStyle(.red)
                .lineSpacing(1)
        }
        .padding(12)
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

// MARK: - 警告訊息組件
struct ClaudeWarningBox: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.appSubheadline(for: "警告圖示"))
                .foregroundStyle(.orange)
            
            Text(message)
                .font(.appSubheadline(for: "警告訊息"))
                .foregroundStyle(.orange)
                .lineSpacing(1)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

// MARK: - 認證容器視圖
struct AuthenticationContainerView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        LoginView()
            .environmentObject(authManager)
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