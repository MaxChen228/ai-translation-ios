# iOS前端遷移分析報告

## 1. 現有架構分析

### 1.1 API調用模式
目前的 VocabularyService.swift 使用以下端點：

| 功能 | 現有端點 | 新統一API端點 | 差異分析 |
|------|----------|---------------|----------|
| 獲取統計 | `/api/vocabulary/statistics` | `/api/vocabulary/statistics` | ✅ 完全相同 |
| 獲取單字列表 | `/api/vocabulary/words` | `/api/vocabulary/words` | ⚠️ 需要新增 scope 參數 |
| 獲取今日複習 | `/api/vocabulary/review/daily` | `/api/vocabulary/review/daily` | ✅ 完全相同 |
| 獲取單字詳情 | `/api/vocabulary/words/{id}` | `/api/vocabulary/words/{id}` | ✅ 完全相同 |
| 獲取內建單字 | `/api/vocabulary/builtin/word/{word}` | `/api/vocabulary/builtin/word/{word}` | ✅ 兼容端點存在 |
| 生成測驗 | `/api/vocabulary/quiz/generate` | ❌ 不存在 | 需要實現替代方案 |
| 提交複習 | `/api/vocabulary/review/submit` | `/api/vocabulary/words/{id}/review` | ⚠️ 端點路徑變更 |

### 1.2 數據模型差異

#### 統計模型 (VocabularyStatistics)
現有模型：
```swift
totalWords, masteredWords, learningWords, newWords, dueToday, masteryPercentage
```

新API響應：
```json
{
    "total_words": 10,           // 用戶學習中的單字數
    "new_words": 2,              // 新單字（未複習）
    "learning_words": 5,         // 學習中
    "mastered_words": 3,         // 已掌握
    "due_today": 1,              // 今日待複習
    "favorite_words": 0,         // 收藏單字（新增）
    "avg_mastery": 2.5,          // 平均掌握度（新增）
    "total_system_words": 9932,  // 系統總單字數（新增）
    "enriched_words": 59,        // 已充實單字數（新增）
    "mastery_percentage": 30.0,  // 掌握百分比
    "learning_percentage": 0.1   // 學習覆蓋率（新增）
}
```

#### 單字列表響應
現有模型：
```json
{
    "words": [...],
    "total_count": 100,
    "page": 1,
    "limit": 20
}
```

新API響應：
```json
{
    "words": [...],
    "pagination": {
        "page": 1,
        "limit": 20,
        "total": 100,
        "pages": 5
    },
    "scope": "all"
}
```

#### 單字模型 (VocabularyWord)
主要差異：
- 新API使用 `word_id` 而不是 `id`
- 新API使用 `pronunciation` 而不是 `pronunciation_ipa`
- 新API使用 `definitions` (JSONB) 而不是分離的 `definition_zh` 和 `definition_en`
- 新API有 `classifications` 欄位包含分類資訊

### 1.3 功能影響評估

1. **統計顯示** - 需要更新模型以包含新欄位
2. **單字列表** - 需要處理新的分頁結構和 scope 參數
3. **測驗功能** - 需要重新設計，因為後端不再提供測驗生成API
4. **複習提交** - 需要更改API調用路徑和參數格式

## 2. 遷移策略

### 2.1 分階段遷移

#### 第一階段：相容性改造（低風險）
1. 更新數據模型以支援新舊兩種格式
2. 在 Service 層添加適配器方法
3. 保持現有UI不變

#### 第二階段：API切換（中風險）
1. 逐個更新API調用
2. 添加錯誤處理和降級策略
3. 進行充分測試

#### 第三階段：功能優化（高風險）
1. 重新設計測驗功能
2. 利用新API的額外功能
3. 優化UI以展示新數據

### 2.2 具體實施步驟

#### Step 1: 創建新的數據模型（向後兼容）
```swift
// 新的統計模型，兼容舊版
struct UnifiedVocabularyStatistics: Codable {
    let totalWords: Int
    let masteredWords: Int
    let learningWords: Int
    let newWords: Int
    let dueToday: Int
    let masteryPercentage: Double
    
    // 新增欄位（可選）
    let favoriteWords: Int?
    let avgMastery: Double?
    let totalSystemWords: Int?
    let enrichedWords: Int?
    let learningPercentage: Double?
}
```

#### Step 2: 創建適配器服務
```swift
class UnifiedVocabularyService: VocabularyService {
    // 覆寫需要調整的方法
    override func getWords(...) async throws -> WordListResponse {
        // 添加 scope 參數，轉換響應格式
    }
    
    override func submitReview(...) async throws -> ReviewResult {
        // 使用新的端點路徑
    }
}
```

#### Step 3: 測驗功能重構
- 在客戶端實現測驗生成邏輯
- 利用單字列表API獲取題目素材
- 本地管理測驗狀態

### 2.3 風險評估與緩解措施

| 風險 | 影響 | 緩解措施 |
|------|------|----------|
| API響應格式不兼容 | 應用崩潰 | 添加響應驗證和錯誤處理 |
| 測驗功能失效 | 用戶體驗下降 | 提前實現客戶端測驗邏輯 |
| 網路延遲增加 | 性能下降 | 實現本地緩存和預加載 |
| 數據不一致 | 功能異常 | 添加數據驗證和同步機制 |

## 3. 測試計劃

### 3.1 單元測試
- 測試新的數據模型解析
- 測試API適配器邏輯
- 測試錯誤處理

### 3.2 集成測試
- 測試完整的API調用流程
- 測試數據同步
- 測試離線功能

### 3.3 UI測試
- 測試統計顯示
- 測試單字列表和搜索
- 測試學習和複習流程

## 4. 時間估算

- 第一階段：2-3天（低風險，主要是代碼重構）
- 第二階段：3-4天（中風險，需要充分測試）
- 第三階段：4-5天（高風險，涉及功能重新設計）

總計：9-12天

## 5. 建議

1. **優先完成第一階段**，確保應用穩定性
2. **在測試環境充分驗證**後再進行第二階段
3. **測驗功能可以考慮**保留舊API或實現簡化版本
4. **監控API性能**，必要時優化查詢或添加緩存
5. **準備回滾方案**，以防出現嚴重問題