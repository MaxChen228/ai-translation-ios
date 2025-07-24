#!/bin/bash

echo "開始診斷建置..."

# 清理
echo "1. 清理舊的建置資料..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Linker-*

# 設定環境變數來獲得更詳細的輸出
export SWIFT_DETERMINISTIC_HASHING=1

# 簡單建置
echo "2. 執行簡單建置..."
xcodebuild -project Linker.xcodeproj \
  -scheme Linker \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
  -derivedDataPath ./DerivedData \
  build \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  -verbose 2>&1 | tee build_log.txt

echo "建置完成，請檢查 build_log.txt"