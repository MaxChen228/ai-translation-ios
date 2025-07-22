// KnowledgePointSyncManager.swift - 知識點本地與雲端同步管理器

import Foundation
import SwiftUI

/// 知識點同步狀態
enum SyncStatus {
    case pending      // 待同步
    case syncing      // 同步中
    case synced       // 已同步
    case failed       // 同步失敗
}

/// 本地知識點同步記錄
struct LocalKnowledgePointSync {
    let localId: String
    let tempId: Int
    var syncStatus: SyncStatus
    var lastSyncAttempt: Date?
    var syncError: String?
}

/// 知識點同步管理器
@MainActor
class KnowledgePointSyncManager: ObservableObject {
    static let shared = KnowledgePointSyncManager()
    
    @Published var isSyncing = false
    @Published var pendingSyncCount = 0
    @Published var lastSyncDate: Date?
    @Published var syncErrors: [String] = []
    
    private let syncStatusKey = "knowledge_point_sync_status"
    private let lastSyncDateKey = "last_knowledge_point_sync_date"
    
    private init() {
        loadSyncStatus()
    }
    
    /// 載入同步狀態
    private func loadSyncStatus() {
        if let date = UserDefaults.standard.object(forKey: lastSyncDateKey) as? Date {
            lastSyncDate = date
        }
        updatePendingSyncCount()
    }
    
    /// 更新待同步數量
    func updatePendingSyncCount() {
        let guestPoints = GuestDataManager.shared.getGuestKnowledgePoints()
        pendingSyncCount = guestPoints.filter { point in
            // 檢查是否為本地知識點（負數 ID）
            if let id = point["id"] as? Int, id < 0 {
                return true
            }
            return false
        }.count
    }
    
    /// 同步所有本地知識點到雲端
    func syncAllLocalKnowledgePoints() async {
        guard !isSyncing else { return }
        
        // 檢查是否為訪客模式
        let authManager = AuthenticationManager.shared
        guard authManager.authState.isAuthenticated else {
            print("❌ 無法同步：使用者未登入")
            return
        }
        
        isSyncing = true
        syncErrors.removeAll()
        
        let guestManager = GuestDataManager.shared
        let localPoints = guestManager.getGuestKnowledgePoints()
        
        var successCount = 0
        var failureCount = 0
        
        for pointData in localPoints {
            // 只同步負數 ID 的本地知識點
            guard let localId = pointData["id"] as? Int, localId < 0 else {
                continue
            }
            
            do {
                // 準備同步資料
                var syncData = pointData
                syncData.removeValue(forKey: "id") // 移除本地 ID
                syncData.removeValue(forKey: "localId") // 移除本地 UUID
                syncData.removeValue(forKey: "isLocal") // 移除本地標記
                
                // 建立錯誤分析物件
                let errorAnalysis = ErrorAnalysis(
                    errorTypeCode: syncData["subcategory"] as? String ?? "B",
                    keyPointSummary: syncData["key_point_summary"] as? String ?? "",
                    originalPhrase: syncData["incorrect_phrase_in_context"] as? String ?? "",
                    correction: syncData["correct_phrase"] as? String ?? "",
                    explanation: syncData["explanation"] as? String ?? "",
                    severity: "medium"
                )
                
                // 準備問題資料
                let questionData: [String: Any?] = [
                    "new_sentence": syncData["user_context_sentence"] as? String ?? "",
                    "type": "review",
                    "hint_text": nil,
                    "knowledge_point_id": nil,
                    "mastery_level": syncData["mastery_level"] as? Double ?? 0.0
                ]
                
                // 呼叫 API 儲存到雲端
                let savedCount = try await UnifiedAPIService.shared.finalizeKnowledgePoints(
                    errors: [errorAnalysis],
                    questionData: questionData,
                    userAnswer: syncData["user_context_sentence"] as? String ?? ""
                )
                
                if savedCount > 0 {
                    successCount += 1
                    // 從本地移除已同步的知識點
                    removeLocalKnowledgePoint(localId: localId)
                } else {
                    failureCount += 1
                    syncErrors.append("知識點 \(abs(localId)) 同步失敗")
                }
                
            } catch {
                failureCount += 1
                syncErrors.append("知識點 \(abs(localId)) 同步錯誤: \(error.localizedDescription)")
            }
            
            // 避免過度請求
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒延遲
        }
        
        // 更新同步狀態
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: lastSyncDateKey)
        updatePendingSyncCount()
        isSyncing = false
        
