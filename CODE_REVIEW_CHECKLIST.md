# 📋 AI 翻譯學習 - 代碼審查檢查清單

## 🎯 核心設計原則檢查

### ✅ 設計系統一致性
- [ ] 使用 `Color.modern...` 而非硬編碼顏色
- [ ] 使用 `.appFont()` 系列字體方法
- [ ] 使用 `ModernSpacing.*` 間距常數
- [ ] 使用 `ModernRadius.*` 圓角常數
- [ ] 遵循 Claude 風格的極簡主義設計

### ✅ 架構模式檢查
- [ ] 視圖檔案保持 < 300 行
- [ ] 業務邏輯已移至 ViewModel
- [ ] API 調用集中在 Repository 層
- [ ] 使用 `@MainActor` 標記 ViewModel
- [ ] 正確使用 `@Published` 屬性
- [ ] 避免在 View 中直接進行網路請求

### ✅ 無障礙支援檢查
- [ ] 所有互動元素添加 `accessibilityLabel`
- [ ] 適當使用 `accessibilityHint`
- [ ] 正確設置 `accessibilityTraits`
- [ ] 圖示元素適當使用 `accessibilityHidden(true)`
- [ ] 進度條有意義的 `accessibilityValue`
- [ ] 表單元素支援 VoiceOver 導航

## 📱 SwiftUI 最佳實踐

### ✅ 狀態管理
- [ ] 適當使用 `@State` vs `@StateObject` vs `@ObservedObject`
- [ ] 避免不必要的狀態重新計算
- [ ] 使用 `@EnvironmentObject` 傳遞共享依賴
- [ ] 正確處理 `@Binding` 雙向綁定

### ✅ 效能優化
- [ ] 使用 `LazyVStack`/`LazyHStack` 處理長列表
- [ ] 適當使用 `LazyVGrid` 而非巢狀 `HStack`
- [ ] 避免在 `body` 中進行複雜計算
- [ ] 使用 computed properties 優化重複邏輯
- [ ] 適當使用 `.id()` 強制視圖重新渲染

### ✅ 錯誤處理
- [ ] 所有 async/await 函數包含適當的錯誤處理
- [ ] 網路錯誤有用戶友好的訊息
- [ ] 載入狀態正確顯示
- [ ] 錯誤狀態提供重試機制

## 🏗️ 架構品質檢查

### ✅ MVVM 模式
```swift
// ✅ 正確的 ViewModel 結構
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var knowledgePoints: [KnowledgePoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository: KnowledgePointRepository
    
    func loadData() async { /* 業務邏輯 */ }
}

// ❌ 避免在 View 中直接處理業務邏輯
struct BadView: View {
    @State private var data: [Item] = []
    
    var body: some View {
        // ❌ 不要在這裡直接呼叫 API
        .onAppear {
            Task {
                data = try await APIService.fetchData()
            }
        }
    }
}
```

### ✅ Repository 模式
- [ ] API 調用統一在 Repository 層
- [ ] 實現本地快取機制
- [ ] 適當的錯誤映射和處理
- [ ] 支援離線模式（從快取讀取）

### ✅ 依賴注入
- [ ] ViewModel 通過初始化器接收依賴
- [ ] 避免在 ViewModel 中直接實例化服務
- [ ] 使用協議定義服務介面
- [ ] 便於單元測試的結構

## 🎨 UI/UX 品質檢查

### ✅ 組件設計
- [ ] 組件職責單一且明確
- [ ] 可重用組件參數化設計
- [ ] 支援不同尺寸和狀態
- [ ] 預覽程式碼完整且有代表性

### ✅ 響應式設計
- [ ] 支援不同螢幕尺寸（iPhone SE 到 Pro Max）
- [ ] 正確處理橫豎屏切換
- [ ] 動態類型字體支援
- [ ] 暗黑模式適配（如有需要）

### ✅ 動畫與過渡
- [ ] 動畫時長適中（0.2-0.5秒）
- [ ] 使用適當的緩動函數
- [ ] 避免過度動畫影響效能
- [ ] 重要狀態變化有視覺回饋

## 🔒 安全性檢查

### ✅ 資料安全
- [ ] 敏感資料使用 Keychain 存儲
- [ ] 避免在日誌中暴露敏感資訊
- [ ] API Token 安全管理
- [ ] 輸入驗證和清理

### ✅ 錯誤處理安全
- [ ] 錯誤訊息不洩露系統資訊
- [ ] 適當的錯誤日誌記錄
- [ ] 網路錯誤的安全處理

## 🧪 測試就緒性

### ✅ 可測試性
- [ ] ViewModel 邏輯與 UI 分離
- [ ] 依賴可以輕易模擬（Mock）
- [ ] 避免靜態依賴和全域狀態
- [ ] 純函數易於單元測試

### ✅ 預覽支援
- [ ] 所有組件提供有意義的預覽
- [ ] 預覽涵蓋不同狀態（載入、錯誤、空狀態）
- [ ] 使用範例資料進行預覽

## 📝 代碼品質檢查

### ✅ 命名規範
- [ ] 變數和函數使用清晰的名稱
- [ ] 類別和結構體遵循 PascalCase
- [ ] 常數使用有意義的名稱
- [ ] 避免縮寫和模糊命名

### ✅ 代碼組織
- [ ] 相關功能分組在 MARK 區塊中
- [ ] 檔案大小合理（< 500 行）
- [ ] 適當的註解和文檔
- [ ] 移除未使用的程式碼和匯入

### ✅ Swift 風格
- [ ] 遵循 Swift API 設計指南
- [ ] 使用尾隨閉包語法
- [ ] 適當使用 guard 語句
- [ ] 避免強制解包，使用可選綁定

## 🌍 國際化支援

### ✅ 本地化準備
- [ ] 所有用戶可見字串使用本地化
- [ ] 避免硬編碼文字
- [ ] 支援從右到左（RTL）語言（如需要）
- [ ] 日期和數字格式本地化

### ✅ 文化適應
- [ ] 顏色選擇考慮文化差異
- [ ] 圖示和符號的文化適當性
- [ ] 文字長度變化的 UI 適應性

## 📊 效能檢查

### ✅ 記憶體管理
- [ ] 避免強循環引用
- [ ] 適當使用 weak/unowned 引用
- [ ] 及時釋放大型資源
- [ ] 圖片資源適當壓縮

### ✅ 網路效能
- [ ] 實現請求快取
- [ ] 避免重複請求
- [ ] 適當的超時設定
- [ ] 支援請求取消

## 🚀 部署準備

### ✅ 建置設定
- [ ] 移除所有調試程式碼
- [ ] 適當的部署目標設定
- [ ] 資源檔案正確打包
- [ ] 版本號正確設定

### ✅ 上線檢查
- [ ] 所有功能經過測試
- [ ] 處理邊界情況
- [ ] 錯誤處理完整
- [ ] 效能滿足要求

---

## 📋 代碼審查流程

1. **自我檢查**：開發者提交前自行檢查此清單
2. **同儕審查**：團隊成員依據此清單進行代碼審查
3. **架構審查**：資深開發者檢查架構合理性
4. **最終測試**：QA 團隊進行功能和品質測試

## 🎯 建議使用方式

- 在每次 Pull Request 前自行檢查
- 代碼審查時作為參考依據
- 定期回顧和更新檢查項目
- 根據專案需求調整檢查重點

---

*此檢查清單會持續改進，請定期檢查更新*