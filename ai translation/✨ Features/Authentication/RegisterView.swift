// RegisterView.swift

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var nativeLanguage = "中文"
    @State private var targetLanguage = "英文"
    @State private var learningLevel = "初級"
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    private let languages = ["中文", "英文", "日文", "韓文", "法文", "德文", "西班牙文"]
    private let levels = ["初級", "中級", "高級"]
    
    var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 標題區域
                    VStack(spacing: 8) {
                        Text("建立新帳號")
                            .font(.appLargeTitle(for: "註冊標題"))
                            .foregroundStyle(.primary)
                        
                        Text("設定您的個人學習資料")
                            .font(.appSubheadline(for: "註冊描述"))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // 基本資料
                    ClaudeAuthCard(title: "基本資料", icon: "person.fill") {
                        VStack(spacing: 20) {
                            ClaudeAuthInputField(
                                title: "使用者名稱",
                                placeholder: "請輸入使用者名稱",
                                text: $username
                            )
                            
                            ClaudeAuthInputField(
                                title: "顯示名稱（選填）",
                                placeholder: "請輸入顯示名稱",
                                text: $displayName
                            )
                            
                            ClaudeAuthInputField(
                                title: "電子郵件",
                                placeholder: "請輸入您的電子郵件",
                                text: $email,
                                keyboardType: .emailAddress
                            )
                        }
                    }
                    
                    // 密碼設定
                    ClaudeAuthCard(title: "密碼設定", icon: "lock.fill") {
                        VStack(spacing: 20) {
                            ClaudeAuthPasswordField(
                                title: "密碼",
                                placeholder: "請輸入密碼（至少6位字符）",
                                text: $password,
                                showPassword: $showPassword
                            )
                            
                            ClaudeAuthPasswordField(
                                title: "確認密碼",
                                placeholder: "請再次輸入密碼",
                                text: $confirmPassword,
                                showPassword: $showConfirmPassword
                            )
                            
                            if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                                ClaudeErrorBox(message: "密碼不匹配")
                            }
                            
                            if !password.isEmpty && password.count < 6 {
                                ClaudeWarningBox(message: "密碼長度至少需要6位字符")
                            }
                        }
                    }
                    
                    // 學習偏好
                    ClaudeAuthCard(title: "學習偏好（選填）", icon: "graduationcap.fill") {
                        VStack(spacing: 20) {
                            ClaudeAuthPickerField(
                                title: "母語",
                                selection: $nativeLanguage,
                                options: languages
                            )
                            
                            ClaudeAuthPickerField(
                                title: "目標語言",
                                selection: $targetLanguage,
                                options: languages
                            )
                            
                            ClaudeAuthPickerField(
                                title: "學習程度",
                                selection: $learningLevel,
                                options: levels
                            )
                        }
                    }
                    
                    // 錯誤訊息
                    if let errorMessage = authManager.errorMessage {
                        ClaudeErrorBox(message: errorMessage)
                    }
                    
                    // 註冊按鈕
                    ClaudeAuthButton(
                        title: "建立帳號",
                        isLoading: authManager.isLoading,
                        isEnabled: isFormValid
                    ) {
                        Task {
                            authManager.clearError()
                            await authManager.register(
                                username: username,
                                email: email,
                                password: password,
                                displayName: displayName.isEmpty ? nil : displayName,
                                nativeLanguage: nativeLanguage,
                                targetLanguage: targetLanguage,
                                learningLevel: learningLevel
                            )
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回登入") {
                        NotificationCenter.default.post(name: NSNotification.Name("ShowLogin"), object: nil)
                    }
                    .foregroundStyle(Color.orange)
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthenticationManager())
}