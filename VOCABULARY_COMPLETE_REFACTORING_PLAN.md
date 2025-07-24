# 單字系統徹底重構方案

## 一、現狀問題總結

### 1. 架構層面的根本問題
- **服務層分裂**：VocabularyService 和 MultiClassificationService 使用完全不同的架構模式
- **狀態管理混亂**：缺乏統一的狀態管理，各服務各自維護狀態
- **錯誤處理不一致**：多種錯誤類型和處理方式並存
- **缺乏抽象層**：直接依賴具體實現，難以測試和擴展

### 2. 技術債務清單
- 重複的模型定義（單字、分類、統計等）
- 硬編碼的 API 端點
- 缺乏緩存機制
- 沒有重試策略
- 測試困難（單例依賴）
- 類型不安全（需要處理多種數據格式）

## 二、重構目標

### 核心原則
1. **統一性**：所有 Vocabulary 相關功能使用一致的架構
2. **可測試性**：通過依賴注入和協議導向設計實現高測試覆蓋率
3. **可維護性**：清晰的分層和職責分離
4. **性能優化**：智能緩存和預加載
5. **錯誤韌性**：完善的錯誤處理和降級策略

## 三、新架構設計

### 3.1 分層架構

```
┌─────────────────────────────────────────────────────┐
│                   Presentation Layer                 │
│              (Views & ViewModels)                    │
├─────────────────────────────────────────────────────┤
│                   Domain Layer                       │
│           (Use Cases & Business Logic)               │
├─────────────────────────────────────────────────────┤
│                 Repository Layer                     │
│            (Data Access Abstraction)                 │
├─────────────────────────────────────────────────────┤
│                   Data Layer                         │
│      ┌────────────────┬────────────────┐           │
│      │  Remote Data   │   Local Data   │           │
│      │   (API)        │   (Cache)      │           │
│      └────────────────┴────────────────┘           │
└─────────────────────────────────────────────────────┘
```

### 3.2 核心組件設計

#### 1. 統一的數據模型（Domain Models）

```swift
// MARK: - 核心領域模型
struct Vocabulary {
    let id: VocabularyID  // 複合ID支持
    let word: String
    let pronunciation: Pronunciation?
    let definitions: [Definition]
    let difficulty: Difficulty
    let mastery: MasteryInfo
    let classifications: [Classification]
    let metadata: VocabularyMetadata
}

struct VocabularyID {
    let value: String
    let source: Source
    
    enum Source {
        case system(Int)
        case user(String)
        case builtin(Int)
    }
}

struct MasteryInfo {
    let level: Double  // 0-5
    let status: MasteryStatus
    let reviews: ReviewHistory
    let nextReviewDate: Date?
}

struct Classification {
    let system: ClassificationSystem
    let category: String
    let level: String?
}
```

#### 2. Repository 協議

```swift
protocol VocabularyRepository {
    // 統計
    func getStatistics() async throws -> VocabularyStatistics
    
    // 單字查詢
    func getWords(
        scope: VocabularyScope,
        filter: VocabularyFilter?,
        pagination: Pagination
    ) async throws -> PaginatedResult<Vocabulary>
    
    // 單字詳情
    func getWordDetail(id: VocabularyID) async throws -> Vocabulary
    
    // 學習管理
    func addToLearning(id: VocabularyID) async throws -> Vocabulary
    func removeFromLearning(id: VocabularyID) async throws
    
    // 複習
    func submitReview(
        id: VocabularyID,
        result: ReviewResult
    ) async throws -> MasteryUpdate
    
    // 分類系統
    func getClassificationSystems() async throws -> [ClassificationSystem]
    func getWordsInCategory(
        system: String,
        category: String,
        pagination: Pagination
    ) async throws -> PaginatedResult<Vocabulary>
}

enum VocabularyScope {
    case all
    case learning
    case available
    case mastered
    case favorite
}
```

#### 3. 實現層

```swift
// MARK: - Repository 實現
final class DefaultVocabularyRepository: VocabularyRepository {
    private let remoteDataSource: VocabularyRemoteDataSource
    private let localDataSource: VocabularyLocalDataSource
    private let mapper: VocabularyDataMapper
    
    init(
        remoteDataSource: VocabularyRemoteDataSource,
        localDataSource: VocabularyLocalDataSource,
        mapper: VocabularyDataMapper
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.mapper = mapper
    }
    
    func getStatistics() async throws -> VocabularyStatistics {
        // 1. 嘗試從緩存獲取
        if let cached = await localDataSource.getCachedStatistics(),
           !cached.isExpired {
            return cached.data
        }
        
        // 2. 從遠程獲取
        do {
            let response = try await remoteDataSource.fetchStatistics()
            let statistics = mapper.mapToStatistics(response)
            
            // 3. 更新緩存
            await localDataSource.cacheStatistics(statistics)
            
            return statistics
        } catch {
            // 4. 錯誤時返回緩存（如果有）
            if let cached = await localDataSource.getCachedStatistics() {
                return cached.data
            }
            throw error
        }
    }
}
```

