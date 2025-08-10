# RevenueCat & App Store 課金の残タスク

## 概要
RevenueCatの実装は完了していますが、App Store Connectでの設定とXcodeプロジェクトの設定が必要です。

## 残タスク

### 1. App Store Connectでサブスクリプション商品を設定
- [ ] App Store Connectにログイン
- [ ] アプリの「App内課金」セクションに移動
- [ ] 新しい自動更新サブスクリプションを作成
  - 参照名: `Task Steps Pro Monthly`
  - 製品ID: `com.entaku.stepbystep.pro.monthly`
  - 価格: 500円/月
- [ ] サブスクリプショングループを作成
  - グループ参照名: `Task Steps Pro`
- [ ] ローカライゼーション情報を追加
  - 表示名: `Task Steps Pro`
  - 説明: `無制限のタスク分割、広告なし、優先サポート`

### 2. In-App Purchase権限（Entitlements）を追加
- [ ] Xcodeでプロジェクトを開く
- [ ] プロジェクト設定 > Signing & Capabilities
- [ ] "+ Capability"をクリック
- [ ] "In-App Purchase"を追加
- [ ] entitlementsファイルが自動生成されることを確認

### 3. RevenueCat設定の完了
- [ ] RevenueCatダッシュボードでApp Store Connectと連携
- [ ] API Keyを取得してアプリに設定（現在はプレースホルダー）
- [ ] Productsを作成し、App Store Connectの製品IDと紐付け
- [ ] Entitlementsを設定（"pro"エンタイトルメント）
- [ ] Offeringsを設定（"default"オファリング）

### 4. App Store Reviewガイドライン対応
- [ ] プライバシーポリシーへのリンクを確認（実装済み）
- [ ] 利用規約へのリンクを確認（実装済み）
- [ ] サブスクリプションの説明を明確に表示（実装済み）
- [ ] 購入の復元機能を確認（実装済み）

### 5. テスト
- [ ] Sandbox環境でのテストアカウント作成
- [ ] 購入フローのテスト
- [ ] 購入の復元テスト
- [ ] サブスクリプションのキャンセルテスト

## 実装済みの機能
- ✅ RevenueCat SDK統合
- ✅ RevenueCatManager（Dependency Client）
- ✅ サブスクリプション画面UI
- ✅ Pro機能の実装（子タスク分割）
- ✅ 購入・復元のロジック
- ✅ 設定画面からのアクセス

## 注意事項
- RevenueCat API Keyは環境変数またはxcconfigファイルで管理すること
- テスト時はSandbox環境を使用すること
- 本番リリース前に必ずレシート検証が正しく動作することを確認すること

## 参考リンク
- [RevenueCat ドキュメント](https://docs.revenuecat.com/)
- [App Store Connect ヘルプ](https://help.apple.com/app-store-connect/)
- [App Store Review ガイドライン](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)