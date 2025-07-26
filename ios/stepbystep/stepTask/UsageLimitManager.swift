import Foundation

// MARK: - Usage Limit Manager

final class UsageLimitManager {
    
    // MARK: - Properties
    
    static let shared = UsageLimitManager()
    
    private let userDefaults = UserDefaults.standard
    private let dailyLimit = 3
    private var isUnlimited = false
    
    // UserDefaults Keys
    private let usageCountKey = "ai_split_usage_count"
    private let lastResetDateKey = "ai_split_last_reset_date"
    
    // MARK: - Initialization
    
    private init() {
        checkAndResetIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// 現在の使用回数を取得
    var currentUsageCount: Int {
        checkAndResetIfNeeded()
        return userDefaults.integer(forKey: usageCountKey)
    }
    
    /// 残り使用可能回数を取得
    var remainingUsage: Int {
        if isUnlimited { return 999 } // 無制限の場合
        return max(0, dailyLimit - currentUsageCount)
    }
    
    /// 使用制限に達しているかチェック
    var hasReachedLimit: Bool {
        if isUnlimited { return false } // 無制限の場合は常にfalse
        return currentUsageCount >= dailyLimit
    }
    
    /// 使用回数をインクリメント
    func incrementUsage() {
        checkAndResetIfNeeded()
        let newCount = currentUsageCount + 1
        userDefaults.set(newCount, forKey: usageCountKey)
    }
    
    /// 使用制限メッセージを取得
    func getLimitMessage() -> String {
        if isUnlimited {
            return "Pro会員は無制限でご利用いただけます。"
        } else if hasReachedLimit {
            return "本日のAI分割使用回数（\(dailyLimit)回）に達しました。\nProにアップグレードして無制限で利用しましょう！"
        } else {
            return "本日の残り使用回数: \(remainingUsage)回"
        }
    }
    
    /// Pro会員かどうかを設定
    func setUnlimited(_ unlimited: Bool) {
        isUnlimited = unlimited
    }
    
    /// デバッグ用: 使用回数をリセット
    func resetUsageForDebug() {
        userDefaults.set(0, forKey: usageCountKey)
        userDefaults.set(Date(), forKey: lastResetDateKey)
    }
    
    // MARK: - Private Methods
    
    /// 日付が変わったかチェックし、必要に応じてリセット
    private func checkAndResetIfNeeded() {
        let now = Date()
        
        // 最後のリセット日時を取得
        if let lastResetDate = userDefaults.object(forKey: lastResetDateKey) as? Date {
            // 日付が変わったかチェック
            if !Calendar.current.isDate(lastResetDate, inSameDayAs: now) {
                // 日付が変わったのでリセット
                resetUsage()
            }
        } else {
            // 初回起動時
            resetUsage()
        }
    }
    
    /// 使用回数をリセット
    private func resetUsage() {
        userDefaults.set(0, forKey: usageCountKey)
        userDefaults.set(Date(), forKey: lastResetDateKey)
    }
}