        print("✅ 同步完成：成功 \(successCount) 個，失敗 \(failureCount) 個")
        
        // 顯示同步結果通知
        if successCount > 0 || failureCount > 0 {
            await showSyncNotification(success: successCount, failure: failureCount)
        }
    }
    
    /// 移除已同步的本地知識點
    private func removeLocalKnowledgePoint(localId: Int) {
        let guestManager = GuestDataManager.shared
        var points = guestManager.getGuestKnowledgePoints()
        
        points.removeAll { point in
            if let id = point["id"] as? Int {
                return id == localId
            }
            return false
        }
        
        // 儲存更新後的列表
        if let data = try? JSONSerialization.data(withJSONObject: points) {
            UserDefaults.standard.set(data, forKey: "guest_knowledge_points")
        }
    }
    
    /// 顯示同步結果通知
    private func showSyncNotification(success: Int, failure: Int) async {
        // 這裡可以整合推送通知或應用內通知
        // 目前先用 print 輸出
        var message = "知識點同步完成："
        if success > 0 {
            message += "\n✅ 成功同步 \(success) 個知識點"
        }
        if failure > 0 {
            message += "\n❌ \(failure) 個知識點同步失敗"
        }
        print(message)
    }
    
    /// 檢查是否需要自動同步
    func checkAndPerformAutoSync() async {
        // 檢查條件：
        // 1. 使用者已登入
        // 2. 有待同步的知識點
        // 3. 距離上次同步超過 1 小時
        
        guard AuthenticationManager.shared.authState.isAuthenticated else { return }
        guard pendingSyncCount > 0 else { return }
        
        if let lastSync = lastSyncDate {
            let hoursSinceLastSync = Date().timeIntervalSince(lastSync) / 3600
            guard hoursSinceLastSync >= 1 else { return }
        }
        
        await syncAllLocalKnowledgePoints()
    }
    
    /// 獲取同步狀態摘要
    func getSyncStatusSummary() -> String {
        if isSyncing {
            return "同步中..."
        } else if pendingSyncCount > 0 {
            return "有 \(pendingSyncCount) 個知識點待同步"
        } else if let lastSync = lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "上次同步：\(formatter.localizedString(for: lastSync, relativeTo: Date()))"
        } else {
            return "所有知識點已同步"
        }
    }
}

/// 同步狀態視圖元件
struct SyncStatusView: View {
    @StateObject private var syncManager = KnowledgePointSyncManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        if authManager.authState.isAuthenticated {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: syncManager.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.icloud")
                        .foregroundStyle(syncManager.pendingSyncCount > 0 ? .orange : .green)
                        .symbolEffect(.pulse, isActive: syncManager.isSyncing)
                    
                    Text(syncManager.getSyncStatusSummary())
                        .font(.appFootnote())
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if syncManager.pendingSyncCount > 0 && !syncManager.isSyncing {
                        Button {
                            Task {
                                await syncManager.syncAllLocalKnowledgePoints()
                            }
                        } label: {
                            Text("立即同步")
                                .font(.appCaption())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.modernAccent.opacity(0.2))
                                .foregroundStyle(Color.modernAccent)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.modernBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if !syncManager.syncErrors.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(syncManager.syncErrors, id: \.self) { error in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                    .font(.appCaption())
                                Text(error)
                                    .font(.appCaption())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}