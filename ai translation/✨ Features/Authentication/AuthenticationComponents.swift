// AuthenticationComponents.swift

import SwiftUI

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