//
//  RevenueCatManager.swift
//  TaskSteps
//
//  RevenueCat サブスクリプション管理
//

import Foundation
import SwiftUI
import RevenueCat
import Dependencies

// MARK: - Subscription Types

enum SubscriptionType: String, CaseIterable {
    case monthly = "com.entaku.stepTask.pro.monthly"
    
    var displayName: String {
        switch self {
        case .monthly:
            return "Task Steps Pro"
        }
    }
    
    var features: [String] {
        return [
            "無制限のタスク分割",
            "ステップを子タスクに分割",
            "広告なし体験",
        ]
    }
}

// MARK: - RevenueCat Manager

@MainActor
class RevenueCatManager: NSObject, ObservableObject {
    static let shared = RevenueCatManager()
    
    @Published var isProUser = false
    @Published var offerings: Offerings?
    @Published var purchaseInProgress = false
    @Published var error: String?
    
    private override init() {
        super.init()
    }
    
    /// RevenueCatを初期化
    func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        print("🔵 [RevenueCat] Configuring with API key: \(AppConfig.revenueCatApiKey.prefix(10))...")
        #endif
        
        // APIキーの検証
        let apiKey = AppConfig.revenueCatApiKey
        
        do {
            Purchases.configure(withAPIKey: apiKey)
            
            // デリゲートを設定
            Purchases.shared.delegate = self
            
            // 購入者情報を取得
            checkSubscriptionStatus()
        } catch {
            print("❌ [RevenueCat] Failed to configure: \(error)")
            self.error = "RevenueCat初期化エラー: \(error.localizedDescription)"
        }
    }
    
    /// サブスクリプション状態をチェック
    func checkSubscriptionStatus() {
        Task {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                await handlePurchaserInfoUpdate(customerInfo)
                
                // オファリングを取得
                let offerings = try await Purchases.shared.offerings()
                await MainActor.run {
                    self.offerings = offerings
                }
            } catch {
                await MainActor.run {
                    self.error = "サブスクリプション情報の取得に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// 価格情報を取得
    func getPriceString() async -> String? {
        guard let offerings = offerings,
              let package = offerings.current?.availablePackages.first else {
            return nil
        }
        return package.localizedPriceString
    }
    
    /// 購入処理
    func purchase(_ productType: SubscriptionType) async throws {
        guard let offerings = offerings,
              let package = offerings.current?.availablePackages.first else {
            throw PurchaseError.productNotFound
        }
        
        await MainActor.run {
            purchaseInProgress = true
            error = nil
        }
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            
            if !result.userCancelled {
                await handlePurchaserInfoUpdate(result.customerInfo)
            }
            
            await MainActor.run {
                purchaseInProgress = false
            }
        } catch {
            await MainActor.run {
                purchaseInProgress = false
                self.error = "購入処理に失敗しました: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// 購入の復元
    func restorePurchases() async {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await handlePurchaserInfoUpdate(customerInfo)
            
            if !isProUser {
                await MainActor.run {
                    self.error = "復元可能な購入が見つかりませんでした"
                }
            }
        } catch {
            await MainActor.run {
                self.error = "購入の復元に失敗しました: \(error.localizedDescription)"
            }
        }
    }
    
    /// 購入者情報の更新を処理
    private func handlePurchaserInfoUpdate(_ customerInfo: CustomerInfo) async {
        await MainActor.run {
            // "pro" エンタイトルメントがアクティブかチェック
            isProUser = customerInfo.entitlements["pro"]?.isActive == true
            
            // 使用制限を更新（UsageLimitManagerに直接アクセス）
            if isProUser {
                UsageLimitManager.shared.setUnlimited(true)
            } else {
                UsageLimitManager.shared.setUnlimited(false)
            }
        }
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            await handlePurchaserInfoUpdate(customerInfo)
        }
    }
}

// MARK: - Purchase Error

enum PurchaseError: LocalizedError {
    case productNotFound
    case purchaseFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "商品が見つかりません"
        case .purchaseFailed(let message):
            return "購入に失敗しました: \(message)"
        }
    }
}

// MARK: - RevenueCat Client

struct RevenueCatClient {
    var isProUser: () async -> Bool
    var purchase: (SubscriptionType) async throws -> Void
    var restorePurchases: () async throws -> Void
    var checkSubscriptionStatus: () async -> Void
    var configure: () -> Void
}

// MARK: - Live Implementation

extension RevenueCatClient {
    static let live = Self(
        isProUser: {
            await MainActor.run {
                RevenueCatManager.shared.isProUser
            }
        },
        purchase: { productType in
            try await RevenueCatManager.shared.purchase(productType)
        },
        restorePurchases: {
            await RevenueCatManager.shared.restorePurchases()
        },
        checkSubscriptionStatus: {
            await MainActor.run {
                RevenueCatManager.shared.checkSubscriptionStatus()
            }
        },
        configure: {
            Task { @MainActor in
                RevenueCatManager.shared.configure()
            }
        }
    )
}

// MARK: - Test Implementation

extension RevenueCatClient {
    static let test = Self(
        isProUser: { false },
        purchase: { _ in
            // テスト用：即座に成功
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
        },
        restorePurchases: {
            // テスト用：復元なし
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        },
        checkSubscriptionStatus: {
            // テスト用：何もしない
        },
        configure: {
            // テスト用：何もしない
        }
    )
    
    static func testPro(isPro: Bool = true) -> Self {
        Self(
            isProUser: { isPro },
            purchase: { _ in },
            restorePurchases: { },
            checkSubscriptionStatus: { },
            configure: { }
        )
    }
}

// MARK: - Dependency Key

private enum RevenueCatClientKey: DependencyKey {
    static let liveValue = RevenueCatClient.live
    static let testValue = RevenueCatClient.test
}

extension DependencyValues {
    var revenueCatClient: RevenueCatClient {
        get { self[RevenueCatClientKey.self] }
        set { self[RevenueCatClientKey.self] = newValue }
    }
}
