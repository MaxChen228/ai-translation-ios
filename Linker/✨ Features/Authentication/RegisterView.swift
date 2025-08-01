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
    @FocusState private var focusField: RegisterField?
    
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
                VStack(spacing: ModernSpacing.lg) {
                    // 標題區域
                    VStack(spacing: ModernSpacing.sm) {
                        Text("建立新帳號")
                            .font(.appLargeTitle(for: "註冊標題"))
                            .foregroundStyle(Color.modernTextPrimary)
                        
                        Text("設定您的個人學習資料")
                            .font(.appSubheadline(for: "註冊描述"))
                            .foregroundStyle(Color.modernTextSecondary)
                    }
                    .padding(.top, ModernSpacing.lg)
                    
                    // 基本資料
                    ModernCard(title: "基本資料", icon: "person.fill", style: .elevated) {
                        VStack(spacing: ModernSpacing.lg) {
                            ModernInputField(
                                title: "使用者名稱",
                                placeholder: "請輸入使用者名稱",
                                text: $username
                            )
                            
                            ModernInputField(
                                title: "顯示名稱（選填）",
                                placeholder: "請輸入顯示名稱",
                                text: $displayName
                            )
                            
                            ModernInputField(
                                title: "電子郵件",
                                placeholder: "請輸入您的電子郵件",
                                text: $email,
                                keyboardType: .emailAddress
                            )
                        }
                    }
                    
                    // 密碼設定
                    ModernCard(title: "密碼設定", icon: "lock.fill", style: .elevated) {
                        VStack(spacing: ModernSpacing.lg) {
                            ModernInputField(
                                title: "密碼",
                                placeholder: "請輸入密碼（至少6位字符）",
                                text: $password,
                                isSecure: true,
                                showPassword: $showPassword
                            )
                            
                            ModernInputField(
                                title: "確認密碼",
                                placeholder: "請再次輸入密碼",
                                text: $confirmPassword,
                                isSecure: true,
                                showPassword: $showConfirmPassword
                            )
                            
                            if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                                ModernStatusBox(message: "密碼不匹配", type: .error)
                            }
                            
                            if !password.isEmpty && password.count < 6 {
                                ModernStatusBox(message: "密碼長度至少需要6位字符", type: .warning)
                            }
                        }
                    }
                    
                    // 學習偏好
                    ModernCard(title: "學習偏好（選填）", icon: "graduationcap.fill", style: .elevated) {
                        VStack(spacing: ModernSpacing.lg) {
                            ModernPickerField(
                                title: "母語",
                                selection: $nativeLanguage,
                                options: languages
                            )
                            
                            ModernPickerField(
                                title: "目標語言",
                                selection: $targetLanguage,
                                options: languages
                            )
                            
                            ModernPickerField(
                                title: "學習程度",
                                selection: $learningLevel,
                                options: levels
                            )
                        }
                    }
                    
                    // 錯誤訊息
                    if let errorMessage = authManager.errorMessage {
                        ModernStatusBox(message: errorMessage, type: .error)
                    }
                    
                    // 註冊按鈕
                    ModernButton(
                        "建立帳號",
                        style: .primary,
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
                    .padding(.horizontal, ModernSpacing.md)
                    
                    Spacer(minLength: ModernSpacing.xl + 8)
                }
                .padding(ModernSpacing.lg)
            }
            .background(Color.modernBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回登入") {
                        NotificationCenter.default.post(name: NSNotification.Name("ShowLogin"), object: nil)
                    }
                    .foregroundStyle(Color.modernAccent)
                }
            }
            .onTapGesture {
                focusField = nil
            }
        }
    }
    
}

enum RegisterField: Hashable {
    case username, email, password, confirmPassword, displayName
}

#Preview {
    RegisterView()
        .environmentObject(AuthenticationManager())
}