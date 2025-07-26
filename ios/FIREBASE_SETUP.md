# Firebase Setup for Task Steps

## 環境設定ファイルのセットアップ

### 1. xcconfig ファイルの設定

このプロジェクトではセキュリティ上の理由から、環境固有の設定ファイルをGitに含めていません。
以下の手順で設定してください：

1. **Debug.xcconfig の作成**
   ```bash
   cp ios/stepbystep/stepTask/Config/Debug.xcconfig.example ios/stepbystep/stepTask/Config/Debug.xcconfig
   ```

2. **Release.xcconfig の作成**
   ```bash
   cp ios/stepbystep/stepTask/Config/Release.xcconfig.example ios/stepbystep/stepTask/Config/Release.xcconfig
   ```

3. **設定値の更新**
   - Debug.xcconfig: 開発環境用の設定（テスト用AdMob IDなど）
   - Release.xcconfig: 本番環境用の設定（本番用AdMob ID、Firebase URLなど）

### 2. GoogleService-Info.plist の設定

このプロジェクトではセキュリティ上の理由から `GoogleService-Info.plist` をGitに含めていません。
以下の手順でファイルを設定してください：

### 1. Firebase Console から GoogleService-Info.plist をダウンロード

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. `stepbystep-tasks` プロジェクトを選択
3. プロジェクト設定 > 全般 に移動
4. iOS アプリ (`com.entaku.stepTask`) を選択
5. `GoogleService-Info.plist` をダウンロード

### 2. ファイルをプロジェクトに配置

ダウンロードした `GoogleService-Info.plist` を以下の場所に配置：
```
ios/stepbystep/stepTask/GoogleService-Info.plist
```

### 3. Xcode プロジェクトに追加

1. Xcode で TaskSteps.xcodeproj を開く
2. プロジェクトナビゲータで `stepTask` フォルダを右クリック
3. "Add Files to "TaskSteps"..." を選択
4. `GoogleService-Info.plist` を選択
5. "Copy items if needed" にチェック
6. Target: TaskSteps にチェック
7. "Add" をクリック

### 重要な注意事項

- `GoogleService-Info.plist` は機密情報を含むため、絶対にGitにコミットしないでください
- `.gitignore` に既に追加されていますが、誤ってコミットしないよう注意してください
- チーム開発の場合は、安全な方法（1Password、環境変数など）でファイルを共有してください

### APIキーの制限

Firebase Console でAPIキーに適切な制限を設定することを推奨します：

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. APIとサービス > 認証情報 に移動
3. 該当するAPIキーを選択
4. "アプリケーションの制限" で "iOS アプリ" を選択
5. バンドルIDに `com.entaku.stepTask` を追加
6. 保存

これにより、APIキーが漏洩した場合でも、指定したiOSアプリ以外からは使用できなくなります。