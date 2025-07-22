// GuestDataManager.swift

import Foundation

// MARK: - Deprecated GuestUser for backward compatibility
struct GuestUser: Codable {
    var totalLearningTime: Int = 0
    var knowledgePointsCount: Int = 0
    var sessionsCompleted: Int = 0
    
    init() {}
}

class GuestDataManager: ObservableObject {
    static let shared = GuestDataManager()
    
    @Published var guestUser: GuestUser
    
    // UserDefaults keys
    private let guestUserKey = "guest_user_data"
    private let guestKnowledgePointsKey = "guest_knowledge_points"
    private let guestLearningSessionsKey = "guest_learning_sessions"
    
    private init() {
        self.guestUser = GuestDataManager.loadGuestUser()
        migrateOldKnowledgePoints()
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
    
    private var localKnowledgePointIdCounter: Int {
        get {
            let counter = UserDefaults.standard.integer(forKey: "localKnowledgePointIdCounter")
            // 如果尚未初始化，從 -1 開始（負數 ID）
            return counter == 0 ? -1 : counter
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "localKnowledgePointIdCounter")
        }
    }
    
    func saveGuestKnowledgePoint(_ knowledgePoint: [String: Any]) {
        var savedPoints = getGuestKnowledgePoints()
        
        // 為本地知識點分配負數 ID
        var modifiedPoint = knowledgePoint
        
        // 獲取當前計數器值並遞減
        var currentCounter = localKnowledgePointIdCounter
        if currentCounter > 0 {
            currentCounter = -1 // 確保從負數開始
        }
        currentCounter -= 1
        
        modifiedPoint["localId"] = modifiedPoint["id"] // 保留原始 UUID
        modifiedPoint["id"] = currentCounter // 使用負數 ID
        modifiedPoint["isLocal"] = true
        
        // 更新計數器
        localKnowledgePointIdCounter = currentCounter
        
        savedPoints.append(modifiedPoint)
        
        if let data = try? JSONSerialization.data(withJSONObject: savedPoints) {
            UserDefaults.standard.set(data, forKey: guestKnowledgePointsKey)
        }
        
        // 增加知識點計數
        incrementKnowledgePoints()
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
    
    // MARK: - 資料遷移
    
    private func migrateOldKnowledgePoints() {
        var points = getGuestKnowledgePoints()
        var needsMigration = false
        
        for i in 0..<points.count {
            // 檢查是否有舊格式的字串 ID
            if let stringId = points[i]["id"] as? String {
                needsMigration = true
                
                // 獲取當前計數器值並遞減
                var currentCounter = localKnowledgePointIdCounter
                if currentCounter > 0 {
                    currentCounter = -1 // 確保從負數開始
                }
                currentCounter -= 1
                
                // 更新為負數 ID
                points[i]["localId"] = stringId // 保留原始 UUID
                points[i]["id"] = currentCounter
                points[i]["isLocal"] = true
                
                // 更新計數器
                localKnowledgePointIdCounter = currentCounter
            }
            
            // 檢查並遷移欄位內容（修正中文句子存在錯誤位置的問題）
            if let context = points[i]["user_context_sentence"] as? String,
               context.range(of: "[\u{4E00}-\u{9FFF}]", options: .regularExpression) != nil {
                // user_context_sentence 包含中文，需要遷移
                needsMigration = true
                
                // 交換欄位內容
                let tempContext = points[i]["user_context_sentence"]
                points[i]["user_context_sentence"] = points[i]["incorrect_phrase_in_context"]
                points[i]["incorrect_phrase_in_context"] = nil // 暫時清空，因為沒有正確資料
                
                print("📝 遷移知識點：交換 user_context_sentence 和 incorrect_phrase_in_context")
            }
            
            // 確保 key_point_summary 存在
            if points[i]["key_point_summary"] == nil || (points[i]["key_point_summary"] as? String)?.isEmpty == true {
                needsMigration = true
                // 使用 subcategory 或固定文字作為預設值
                points[i]["key_point_summary"] = points[i]["subcategory"] as? String ?? "需要更新"
                print("📝 遷移知識點：添加預設 key_point_summary")
            }
        }
        
        // 如果有需要遷移的資料，儲存更新後的知識點
        if needsMigration {
            if let data = try? JSONSerialization.data(withJSONObject: points) {
                UserDefaults.standard.set(data, forKey: guestKnowledgePointsKey)
                print("✅ 已遷移並修正 \(points.count) 個本地知識點")
            }
        }
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