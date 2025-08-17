//
//  SubscriptionView.swift
//  TaskSteps
//
//  サブスクリプション画面
//

import SwiftUI
import ComposableArchitecture
import Dependencies

// MARK: - Subscription Reducer

@Reducer
struct SubscriptionReducer {
    @ObservableState
    struct State: Equatable {
        var isProUser = false
        var isPurchasing = false
        var isRestoring = false
        var errorMessage: String?
        var showSuccessAlert = false
        var selectedSubscription: SubscriptionType = .monthly
        var price: String?
        var isLoadingPrice = false
    }
    
    enum Action {
        case onAppear
        case proStatusUpdated(Bool)
        case priceUpdated(String?)
        case purchaseButtonTapped
        case purchaseCompleted(Bool)
        case purchaseFailed(String)
        case restoreButtonTapped
        case restoreCompleted(Bool)
        case restoreFailed(String)
        case dismissError
        case dismissSuccessAlert
    }
    
    @Dependency(\.revenueCatClient) var revenueCatClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.isPresented) var isPresented
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoadingPrice = true
                return .run { send in
                    await revenueCatClient.checkSubscriptionStatus()
                    let isProUser = await revenueCatClient.isProUser()
                    await send(.proStatusUpdated(isProUser))
                    
                    // RevenueCatから価格情報を取得
                    if let priceString = await RevenueCatManager.shared.getPriceString() {
                        await send(.priceUpdated(priceString))
                    } else {
                        // 価格が取得できない場合のフォールバック
                        await send(.priceUpdated(nil))
                    }
                }
                
            case let .proStatusUpdated(isPro):
                state.isProUser = isPro
                return .none
                
            case let .priceUpdated(price):
                state.price = price
                state.isLoadingPrice = false
                return .none
                
            case .purchaseButtonTapped:
                guard !state.isPurchasing else { return .none }
                state.isPurchasing = true
                state.errorMessage = nil
                
                return .run { [subscription = state.selectedSubscription] send in
                    do {
                        try await revenueCatClient.purchase(subscription)
                        let isProUser = await revenueCatClient.isProUser()
                        await send(.purchaseCompleted(isProUser))
                    } catch {
                        await send(.purchaseFailed(error.localizedDescription))
                    }
                }
                
            case let .purchaseCompleted(success):
                state.isPurchasing = false
                if success {
                    state.isProUser = true
                    state.showSuccessAlert = true
                }
                return .none
                
            case let .purchaseFailed(error):
                state.isPurchasing = false
                state.errorMessage = error
                return .none
                
            case .restoreButtonTapped:
                guard !state.isRestoring else { return .none }
                state.isRestoring = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        try await revenueCatClient.restorePurchases()
                        let isProUser = await revenueCatClient.isProUser()
                        await send(.restoreCompleted(isProUser))
                    } catch {
                        await send(.restoreFailed(error.localizedDescription))
                    }
                }
                
            case let .restoreCompleted(success):
                state.isRestoring = false
                if success {
                    state.isProUser = true
                    state.showSuccessAlert = true
                } else {
                    state.errorMessage = "復元可能な購入が見つかりませんでした"
                }
                return .none
                
            case let .restoreFailed(error):
                state.isRestoring = false
                state.errorMessage = error
                return .none
                
            case .dismissError:
                state.errorMessage = nil
                return .none
                
            case .dismissSuccessAlert:
                state.showSuccessAlert = false
                // ビューが表示されている場合のみdismiss
                if isPresented {
                    return .run { _ in
                        await self.dismiss()
                    }
                } else {
                    return .none
                }
            }
        }
    }
}

// MARK: - Subscription View

struct SubscriptionView: View {
    let store: StoreOf<SubscriptionReducer>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    headerSection
                    
                    // 機能リスト
                    featuresSection
                    
                    // 価格と購入ボタン
                    if !store.isProUser {
                        purchaseSection
                    } else {
                        proUserSection
                    }
                    
                    // 復元ボタン
                    if !store.isProUser {
                        restoreSection
                    }
                    
                    // 注意事項
                    termsSection
                }
                .padding()
            }
            .navigationTitle("Task Steps Pro")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        store.send(.dismissSuccessAlert)
                    }
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
            .alert("エラー", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { _ in store.send(.dismissError) }
            )) {
                Button("OK") {
                    store.send(.dismissError)
                }
            } message: {
                Text(store.errorMessage ?? "")
            }
            .alert("購入完了", isPresented: Binding(
                get: { store.showSuccessAlert },
                set: { _ in store.send(.dismissSuccessAlert) }
            )) {
                Button("OK") {
                    store.send(.dismissSuccessAlert)
                }
            } message: {
                Text("Task Steps Proへようこそ！\n無制限でタスク分割をお楽しみください。")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.3), radius: 10)
            
            Text("Task Steps Pro")
                .font(.title)
                .fontWeight(.bold)
            
            Text("無制限のタスク分割で\n生産性を最大化")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pro会員の特典")
                .font(.headline)
            
            ForEach(SubscriptionType.monthly.features, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    
                    Text(feature)
                        .font(.body)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("月額プラン")
                    .font(.headline)
                
                // RevenueCatから取得した価格を表示
                if let price = store.price {
                    Text(price)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                } else {
                    Text("読み込み中...")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
                
                Text("/ 月")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                store.send(.purchaseButtonTapped)
            }) {
                HStack {
                    if store.isPurchasing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Text("今すぐ始める")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
            }
            .disabled(store.isPurchasing || store.isRestoring)
            
            Text("いつでもキャンセル可能")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Pro User Section
    
    private var proUserSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Pro会員です")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("無制限でタスク分割をご利用いただけます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Restore Section
    
    private var restoreSection: some View {
        Button(action: {
            store.send(.restoreButtonTapped)
        }) {
            HStack {
                if store.isRestoring {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("購入を復元")
                }
            }
            .font(.body)
            .foregroundColor(.blue)
        }
        .disabled(store.isPurchasing || store.isRestoring)
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("サブスクリプションについて")
                .font(.caption)
                .fontWeight(.semibold)
            
            Text("""
                • お支払いは購入確認時にApple IDアカウントに請求されます
                • サブスクリプションは自動的に更新されます
                • 現在の期間終了の24時間前までにキャンセルすれば更新されません
                • アカウント設定から管理・キャンセルできます
                """)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 16) {
                Link("利用規約", destination: URL(string: "https://example.com/terms")!)
                Link("プライバシーポリシー", destination: URL(string: "https://example.com/privacy")!)
            }
            .font(.caption)
        }
        .padding(.top)
    }
}