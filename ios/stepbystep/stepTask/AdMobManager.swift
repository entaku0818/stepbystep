import UIKit
import GoogleMobileAds
import Dependencies

// MARK: - AdMob Manager

class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()
    
    @Published var isAdLoaded = false
    @Published var isShowingAd = false
    
    private var rewardedAd: GADRewardedAd?
    private var isAdLoading = false
    
    // テスト用広告ユニットID（本番時は実際のIDに変更）
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313" // テスト用ID
    
    override init() {
        super.init()
        configureAdMob()
    }
    
    private func configureAdMob() {
        // AdMobの初期化
        GADMobileAds.sharedInstance().start { _ in
            print("AdMob initialized")
        }
        
        // 広告をプリロード
        loadRewardedAd()
    }
    
    /// リワード広告を読み込み
    func loadRewardedAd() {
        guard !isAdLoading else { return }
        
        isAdLoading = true
        
        let request = GADRequest()
        
        GADRewardedAd.load(withAdUnitID: rewardedAdUnitID, request: request) { [weak self] ad, error in
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
        
        rewardedAd.present(fromRootViewController: rootViewController) { [weak self] in
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

extension AdMobManager: GADFullScreenContentDelegate {
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("Ad recorded an impression")
    }
    
    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        print("Ad recorded a click")
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present: \(error.localizedDescription)")
        isShowingAd = false
        loadRewardedAd() // 失敗した場合は新しい広告を読み込み
    }
    
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad will present")
        isShowingAd = true
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad dismissed")
        isShowingAd = false
        rewardedAd = nil
        isAdLoaded = false
        loadRewardedAd() // 次の広告をプリロード
    }
}

// MARK: - Ad Client Protocol

protocol AdClient {
    func loadAd() async
    func showAd() async -> Bool
    var isAdAvailable: Bool { get async }
}

// MARK: - Live Ad Client

class LiveAdClient: AdClient {
    private let adManager = AdMobManager.shared
    
    func loadAd() async {
        await MainActor.run {
            adManager.loadRewardedAd()
        }
    }
    
    func showAd() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.adManager.showRewardedAd { success in
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    var isAdAvailable: Bool {
        get async {
            await MainActor.run {
                return adManager.isAdAvailable
            }
        }
    }
}

// MARK: - Mock Ad Client (テスト用)

class MockAdClient: AdClient {
    private var _isAdAvailable = true
    
    func loadAd() async {
        // テスト用：即座に読み込み完了
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        _isAdAvailable = true
        print("Mock ad loaded")
    }
    
    func showAd() async -> Bool {
        guard _isAdAvailable else { return false }
        
        // テスト用：2秒間の疑似広告表示
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒待機
        print("Mock ad shown")
        
        // 次の広告をプリロード
        await loadAd()
        
        return true
    }
    
    var isAdAvailable: Bool {
        get async {
            return _isAdAvailable
        }
    }
}

// MARK: - Dependency Key

private enum AdClientKey: DependencyKey {
    static let liveValue: AdClient = LiveAdClient()
    static let testValue: AdClient = MockAdClient()
}

extension DependencyValues {
    var adClient: AdClient {
        get { self[AdClientKey.self] }
        set { self[AdClientKey.self] = newValue }
    }
}