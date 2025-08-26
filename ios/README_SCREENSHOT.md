# スクリーンショット撮影方法

## UI Testを使用したスクリーンショット撮影

### 1. 基本的な実行方法

```bash
# Xcodeから実行する場合
1. Xcodeでプロジェクトを開く
2. スキームから「stepbystep」を選択
3. Product > Test > ScreenshotUITests を実行

# コマンドラインから実行
xcodebuild test \
  -project stepbystep/TaskSteps.xcodeproj \
  -scheme stepbystep \
  -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
  -only-testing:stepbystepUITests/ScreenshotUITests/testCaptureAllScreenshots
```

### 2. Fastlaneを使用した自動撮影

```bash
cd ios

# fastlane snapshotを実行
fastlane screenshots

# フレーム付きスクリーンショットを生成
fastlane framed_screenshots
```

### 3. 出力場所

- **Xcode UI Test**: Test Reportに添付される
- **Fastlane**: `ios/screenshots/` ディレクトリに保存

### 4. デバイス設定

`fastlane/Snapfile` で設定変更可能:
- iPhone 15 Pro
- iPhone 15 Pro Max
- iPad Pro (12.9-inch)

### 5. トラブルシューティング

デバッグメニューが表示されない場合:
1. アプリの設定画面を確認
2. デバッグビルドであることを確認
3. UI要素のアクセシビリティIDを確認