#!/bin/bash

echo "🔧 重置 Xcode 專案..."

# 1. 關閉 Xcode
echo "⚠️  請先關閉 Xcode！"
echo "按 Enter 繼續..."
read

# 2. 清理所有快取
echo "🗑️  清理快取..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Linker-*
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf ~/Library/Caches/com.apple.dt.Xcode/
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/

# 3. 清理專案內的 SwiftPM 資料
echo "🧹 清理專案 SwiftPM 資料..."
rm -rf .swiftpm/
rm -rf Linker.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
rm -rf Linker.xcodeproj/project.xcworkspace/xcuserdata/

# 4. 重新解析套件
echo "📦 重新解析套件依賴..."
xcodebuild -resolvePackageDependencies -project Linker.xcodeproj

echo "✅ 重置完成！"
echo ""
echo "請執行以下步驟："
echo "1. 開啟 Xcode"
echo "2. 選擇 File > Packages > Reset Package Caches"
echo "3. 選擇 File > Packages > Update to Latest Package Versions"
echo "4. 清理建置資料夾 (Cmd + Shift + K)"
echo "5. 重新建置 (Cmd + B)"