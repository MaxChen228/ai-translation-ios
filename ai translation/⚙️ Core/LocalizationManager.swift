// LocalizationManager.swift - 國際化管理系統

import Foundation
import SwiftUI

// MARK: - 本地化管理器
@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: SupportedLanguage = .traditionalChinese
    @Published var currentRegion: SupportedRegion = .taiwan
    
    private init() {
        // 從用戶偏好或系統設定載入語言
        loadUserPreferredLanguage()
    }
    
    /// 切換語言
    func setLanguage(_ language: SupportedLanguage) {
        currentLanguage = language
        saveUserPreference()
        
        // 通知系統語言已變更
        NotificationCenter.default.post(
            name: .languageDidChange,
            object: language
        )
    }
    
    /// 獲取本地化字串
    func localizedString(for key: LocalizedStringKey, language: SupportedLanguage? = nil) -> String {
        let targetLanguage = language ?? currentLanguage
        
        // 從對應的語言包獲取字串
        return LocalizedStrings.getString(for: key, language: targetLanguage)
    }
    
    /// 載入用戶偏好語言
    private func loadUserPreferredLanguage() {
        if let languageCode = UserDefaults.standard.string(forKey: "user_preferred_language"),
           let language = SupportedLanguage(rawValue: languageCode) {
            currentLanguage = language
        } else {
            // 根據系統語言自動選擇
            detectSystemLanguage()
        }
    }
    
    /// 儲存用戶偏好
    private func saveUserPreference() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: "user_preferred_language")
    }
    
    /// 偵測系統語言
    private func detectSystemLanguage() {
        let systemLanguages = Locale.preferredLanguages
        
        for languageCode in systemLanguages {
            if languageCode.hasPrefix("zh-Hant") || languageCode.hasPrefix("zh-TW") {
                currentLanguage = .traditionalChinese
                currentRegion = .taiwan
                return
            } else if languageCode.hasPrefix("zh-Hans") || languageCode.hasPrefix("zh-CN") {
                currentLanguage = .simplifiedChinese
                currentRegion = .china
                return
            } else if languageCode.hasPrefix("en") {
                currentLanguage = .english
                currentRegion = .unitedStates
                return
            }
        }
        
        // 預設使用繁體中文（台灣）
        currentLanguage = .traditionalChinese
        currentRegion = .taiwan
    }
}

// MARK: - 支援的語言
enum SupportedLanguage: String, CaseIterable, Identifiable {
    case traditionalChinese = "zh-Hant"
    case simplifiedChinese = "zh-Hans"
    case english = "en"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .traditionalChinese: return "繁體中文"
        case .simplifiedChinese: return "简体中文"
        case .english: return "English"
        }
    }
    
    var nativeName: String {
        switch self {
        case .traditionalChinese: return "繁體中文（台灣）"
        case .simplifiedChinese: return "简体中文（中国）"
        case .english: return "English (US)"
        }
    }
    
    var flagEmoji: String {
        switch self {
        case .traditionalChinese: return "🇹🇼"
        case .simplifiedChinese: return "🇨🇳"
        case .english: return "🇺🇸"
        }
    }
}

// MARK: - 支援的地區
enum SupportedRegion: String, CaseIterable {
    case taiwan = "TW"
    case china = "CN"
    case unitedStates = "US"
    case hongKong = "HK"
    case singapore = "SG"
    
    var displayName: String {
        switch self {
        case .taiwan: return "台灣"
        case .china: return "中國大陸"
        case .unitedStates: return "美國"
        case .hongKong: return "香港"
        case .singapore: return "新加坡"
        }
    }
}

// MARK: - 本地化字串鍵值
enum LocalizedStringKey: String {
    // MARK: - 通用
    case appName = "app_name"
    case loading = "loading"
    case error = "error"
    case success = "success"
    case cancel = "cancel"
    case confirm = "confirm"
    case save = "save"
    case delete = "delete"
    case edit = "edit"
    case done = "done"
    case back = "back"
    case next = "next"
    case previous = "previous"
    case retry = "retry"
    case refresh = "refresh"
    
