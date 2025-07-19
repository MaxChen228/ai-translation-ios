// LoginView.swift

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isShowingRegister = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Logo 和標題區域
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(Color.orange)
                        .padding(.top, 40)
                    
                    VStack(spacing: 8) {
                        Text("AI 翻譯學習")
                            .font(.appLargeTitle(for: "應用標題"))
                            .foregroundStyle(.primary)
                        
                        Text("登入您的帳號開始個人化學習之旅")
                            .font(.appSubheadline(for: "登入描述"))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                
                // 登入表單
                ClaudeAuthCard(title: "登入", icon: "person.crop.circle") {
                    VStack(spacing: 20) {
                        // Email 輸入欄
                        ClaudeAuthInputField(
                            title: "電子郵件",
                            placeholder: "請輸入您的電子郵件",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        // 密碼輸入欄
                        ClaudeAuthPasswordField(
                            title: "密碼",
                            placeholder: "請輸入您的密碼",
                            text: $password,
                            showPassword: $showPassword
                        )
                        
                        // 錯誤訊息
                        if let errorMessage = authManager.errorMessage {
                            ClaudeErrorBox(message: errorMessage)
                        }
                        
                        // 登入按鈕
                        ClaudeAuthButton(
                            title: "登入",
                            isLoading: authManager.isLoading,
                            isEnabled: !email.isEmpty && !password.isEmpty
                        ) {
                            Task {
                                authManager.clearError()
                                await authManager.login(email: email, password: password)
                            }
                        }
                    }
                }
                
                // 其他選項
                VStack(spacing: 20) {
                    // 訪客模式按鈕
                    Button(action: {
                        print("🔴 點擊訪客模式按鈕")
                        authManager.enterGuestMode()
                        print("🔴 按鈕動作完成")
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "eye")
                                .font(.appCallout(for: "訪客圖示"))
                                .foregroundStyle(Color.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("訪客體驗")
                                    .font(.appCallout(for: "訪客按鈕"))
                                    .foregroundStyle(Color.blue)
                                
                                Text("無需註冊，立即開始學習")
                                    .font(.appCaption(for: "訪客說明"))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .font(.appCaption(for: "箭頭"))
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    
                    // 分隔線
                    HStack {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                        
                        Text("或")
                            .font(.appCaption(for: "分隔符"))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    
                    // 註冊連結
                    Button(action: {
                        NotificationCenter.default.post(name: NSNotification.Name("ShowRegister"), object: nil)
                    }) {
                        HStack(spacing: 8) {
                            Text("還沒有帳號？")
                                .font(.appSubheadline(for: "註冊提示"))
                                .foregroundStyle(.secondary)
                            
                            Text("立即註冊")
                                .font(.appSubheadline(for: "註冊連結"))
                                .foregroundStyle(Color.orange)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}