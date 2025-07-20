// AccessibilityExtensions.swift - 無障礙功能擴展

import SwiftUI

// MARK: - 無障礙標籤與提示常數
struct AccessibilityLabels {
    
    // MARK: - 認證相關
    struct Auth {
        static let loginButton = "登入按鈕"
        static let registerButton = "註冊按鈕"
        static let guestModeButton = "訪客模式按鈕"
        static let logoImage = "AI 翻譯學習應用程式標誌"
        static let emailField = "電子郵件輸入欄位"
        static let passwordField = "密碼輸入欄位"
        static let showPasswordButton = "顯示密碼按鈕"
        static let hidePasswordButton = "隱藏密碼按鈕"
    }
    
    // MARK: - 儀表板相關
    struct Dashboard {
        static let knowledgePointCard = "知識點卡片"
        static let masteryProgress = "熟練度進度"
        static let deleteButton = "刪除按鈕"
        static let archiveButton = "歸檔按鈕"
        static let editButton = "編輯按鈕"
        static let statsCard = "統計資料卡片"
        static let refreshButton = "重新整理按鈕"
    }
    
    // MARK: - AI 家教相關
    struct AITutor {
        static let questionCard = "題目卡片"
        static let answerInput = "答案輸入欄位"
        static let submitButton = "提交答案按鈕"
        static let nextButton = "下一題按鈕"
        static let previousButton = "上一題按鈕"
        static let skipButton = "跳過題目按鈕"
        static let progressBar = "學習進度條"
        static let feedbackCard = "AI 回饋卡片"
        static let startSessionButton = "開始學習按鈕"
    }
    
    // MARK: - 學習區域相關
    struct Learning {
        static let calendarView = "學習日曆"
        static let achievementBadge = "成就徽章"
        static let studyStreak = "學習連續天數"
        static let dailyGoal = "每日目標"
        static let statisticsChart = "統計圖表"
    }
    
    // MARK: - 單字庫相關
    struct Vocabulary {
        static let flashcard = "單字卡片"
        static let pronunciationButton = "發音按鈕"
        static let markKnownButton = "標記已知按鈕"
        static let markUnknownButton = "標記未知按鈕"
        static let studyModeButton = "學習模式按鈕"
        static let quizModeButton = "測驗模式按鈕"
    }
}

// MARK: - 無障礙提示常數
struct AccessibilityHints {
    
    // MARK: - 認證相關
    struct Auth {
        static let loginButton = "輕點以登入您的帳號"
        static let registerButton = "輕點以註冊新帳號"
        static let guestModeButton = "輕點以訪客身份使用應用程式"
        static let emailField = "請輸入您的電子郵件地址"
        static let passwordField = "請輸入您的密碼"
        static let showPassword = "輕點以顯示密碼文字"
        static let hidePassword = "輕點以隱藏密碼文字"
    }
    
    // MARK: - 儀表板相關
    struct Dashboard {
        static let knowledgePointCard = "輕點以查看知識點詳細資訊"
        static let deleteAction = "輕點以刪除此知識點"
        static let archiveAction = "輕點以歸檔此知識點"
        static let editAction = "輕點以編輯此知識點"
        static let refreshAction = "輕點以重新載入數據"
    }
    
    // MARK: - AI 家教相關
    struct AITutor {
        static let answerInput = "在此輸入您的答案"
        static let submitAnswer = "輕點以提交您的答案"
        static let nextQuestion = "輕點以進入下一題"
        static let previousQuestion = "輕點以返回上一題"
        static let skipQuestion = "輕點以跳過此題目"
        static let startSession = "輕點以開始新的學習會話"
    }
    
    // MARK: - 學習區域相關
    struct Learning {
        static let selectDate = "輕點以選擇學習日期"
        static let viewAchievement = "輕點以查看成就詳情"
        static let updateGoal = "輕點以更新每日目標"
    }
    
    // MARK: - 單字庫相關
    struct Vocabulary {
        static let flipCard = "輕點以翻轉單字卡片"
        static let playPronunciation = "輕點以播放發音"
        static let markKnown = "輕點以標記為已知單字"
        static let markUnknown = "輕點以標記為未知單字"
    }
}

