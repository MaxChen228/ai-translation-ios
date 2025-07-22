// LoginView.swift

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isShowingRegister = false
    @FocusState private var focusField: LoginField?
    
    var body: some View {
        ScrollView {
            VStack(spacing: ModernSpacing.xxl) {
                // Logo 和標題區域
                VStack(spacing: ModernSpacing.md) {
                    Image(systemName: "brain.head.profile")
                        .font(.appLargeTitle())
                        .foregroundStyle(Color.modernAccent)
                        .padding(.top, ModernSpacing.xl + 8)
                    
                    VStack(spacing: ModernSpacing.sm) {
                        Text("AI 翻譯學習")
                            .font(.appLargeTitle(for: "應用標題"))
                            .foregroundStyle(Color.modernTextPrimary)
                        
                        Text("登入您的帳號開始個人化學習之旅")
                            .font(.appSubheadline(for: "登入描述"))
                            .foregroundStyle(Color.modernTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, ModernSpacing.lg)
                
                // 登入表單
                ModernCard(title: "登入", icon: "person.crop.circle", style: .elevated) {
                    VStack(spacing: ModernSpacing.lg) {
                        // Email 輸入欄
                        ModernInputField(
                            title: "電子郵件",
                            placeholder: "請輸入您的電子郵件",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        // 密碼輸入欄
                        ModernInputField(
                            title: "密碼",
                            placeholder: "請輸入您的密碼",
                            text: $password,
                            isSecure: true,
                            showPassword: $showPassword
                        )
                        
                        // 錯誤訊息
                        if let errorMessage = authManager.errorMessage {
                            ModernStatusBox(message: errorMessage, type: .error)
                        }
                        
                        // 登入按鈕
                        ModernButton(
                            "登入",
                            style: .primary,
                            isLoading: authManager.isLoading,
                            isEnabled: !email.isEmpty && !password.isEmpty
                        ) {
                            Task {
                                authManager.clearError()
                                await authManager.login(email: email, password: password)
                            }
                        }
                        .padding(.horizontal, ModernSpacing.md)
                    }
                }
                
                // 其他選項
                VStack(spacing: ModernSpacing.lg) {
                    // 訪客模式按鈕
                    Button(action: {
                        Task {
                            await authManager.registerAnonymously()
                        }
                    }) {
                        HStack(spacing: ModernSpacing.sm) {
                            Image(systemName: "eye")
                                .font(.appCallout(for: "訪客圖示"))
                                .foregroundStyle(Color.modernSpecial)
                            
                            VStack(alignment: .leading, spacing: ModernSpacing.xs) {
                                Text("訪客體驗")
                                    .font(.appCallout(for: "訪客按鈕"))
                                    .foregroundStyle(Color.modernSpecial)
                                
                                Text("無需註冊，立即開始學習")
                                    .font(.appCaption(for: "訪客說明"))
                                    .foregroundStyle(Color.modernTextSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .font(.appCaption(for: "箭頭"))
                                .foregroundStyle(Color.modernTextSecondary)
                        }
                        .padding(ModernSpacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: ModernRadius.sm)
                                .fill(Color.modernSpecialSoft)
                                .overlay {
                                    RoundedRectangle(cornerRadius: ModernRadius.sm)
                                        .stroke(Color.modernSpecial.opacity(0.3), lineWidth: 1)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, ModernSpacing.lg)
                    
                    // 分隔線
                    HStack {
                        ModernDivider()
                        
                        Text("或")
                            .font(.appCaption(for: "分隔符"))
                            .foregroundStyle(Color.modernTextSecondary)
                            .padding(.horizontal, ModernSpacing.md)
                        
                        ModernDivider()
                    }
                    .padding(.horizontal, ModernSpacing.lg)
                    
                    // 註冊連結
                    Button(action: {
                        NotificationCenter.default.post(name: NSNotification.Name("ShowRegister"), object: nil)
                    }) {
                        HStack(spacing: ModernSpacing.sm) {
                            Text("還沒有帳號？")
                                .font(.appSubheadline(for: "註冊提示"))
                                .foregroundStyle(Color.modernTextSecondary)
                            
                            Text("立即註冊")
                                .font(.appSubheadline(for: "註冊連結"))
                                .foregroundStyle(Color.modernAccent)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: ModernSpacing.xl + 8)
            }
        }
        .background(Color.modernBackground)
        .onTapGesture {
            focusField = nil
        }
    }
    
}

enum LoginField: Hashable {
    case email, password
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}