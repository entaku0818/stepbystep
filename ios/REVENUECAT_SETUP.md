# RevenueCat サブスクリプション設定ガイド

## 1. App Store Connect での準備

### サブスクリプショングループとプロダクトの作成

1. [App Store Connect](https://appstoreconnect.apple.com) にログイン
2. アプリを選択 → 「App内課金」→「作成」をクリック
3. 以下の情報で自動更新サブスクリプションを作成：
   - **参照名**: Task Steps Pro Monthly
   - **プロダクトID**: `com.entaku.stepTask.pro.subscription.monthly`
   - **サブスクリプショングループ**: Task Steps Pro (新規作成)
   - **期間**: 1ヶ月
   - **価格**: 500円（Tier 3）

### ローカライゼーション設定
- **表示名**: Task Steps Pro
- **説明**: 無制限のタスク分割、広告なし、優先サポート

## 2. RevenueCat Dashboard での設定

1. [RevenueCat](https://app.revenuecat.com) でアカウント作成
2. 新しいプロジェクトを作成
3. App Store Connect API キーを設定：
   - App Store Connect → ユーザーとアクセス → キー
   - 新しいキーを作成（役割: App Manager）
   - RevenueCatにアップロード

4. 製品を設定：
   - プロダクトID: `com.entaku.stepTask.pro.subscription.monthly`
   - エンタイトルメント: `pro`

5. API キーを取得（後でコードで使用）

## 3. Xcode プロジェクトの設定

### Swift Package Manager で RevenueCat を追加

1. Xcode でプロジェクトを開く
2. File → Add Package Dependencies
3. URL: `https://github.com/RevenueCat/purchases-ios.git`
4. Version: Up to Next Major → 4.0.0

### In-App Purchase 権限を追加

1. プロジェクトナビゲータでプロジェクトを選択
2. Signing & Capabilities タブ
3. "+ Capability" → "In-App Purchase" を追加

### Entitlements ファイルの作成

自動的に作成される `TaskSteps.entitlements` に以下が追加されることを確認：
```xml
<key>com.apple.developer.in-app-payments</key>
<array>
    <string>com.entaku.stepTask.pro.subscription.monthly</string>
</array>
```

## 4. 実装手順

### 環境変数の追加

`Debug.xcconfig` と `Release.xcconfig` に追加：
```
REVENUECAT_API_KEY = your_revenuecat_api_key_here
```

### AppConfig.swift に追加
```swift
static var revenueCatApiKey: String {
    guard let key = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String else {
        fatalError("RevenueCatAPIKey not found in Info.plist")
    }
    return key
}
```

### Info.plist に追加
```xml
<key>RevenueCatAPIKey</key>
<string>$(REVENUECAT_API_KEY)</string>
```

## 5. テスト

### Sandbox テスターの設定

1. App Store Connect → ユーザーとアクセス → Sandbox テスター
2. 新しいテスターを作成
3. デバイスでサインアウトし、テストアカウントでサインイン

### 購入フローのテスト

1. アプリを実行
2. サブスクリプション画面を開く
3. 購入ボタンをタップ
4. Sandboxアカウントでサインイン
5. 購入確認

## 6. 審査準備

### 審査ノート
- テスト用アカウント情報を提供
- サブスクリプションの利点を明記
- キャンセル方法の説明を含める

### スクリーンショット
- サブスクリプション画面
- 購入フロー
- Pro機能の説明