    // MARK: - 認證
    case login = "login"
    case register = "register"
    case logout = "logout"
    case email = "email"
    case password = "password"
    case confirmPassword = "confirm_password"
    case username = "username"
    case displayName = "display_name"
    case guestMode = "guest_mode"
    case loginSuccess = "login_success"
    case loginFailed = "login_failed"
    case registerSuccess = "register_success"
    case registerFailed = "register_failed"
    
    // MARK: - 儀表板
    case dashboard = "dashboard"
    case overview = "overview"
    case statistics = "statistics"
    case progress = "progress"
    case totalKnowledgePoints = "total_knowledge_points"
    case masteredPoints = "mastered_points"
    case averageMastery = "average_mastery"
    case completionRate = "completion_rate"
    case weeklyProgress = "weekly_progress"
    case studyStreak = "study_streak"
    
    // MARK: - AI 家教
    case aiTutor = "ai_tutor"
    case startLearning = "start_learning"
    case submitAnswer = "submit_answer"
    case nextQuestion = "next_question"
    case previousQuestion = "previous_question"
    case skipQuestion = "skip_question"
    case viewFeedback = "view_feedback"
    case sessionComplete = "session_complete"
    case yourAnswer = "your_answer"
    case correctAnswer = "correct_answer"
    case feedback = "feedback"
    
    // MARK: - 學習區域
    case learningArea = "learning_area"
    case calendar = "calendar"
    case achievements = "achievements"
    case settings = "settings"
    case dailyGoal = "daily_goal"
    case weeklyGoal = "weekly_goal"
    case monthlyGoal = "monthly_goal"
    
    // MARK: - 單字庫
    case vocabulary = "vocabulary"
    case flashcards = "flashcards"
    case quiz = "quiz"
    case studyMode = "study_mode"
    case pronunciation = "pronunciation"
    case definition = "definition"
    case example = "example"
    case known = "known"
    case unknown = "unknown"
    
    // MARK: - 設定
    case language = "language"
    case region = "region"
    case theme = "theme"
    case notifications = "notifications"
    case privacy = "privacy"
    case about = "about"
    case version = "version"
    case support = "support"
    
    // MARK: - 錯誤訊息
    case networkError = "network_error"
    case invalidInput = "invalid_input"
    case authenticationError = "authentication_error"
    case permissionDenied = "permission_denied"
    case unknownError = "unknown_error"
}

// MARK: - 本地化字串庫
struct LocalizedStrings {
    static func getString(for key: LocalizedStringKey, language: SupportedLanguage) -> String {
        switch language {
        case .traditionalChinese:
            return traditionalChineseStrings[key] ?? key.rawValue
        case .simplifiedChinese:
            return simplifiedChineseStrings[key] ?? key.rawValue
        case .english:
            return englishStrings[key] ?? key.rawValue
        }
    }
    
    // MARK: - 繁體中文字串
    private static let traditionalChineseStrings: [LocalizedStringKey: String] = [
        .appName: "AI 翻譯學習",
        .loading: "載入中...",
        .error: "錯誤",
        .success: "成功",
        .cancel: "取消",
        .confirm: "確認",
        .save: "儲存",
        .delete: "刪除",
        .edit: "編輯",
        .done: "完成",
        .back: "返回",
        .next: "下一步",
        .previous: "上一步",
        .retry: "重試",
        .refresh: "重新整理",
        
        .login: "登入",
        .register: "註冊",
        .logout: "登出",
        .email: "電子郵件",
        .password: "密碼",
        .confirmPassword: "確認密碼",
        .username: "使用者名稱",
        .displayName: "顯示名稱",
        .guestMode: "訪客模式",
        .loginSuccess: "登入成功",
        .loginFailed: "登入失敗",
        .registerSuccess: "註冊成功",
        .registerFailed: "註冊失敗",
        
        .dashboard: "儀表板",
        .overview: "概覽",
        .statistics: "統計",
        .progress: "進度",
        .totalKnowledgePoints: "總知識點",
        .masteredPoints: "已熟練",
        .averageMastery: "平均熟練度",
        .completionRate: "完成率",
        .weeklyProgress: "本週進度",
        .studyStreak: "學習連續天數",
        
        .aiTutor: "AI 家教",
        .startLearning: "開始學習",
        .submitAnswer: "提交答案",
        .nextQuestion: "下一題",
        .previousQuestion: "上一題",
        .skipQuestion: "跳過",
        .viewFeedback: "查看回饋",
        .sessionComplete: "學習完成",
        .yourAnswer: "您的答案",
        .correctAnswer: "正確答案",
        .feedback: "回饋",
        
        .learningArea: "學習區域",
        .calendar: "日曆",
        .achievements: "成就",
        .settings: "設定",
        .dailyGoal: "每日目標",
        .weeklyGoal: "每週目標",
        .monthlyGoal: "每月目標",
        
        .vocabulary: "單字庫",
        .flashcards: "單字卡",
        .quiz: "測驗",
        .studyMode: "學習模式",
        .pronunciation: "發音",
        .definition: "定義",
        .example: "例句",
        .known: "已知",
        .unknown: "未知",
        
        .language: "語言",
        .region: "地區",
        .theme: "主題",
        .notifications: "通知",
        .privacy: "隱私",
        .about: "關於",
        .version: "版本",
        .support: "支援",
        
        .networkError: "網路連接錯誤",
        .invalidInput: "輸入無效",
        .authenticationError: "驗證錯誤",
        .permissionDenied: "權限被拒絕",
        .unknownError: "未知錯誤"
    ]
    
