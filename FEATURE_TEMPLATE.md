# iOS 新功能模板

使用此模板為 iOS 專案添加新功能模組。

## 資料夾結構

在 `Features/` 目錄下建立新功能資料夾：

```
Features/
└── YourFeatureName/
    ├── Models/
    │   └── YourFeatureModel.swift
    ├── ViewModels/
    │   └── YourFeatureViewModel.swift
    ├── Views/
    │   ├── YourFeatureView.swift
    │   └── Components/
    │       └── YourFeatureComponent.swift
    └── Services/
        └── YourFeatureService.swift
```

## 檔案模板

### Model 模板 (Models/YourFeatureModel.swift)
```swift
import Foundation

// MARK: - YourFeature Model
struct YourFeatureModel: Codable, Identifiable {
    let id: Int
    // 其他屬性
    
    enum CodingKeys: String, CodingKey {
        case id
        // 映射 API 欄位
    }
}
```

### ViewModel 模板 (ViewModels/YourFeatureViewModel.swift)
```swift
import SwiftUI
import Combine

@MainActor
final class YourFeatureViewModel: ObservableObject {
    // MARK: - Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service: YourFeatureService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(service: YourFeatureService = YourFeatureService()) {
        self.service = service
    }
    
    // MARK: - Methods
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 調用 service 載入資料
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
```

### View 模板 (Views/YourFeatureView.swift)
```swift
import SwiftUI

struct YourFeatureView: View {
    @StateObject private var viewModel = YourFeatureViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                // 主要內容
            }
        }
        .navigationTitle("Your Feature")
        .task {
            await viewModel.loadData()
        }
        .alert("錯誤", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("確定") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    NavigationView {
        YourFeatureView()
    }
}
```

### Service 模板 (Services/YourFeatureService.swift)
```swift
import Foundation

final class YourFeatureService {
    private let apiService: UnifiedAPIServiceProtocol
    
    init(apiService: UnifiedAPIServiceProtocol = UnifiedAPIService.shared) {
        self.apiService = apiService
    }
    
    func fetchData() async throws -> [YourFeatureModel] {
        // 實現 API 調用
        return try await apiService.request(
            endpoint: .yourFeature,
            method: .get,
            responseType: [YourFeatureModel].self
        )
    }
}
```

## 整合步驟

1. **建立功能資料夾**
   ```bash
   mkdir -p Features/YourFeature/{Models,ViewModels,Views,Services}
   ```

2. **建立檔案**
   - 使用上述模板建立對應檔案
   - 根據實際需求調整內容

3. **更新導航**
   - 在主要導航中添加新功能的入口
   - 更新 TabView 或 NavigationView

4. **添加 API 端點**
   - 在 `APIEndpoint.swift` 中添加新的端點
   - 在 `UnifiedAPIService.swift` 中實現對應方法（如需要）

5. **測試**
   - 建立單元測試
   - 建立 UI 測試
   - 手動測試功能流程

## 最佳實踐

1. **遵循 MVVM 模式**
   - View 只負責顯示
   - ViewModel 處理業務邏輯
   - Service 處理 API 調用

2. **錯誤處理**
   - 在 ViewModel 中統一處理錯誤
   - 提供用戶友好的錯誤訊息

3. **異步操作**
   - 使用 async/await
   - 顯示載入狀態

4. **可測試性**
   - 使用依賴注入
   - 提供 Mock 實現

5. **設計一致性**
   - 使用 DesignSystem 中的組件和樣式
   - 保持 UI 風格統一