#### 4. 網絡層重構

```swift
// MARK: - API 端點定義
enum VocabularyEndpoint: APIEndpoint {
    case statistics
    case words(scope: String, page: Int, limit: Int)
    case wordDetail(id: Int)
    case addToLearning(id: Int)
    case removeFromLearning(id: Int)
    case submitReview(id: Int)
    case dailyReview(limit: Int)
    case classificationSystems
    case categoryWords(system: String, category: String, page: Int)
    
    var path: String {
        switch self {
        case .statistics:
            return "/vocabulary/statistics"
        case .words:
            return "/vocabulary/words"
        case .wordDetail(let id):
            return "/vocabulary/words/\(id)"
        case .addToLearning(let id):
            return "/vocabulary/words/\(id)/learn"
        case .removeFromLearning(let id):
            return "/vocabulary/words/\(id)/learn"
        case .submitReview(let id):
            return "/vocabulary/words/\(id)/review"
        case .dailyReview:
            return "/vocabulary/review/daily"
        case .classificationSystems:
            return "/vocabulary/classifications/systems"
        case .categoryWords:
            return "/vocabulary/classifications/words"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .addToLearning, .submitReview:
            return .post
        case .removeFromLearning:
            return .delete
        default:
            return .get
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .words(let scope, let page, let limit):
            return ["scope": scope, "page": page, "limit": limit]
        case .dailyReview(let limit):
            return ["limit": limit]
        case .categoryWords(let system, let category, let page):
            return ["system": system, "category": category, "page": page]
        default:
            return nil
        }
    }
}
```

#### 5. 統一的 ViewModel

```swift
@MainActor
final class VocabularyViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var viewState: ViewState = .idle
    @Published private(set) var statistics: VocabularyStatistics?
    @Published private(set) var words: [Vocabulary] = []
    @Published private(set) var selectedWord: Vocabulary?
    @Published private(set) var classifications: [ClassificationSystem] = []
    
    // MARK: - Dependencies
    private let repository: VocabularyRepository
    private let errorHandler: ErrorHandler
    private let analytics: AnalyticsService
    
    // MARK: - Pagination
    private var currentPage = 1
    private var hasMorePages = true
    private var isLoadingMore = false
    
    // MARK: - Initialization
    init(
        repository: VocabularyRepository,
        errorHandler: ErrorHandler,
        analytics: AnalyticsService
    ) {
        self.repository = repository
        self.errorHandler = errorHandler
        self.analytics = analytics
    }
    
    // MARK: - Public Methods
    func loadStatistics() async {
        await performAction {
            self.statistics = try await self.repository.getStatistics()
        }
    }
    
    func loadWords(scope: VocabularyScope, refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            hasMorePages = true
            words = []
        }
        
        guard !isLoadingMore && hasMorePages else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        await performAction {
            let result = try await self.repository.getWords(
                scope: scope,
                filter: nil,
                pagination: Pagination(page: self.currentPage, limit: 20)
            )
            
            if refresh {
                self.words = result.items
            } else {
                self.words.append(contentsOf: result.items)
            }
            
            self.hasMorePages = result.hasNextPage
            self.currentPage += 1
        }
    }
    
    // MARK: - Private Methods
    private func performAction(_ action: @escaping () async throws -> Void) async {
        viewState = .loading
        
        do {
            try await action()
            viewState = .loaded
        } catch {
            viewState = .error(errorHandler.handle(error))
            analytics.logError(error)
        }
    }
}

// MARK: - View State
extension VocabularyViewModel {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case error(UserFacingError)
    }
}
```

### 3.3 錯誤處理體系

```swift
// MARK: - 統一錯誤類型
enum VocabularyError: LocalizedError {
    case networkError(NetworkError)
    case dataError(DataError)
    case businessError(BusinessError)
    
    enum NetworkError {
        case noConnection
        case timeout
        case serverError(statusCode: Int)
        case invalidResponse
    }
    
    enum DataError {
        case decodingFailed
        case cachingFailed
        case invalidData
    }
    
    enum BusinessError {
        case wordNotFound
        case alreadyLearning
        case reviewTooSoon
        case quotaExceeded
    }
}

// MARK: - 錯誤處理器
protocol ErrorHandler {
    func handle(_ error: Error) -> UserFacingError
}

struct UserFacingError: Equatable {
    let title: String
    let message: String
    let actions: [ErrorAction]
}

enum ErrorAction {
    case retry(() -> Void)
    case dismiss
    case openSettings
}
```