    // MARK: - 簡體中文字串
    private static let simplifiedChineseStrings: [LocalizedStringKey: String] = [
        .appName: "AI 翻译学习",
        .loading: "加载中...",
        .error: "错误",
        .success: "成功",
        .cancel: "取消",
        .confirm: "确认",
        .save: "保存",
        .delete: "删除",
        .edit: "编辑",
        .done: "完成",
        .back: "返回",
        .next: "下一步",
        .previous: "上一步",
        .retry: "重试",
        .refresh: "刷新",
        
        .login: "登录",
        .register: "注册",
        .logout: "登出",
        .email: "电子邮件",
        .password: "密码",
        .confirmPassword: "确认密码",
        .username: "用户名",
        .displayName: "显示名称",
        .guestMode: "访客模式",
        .loginSuccess: "登录成功",
        .loginFailed: "登录失败",
        .registerSuccess: "注册成功",
        .registerFailed: "注册失败"
        // ... 其他簡體中文翻譯
    ]
    
    // MARK: - 英文字串
    private static let englishStrings: [LocalizedStringKey: String] = [
        .appName: "AI Translation Learning",
        .loading: "Loading...",
        .error: "Error",
        .success: "Success",
        .cancel: "Cancel",
        .confirm: "Confirm",
        .save: "Save",
        .delete: "Delete",
        .edit: "Edit",
        .done: "Done",
        .back: "Back",
        .next: "Next",
        .previous: "Previous",
        .retry: "Retry",
        .refresh: "Refresh",
        
        .login: "Login",
        .register: "Register",
        .logout: "Logout",
        .email: "Email",
        .password: "Password",
        .confirmPassword: "Confirm Password",
        .username: "Username",
        .displayName: "Display Name",
        .guestMode: "Guest Mode",
        .loginSuccess: "Login Successful",
        .loginFailed: "Login Failed",
        .registerSuccess: "Registration Successful",
        .registerFailed: "Registration Failed"
        // ... 其他英文翻譯
    ]
}

// MARK: - SwiftUI 擴展
extension Text {
    /// 初始化本地化文字
    @MainActor
    init(localized key: LocalizedStringKey) {
        let localizedString = LocalizationManager.shared.localizedString(for: key)
        self.init(localizedString)
    }
}

// MARK: - 通知
extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// MARK: - 本地化預覽助手
#if DEBUG
struct LocalizationPreview: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: ModernSpacing.lg) {
            Text(localized: .appName)
                .font(.appTitle())
            
            Picker("語言", selection: $localizationManager.currentLanguage) {
                ForEach(SupportedLanguage.allCases) { language in
                    HStack {
                        Text(language.flagEmoji)
                        Text(language.displayName)
                    }
                    .tag(language)
                }
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading, spacing: ModernSpacing.md) {
                Text(localized: .login)
                Text(localized: .dashboard)
                Text(localized: .aiTutor)
                Text(localized: .vocabulary)
                Text(localized: .settings)
            }
        }
        .padding()
    }
}

#Preview {
    LocalizationPreview()
}
#endif