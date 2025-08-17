import UIKit
import GoogleMobileAds
import Dependencies

// MARK: - AdMob Manager

class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()
    
    @Published var isAdLoaded = false
    @Published var isShowingAd = false
    
    private var rewardedAd: RewardedAd?
    private var isAdLoading = false
    
    // 広告ユニットID（環境変数から取得）
    private let rewardedAdUnitID = AppConfig.adMobRewardedAdUnitId
    
    override init() {
        super.init()
        configureAdMob()
    }
    
    private func configureAdMob() {
        // AdMobの初期化
        MobileAds.shared.start { _ in
            print("AdMob initialized")
        }
        
        // 広告をプリロード
        loadRewardedAd()
    }
    
    /// リワード広告を読み込み
    func loadRewardedAd() {
        guard !isAdLoading else { return }
        
        isAdLoading = true
        
        let request = Request()
        
        RewardedAd.load(with: rewardedAdUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isAdLoading = false
                
                if let error = error {
                    print("Failed to load rewarded ad: \(error.localizedDescription)")
                    self?.isAdLoaded = false
                    return
                }
                
                print("Rewarded ad loaded successfully")
                self?.rewardedAd = ad
                self?.isAdLoaded = true
                
                // デリゲートを設定
                self?.rewardedAd?.fullScreenContentDelegate = self
            }
        }
    }
    
    /// リワード広告を表示
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        guard let rewardedAd = rewardedAd, isAdLoaded else {
            print("Rewarded ad is not ready")
            completion(false)
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Could not find root view controller")
            completion(false)
            return
        }
        
        isShowingAd = true
        
        rewardedAd.present(from: rootViewController) { [weak self] in
            print("User earned reward")
            completion(true)
            
            // 広告表示後、次の広告をプリロード
            self?.loadRewardedAd()
        }
    }
    
    /// 広告が利用可能かチェック
    var isAdAvailable: Bool {
        return isAdLoaded && rewardedAd != nil
    }
}

// MARK: - GADFullScreenContentDelegate

extension AdMobManager: FullScreenContentDelegate {
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("Ad recorded an impression")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("Ad recorded a click")
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present: \(error.localizedDescription)")
        isShowingAd = false
        loadRewardedAd() // 失敗した場合は新しい広告を読み込み
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad will present")
        isShowingAd = true
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad dismissed")
        isShowingAd = false
        rewardedAd = nil
        isAdLoaded = false
        loadRewardedAd() // 次の広告をプリロード
    }
}

// MARK: - Ad Client

struct AdClient {
    var loadAd: () async -> Void
    var showAd: () async -> Bool
    var isAdAvailable: () async -> Bool
}

// MARK: - Live Implementation

extension AdClient {
    static let live = Self(
        loadAd: {
            await MainActor.run {
                AdMobManager.shared.loadRewardedAd()
            }
        },
        showAd: {
            await withCheckedContinuation { continuation in
                DispatchQueue.main.async {
                    AdMobManager.shared.showRewardedAd { success in
                        continuation.resume(returning: success)
                    }
                }
            }
        },
        isAdAvailable: {
            await MainActor.run {
                AdMobManager.shared.isAdAvailable
            }
        }
    )
}

// MARK: - Test Implementation

extension AdClient {
    static let test = Self(
        loadAd: {
            // テスト用：即座に読み込み完了
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
            print("Mock ad loaded")
        },
        showAd: {
            // テスト用：2秒間の疑似広告表示
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒待機
            print("Mock ad shown")
            return true
        },
        isAdAvailable: {
            return true
        }
    )
    
    static let testNoAds = Self(
        loadAd: { },
        showAd: { false },
        isAdAvailable: { false }
    )
}

// MARK: - Dependency Key

private enum AdClientKey: DependencyKey {
    static let liveValue = AdClient.live
    static let testValue = AdClient.test
}

extension DependencyValues {
    var adClient: AdClient {
        get { self[AdClientKey.self] }
        set { self[AdClientKey.self] = newValue }
    }
}