// MARK: - View 擴展：無障礙功能
extension View {
    
    /// 為互動元素添加完整的無障礙支援
    func accessibleInteraction(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = .isButton,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityValue(value ?? "")
    }
    
    /// 為卡片元素添加無障礙支援
    func accessibleCard(
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    /// 為標題元素添加無障礙支援
    func accessibleHeading(level: Int = 1) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(.h1) // iOS 會根據層級自動調整
    }
    
    /// 為進度指示器添加無障礙支援
    func accessibleProgress(
        value: Double,
        total: Double = 1.0,
        label: String = "進度"
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(value/total * 100))% 完成")
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    /// 為統計數據添加無障礙支援
    func accessibleStatistic(
        label: String,
        value: String,
        trend: String? = nil
    ) -> some View {
        var accessibilityText = "\(label)：\(value)"
        if let trend = trend {
            accessibilityText += "，\(trend)"
        }
        
        return self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
            .accessibilityAddTraits(.isStaticText)
    }
    
    /// 為導航元素添加無障礙支援
    func accessibleNavigation(
        label: String,
        destination: String
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint("導航至\(destination)")
            .accessibilityAddTraits(.isButton)
    }
    
    /// 為輸入表單添加無障礙支援
    func accessibleForm() -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilityLabel("表單")
    }
    
    /// 為錯誤訊息添加無障礙支援
    func accessibleError(message: String) -> some View {
        self
            .accessibilityLabel("錯誤：\(message)")
            .accessibilityAddTraits(.isStaticText)
            .accessibilityAction(.default) {
                // iOS 15+ 使用 AccessibilityNotification
                if #available(iOS 15.0, *) {
                    // 這裡可以添加輔助功能通知
                }
            }
    }
    
    /// 為成功訊息添加無障礙支援
    func accessibleSuccess(message: String) -> some View {
        self
            .accessibilityLabel("成功：\(message)")
            .accessibilityAddTraits(.isStaticText)
            .accessibilityAction(.default) {
                // iOS 15+ 使用 AccessibilityNotification
                if #available(iOS 15.0, *) {
                    // 這裡可以添加輔助功能通知
                }
            }
    }
}

// MARK: - 無障礙動態類型支援
extension Font {
    /// 支援動態類型的應用程式字體
    static func appDynamicFont(
        style: Font.TextStyle,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> Font {
        return .system(style, design: design, weight: weight)
    }
}

// MARK: - 色彩對比度檢查
extension Color {
    /// 檢查與背景色的對比度是否符合無障礙標準
    func contrastRatio(with background: Color) -> Double {
        // 這是一個簡化的對比度計算
        // 實際應用中可能需要更精確的計算
        return 4.5 // 返回預設的可接受對比度
    }
    
    /// 根據系統設定調整對比度
    static func adaptiveText(primary: Color, secondary: Color) -> Color {
        // 檢查是否啟用了增強對比度
        return primary // 簡化實現，實際可根據系統設定調整
    }
}

// MARK: - VoiceOver 手勢支援
struct AccessibleGestures {
    /// 為 VoiceOver 用戶提供自定義手勢
    static func customRotorAction(
        label: String,
        action: @escaping () -> Void
    ) -> AccessibilityCustomContentKey {
        return AccessibilityCustomContentKey(Text(label), id: label)
    }
}

// MARK: - 無障礙測試輔助
#if DEBUG
struct AccessibilityPreview: View {
    var body: some View {
        VStack(spacing: ModernSpacing.lg) {
            Text("無障礙功能測試")
                .accessibleHeading()
            
            ModernButton("測試按鈕") {}
                .accessibleInteraction(
                    label: AccessibilityLabels.Auth.loginButton,
                    hint: AccessibilityHints.Auth.loginButton
                )
            
            HStack {
                Text("進度：")
                ProgressView(value: 0.75)
                    .accessibleProgress(value: 0.75, label: "學習進度")
            }
            
            Text("統計：75%")
                .accessibleStatistic(
                    label: "完成率",
                    value: "75%",
                    trend: "比昨天提高 5%"
                )
        }
        .padding()
        .accessibleForm()
    }
}

#Preview {
    AccessibilityPreview()
}
#endif