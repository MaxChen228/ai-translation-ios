// GuestDataManager.swift

import Foundation

class GuestDataManager: ObservableObject {
    static let shared = GuestDataManager()
    
    @Published var guestUser: GuestUser
    
    // UserDefaults keys
    private let guestUserKey = "guest_user_data"
    private let guestKnowledgePointsKey = "guest_knowledge_points"
    private let guestLearningSessionsKey = "guest_learning_sessions"
    
    private init() {
        self.guestUser = GuestDataManager.loadGuestUser()
    }
    
    // MARK: - 訪客用戶資料管理
    
    private static func loadGuestUser() -> GuestUser {
        if let data = UserDefaults.standard.data(forKey: "guest_user_data"),
           let savedGuestUser = try? JSONDecoder().decode(GuestUser.self, from: data) {
            return savedGuestUser
        }
        return GuestUser()
    }
    
    func saveGuestUser() {
        if let data = try? JSONEncoder().encode(guestUser) {
            UserDefaults.standard.set(data, forKey: guestUserKey)
        }
    }
    
    // MARK: - 學習統計更新
    
    func updateLearningTime(_ seconds: Int) {
        guestUser.totalLearningTime += seconds
        saveGuestUser()
    }
    
    func incrementKnowledgePoints(_ count: Int = 1) {
        guestUser.knowledgePointsCount += count
        saveGuestUser()
    }
    
    func incrementSessionsCompleted() {
        guestUser.sessionsCompleted += 1
        saveGuestUser()
    }
    
    // MARK: - 訪客知識點管理（本地儲存）
    
    func saveGuestKnowledgePoint(_ knowledgePoint: [String: Any]) {
        var savedPoints = getGuestKnowledgePoints()
        savedPoints.append(knowledgePoint)
        
        if let data = try? JSONSerialization.data(withJSONObject: savedPoints) {
            UserDefaults.standard.set(data, forKey: guestKnowledgePointsKey)
        }
    }
    
    func getGuestKnowledgePoints() -> [[String: Any]] {
        guard let data = UserDefaults.standard.data(forKey: guestKnowledgePointsKey),
              let points = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return points
    }
    
    // MARK: - 學習會話記錄
    
    func saveGuestLearningSession(_ session: [String: Any]) {
        var savedSessions = getGuestLearningSessions()
        savedSessions.append(session)
        
        // 只保留最近50個會話，避免本地儲存過大
        if savedSessions.count > 50 {
            savedSessions = Array(savedSessions.suffix(50))
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: savedSessions) {
            UserDefaults.standard.set(data, forKey: guestLearningSessionsKey)
        }
    }
    
    func getGuestLearningSessions() -> [[String: Any]] {
        guard let data = UserDefaults.standard.data(forKey: guestLearningSessionsKey),
              let sessions = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return sessions
    }
    
    // MARK: - 訪客限制檢查
    
    func canUseFeature(_ feature: GuestFeatureLimit) -> Bool {
        switch feature {
        case .dailyPractice:
            return getTodayPracticeCount() < feature.limit
        case .knowledgePointsSave:
            return guestUser.knowledgePointsCount < feature.limit
        case .aiModelAccess:
            return false // 訪客無法使用進階AI模型
        case .cloudSync:
            return false // 訪客無法使用雲端同步
        }
    }
    
    private func getTodayPracticeCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let sessions = getGuestLearningSessions()
        
        return sessions.filter { session in
            if let timestampString = session["timestamp"] as? String,
               let timestamp = ISO8601DateFormatter().date(from: timestampString) {
                return Calendar.current.isDate(timestamp, inSameDayAs: today)
            }
            return false
        }.count
    }
    
    // MARK: - 數據遷移準備
    
    func prepareDataForMigration() -> [String: Any] {
        return [
            "guestUser": (try? JSONEncoder().encode(guestUser)) ?? Data(),
            "knowledgePoints": getGuestKnowledgePoints(),
            "learningSessions": getGuestLearningSessions(),
            "migrationTimestamp": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    // MARK: - 清除訪客數據
    
    func clearGuestData() {
        UserDefaults.standard.removeObject(forKey: guestUserKey)
        UserDefaults.standard.removeObject(forKey: guestKnowledgePointsKey)
        UserDefaults.standard.removeObject(forKey: guestLearningSessionsKey)
        guestUser = GuestUser()
    }
    
    // MARK: - 訪客模式提示檢查
    
    func shouldShowRegistrationPrompt() -> Bool {
        // 完成5個學習會話後提示註冊
        if guestUser.sessionsCompleted >= 5 { return true }
        
        // 學習時間超過30分鐘後提示註冊
        if guestUser.totalLearningTime >= 1800 { return true }
        
        // 收集5個知識點後提示註冊
        if guestUser.knowledgePointsCount >= 5 { return true }
        
        return false
    }
}

// MARK: - 訪客功能限制枚舉

enum GuestFeatureLimit {
    case dailyPractice     // 每日練習次數限制
    case knowledgePointsSave // 知識點收藏限制
    case aiModelAccess     // AI模型訪問限制
    case cloudSync         // 雲端同步限制
    
    var limit: Int {
        switch self {
        case .dailyPractice: return 10      // 每日最多10次練習
        case .knowledgePointsSave: return 20 // 最多收藏20個知識點
        case .aiModelAccess: return 0       // 無法使用
        case .cloudSync: return 0           // 無法使用
        }
    }
    
    var description: String {
        switch self {
        case .dailyPractice:
            return "訪客模式每日最多練習\(limit)次"
        case .knowledgePointsSave:
            return "訪客模式最多收藏\(limit)個知識點"
        case .aiModelAccess:
            return "註冊後可使用進階AI模型"
        case .cloudSync:
            return "註冊後可同步至雲端"
        }
    }
}