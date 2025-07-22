# Core 目錄

核心功能模組，提供應用程式的基礎服務。這些模組不包含業務邏輯，可被任何功能模組使用。

## 子目錄說明

### Network/
網路層實現：
- `NetworkManager.swift` - 網路請求管理器
- `APIEndpoint.swift` - API 端點定義
- `UnifiedAPIService.swift` - 統一的 API 服務

### Database/
資料持久化：
- `CoreDataManager.swift` - Core Data 管理
- `UserDefaultsManager.swift` - UserDefaults 封裝

### Extensions/
Swift 擴展：
- `ViewExtensions.swift` - SwiftUI View 擴展
- `ColorExtensions.swift` - Color 擴展
- `StringExtensions.swift` - String 擴展

### Utils/
工具類：
- `DateFormatter.swift` - 日期格式化工具
- `Logger.swift` - 日誌記錄工具