### 3.4 緩存策略

```swift
// MARK: - 緩存管理
protocol CachePolicy {
    var expirationTime: TimeInterval { get }
    var maxSize: Int { get }
}

struct VocabularyCachePolicy: CachePolicy {
    var expirationTime: TimeInterval {
        switch cacheType {
        case .statistics: return 300 // 5分鐘
        case .wordList: return 600 // 10分鐘
        case .wordDetail: return 3600 // 1小時
        case .classifications: return 86400 // 1天
        }
    }
    
    var maxSize: Int {
        switch cacheType {
        case .statistics: return 1
        case .wordList: return 100
        case .wordDetail: return 500
        case .classifications: return 10
        }
    }
    
    private let cacheType: CacheType
    
    enum CacheType {
        case statistics
        case wordList
        case wordDetail
        case classifications
    }
}
```

## 四、實施計劃

### Phase 1: 基礎架構搭建（3天）
1. 創建新的領域模型
2. 定義 Repository 協議
3. 實現數據映射器
4. 設置依賴注入容器

### Phase 2: 數據層實現（4天）
1. 實現遠程數據源（統一 API 調用）
2. 實現本地數據源（緩存）
3. 實現 Repository
4. 添加錯誤處理

### Phase 3: 視圖層重構（4天）
1. 創建統一的 ViewModel
2. 重構現有視圖使用新 ViewModel
3. 實現加載狀態和錯誤處理 UI
4. 添加下拉刷新和無限滾動

### Phase 4: 測試和優化（3天）
1. 編寫單元測試
2. 編寫集成測試
3. 性能優化
4. 修復發現的問題

### Phase 5: 遷移和部署（2天）
1. 數據遷移腳本
2. A/B 測試配置
3. 監控設置
4. 逐步發布

## 五、測試策略

### 單元測試
```swift
class VocabularyRepositoryTests: XCTestCase {
    var sut: VocabularyRepository!
    var mockRemoteDataSource: MockVocabularyRemoteDataSource!
    var mockLocalDataSource: MockVocabularyLocalDataSource!
    
    override func setUp() {
        super.setUp()
        mockRemoteDataSource = MockVocabularyRemoteDataSource()
        mockLocalDataSource = MockVocabularyLocalDataSource()
        sut = DefaultVocabularyRepository(
            remoteDataSource: mockRemoteDataSource,
            localDataSource: mockLocalDataSource,
            mapper: VocabularyDataMapper()
        )
    }
    
    func testGetStatistics_WithCache_ReturnsCache() async throws {
        // Given
        let cachedStats = VocabularyStatistics.fixture()
        mockLocalDataSource.cachedStatistics = CachedData(
            data: cachedStats,
            timestamp: Date()
        )
        
        // When
        let result = try await sut.getStatistics()
        
        // Then
        XCTAssertEqual(result, cachedStats)
        XCTAssertFalse(mockRemoteDataSource.fetchStatisticsCalled)
    }
}
```

## 六、風險和緩解措施

| 風險 | 影響 | 緩解措施 |
|------|------|----------|
| 大規模重構導致新 bug | 用戶體驗下降 | 漸進式發布，保留回滾能力 |
| 開發時間超預期 | 延遲發布 | 明確的里程碑和每日進度檢查 |
| 性能問題 | 應用卡頓 | 性能測試和監控 |
| 向後兼容性 | 舊版本崩潰 | API 版本控制 |

## 七、成功指標

1. **代碼質量**
   - 測試覆蓋率 > 80%
   - 零重複代碼
   - 一致的架構模式

2. **性能指標**
   - API 響應時間 < 200ms（緩存命中）
   - 內存使用減少 30%
   - 啟動時間 < 2秒

3. **可維護性**
   - 新功能開發時間減少 50%
   - Bug 修復時間減少 60%
   - 新開發者上手時間 < 1天

## 八、結論

這個重構方案徹底解決了現有的所有架構問題：

1. **統一的架構**：所有 Vocabulary 功能使用相同的模式
2. **清晰的分層**：各層職責明確，易於維護
3. **完善的錯誤處理**：統一的錯誤類型和處理流程
4. **高測試覆蓋率**：通過依賴注入實現可測試性
5. **性能優化**：智能緩存和預加載策略
6. **未來可擴展**：易於添加新功能

實施這個方案後，Vocabulary 系統將成為一個健壯、可維護、高性能的模組。