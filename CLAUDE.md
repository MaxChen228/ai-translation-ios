# Claude Code 開發協作指南

## 專案概述
這是一個 iOS Linker應用程式，使用 Swift 和 SwiftUI 開發。

## 開發工作流程

### 1. 開發階段
- 使用 TodoWrite 工具追蹤和管理任務進度
- 系統性地修復編譯錯誤和警告
- 遵循現有的程式碼慣例和設計模式

### 2. 測試階段
開發完成後，**必須**執行完整的建置測試：

```bash
cd "/Users/chenliangyu/my_project/core/Linker-ios"
xcodebuild -scheme "Linker" -configuration Debug -destination "platform=iOS Simulator,name=iPhone 16" clean build
```

### 3. 品質確保
- 確保建置過程中**零編譯錯誤**
- 檢查並修復所有警告
- 驗證程式碼符合 Swift 最佳實踐

### 4. Git 提交流程
建置成功且無錯誤後，執行以下步驟：

1. **檢查狀態**：
```bash
git status
git diff
```

2. **添加變更**：
```bash
git add .
```

3. **提交變更**：
```bash
git commit -m "$(cat <<'EOF'
[簡潔描述變更內容]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

4. **推送到 GitHub**：
```bash
git push origin main
```

## 專案結構
```
my_project/
├── 🎯 core/                    # 核心產品代碼
│   ├── Linker-ios/             # 主要iOS應用
│   │   ├── ✨ Features/        # 功能模組
│   │   │   ├── Dashboard/      # 儀表板
│   │   │   ├── Learning/       # AI 學習
│   │   │   └── Authentication/ # 認證系統
│   │   ├── ⚙️ Core/           # 核心功能 (含Logger系統)
│   │   └── 🏠 Areas/          # 主要區域
│   └── backend/               # Flask後端API
├── 🔧 tools/                  # 工具和整合
│   ├── dictionary/            # 韋氏詞典整合
│   ├── database/              # PostgreSQL向量擴展
│   └── helix-engine/          # 記憶演算法引擎
├── 🧪 research/               # 研究和實驗代碼
└── 📚 docs/                   # 統一文檔
```

## 開發規範

### Swift 程式碼風格
- 使用 SwiftUI 和現代 Swift 語法
- 遵循 `@MainActor` 並發模型
- 使用 `async/await` 處理非同步操作
- 保持一致的命名慣例

### 編譯要求
- 目標平台：iOS 17.0+
- 模擬器：iPhone 16
- 建置配置：Debug
- **零編譯錯誤和警告**

### 提交訊息格式
```
[類型]: [簡潔描述]

[詳細說明（可選）]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## 重要提醒
1. **絕對不要**在有編譯錯誤的情況下提交程式碼
2. **每次開發完成後**都要執行完整建置測試
3. **確保**所有變更都經過測試驗證
4. **遵循**現有的程式碼架構和設計模式

## 測試指令快速參考
```bash
# 完整建置測試
cd "/Users/chenliangyu/my_project/core/Linker-ios"
xcodebuild -scheme "Linker" -configuration Debug -destination "platform=iOS Simulator,name=iPhone 16" clean build

# 檢查專案狀態
git status
git diff

# 提交流程
git add .
git commit -m "描述變更內容

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
git push origin main
```

---

*此文件說明了與 Claude Code 協作開發此 iOS 專案的標準工作流程。*