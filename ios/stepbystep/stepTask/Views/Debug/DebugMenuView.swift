import SwiftUI
import ComposableArchitecture

// MARK: - Debug Menu Reducer

@Reducer
struct DebugMenuReducer {
    @ObservableState
    struct State: Equatable {
        var showingResetConfirmation = false
        var showingAlert = false
        var alertMessage = ""
        var showingScreenshotView = false
    }
    
    enum Action {
        case resetUsageLimitTapped
        case resetAllDataTapped
        case confirmReset
        case cancelReset
        case setShowingResetConfirmation(Bool)
        case setAlert(Bool, String)
        case toggleUnlimitedUsage
        case forceCrashTapped
        case screenshotModeTapped
        case setShowingScreenshotView(Bool)
    }
    
    @Dependency(\.usageLimitClient) var usageLimitClient
    @Dependency(\.taskStorageClient) var taskStorageClient
    @Dependency(\.revenueCatClient) var revenueCatClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .resetUsageLimitTapped:
                return .run { send in
                    usageLimitClient.resetUsageForDebug()
                    await send(.setAlert(true, "使用回数制限をリセットしました"))
                }
                
            case .resetAllDataTapped:
                state.showingResetConfirmation = true
                return .none
                
            case .confirmReset:
                state.showingResetConfirmation = false
                return .run { send in
                    // Reset all data
                    usageLimitClient.resetUsageForDebug()
                    try? await taskStorageClient.clearAllTasks()
                    await send(.setAlert(true, "すべてのデータをリセットしました"))
                }
                
            case .cancelReset:
                state.showingResetConfirmation = false
                return .none
                
            case let .setShowingResetConfirmation(showing):
                state.showingResetConfirmation = showing
                return .none
                
            case let .setAlert(showing, message):
                state.showingAlert = showing
                state.alertMessage = message
                return .none
                
            case .toggleUnlimitedUsage:
                return .run { _ in
                    let currentUnlimited = usageLimitClient.hasReachedLimit()
                    usageLimitClient.setUnlimited(!currentUnlimited)
                }
                
            case .forceCrashTapped:
                fatalError("Force crash for testing")
                
            case .screenshotModeTapped:
                state.showingScreenshotView = true
                return .none
                
            case let .setShowingScreenshotView(showing):
                state.showingScreenshotView = showing
                return .none
            }
        }
    }
}

// MARK: - Debug Menu View

struct DebugMenuView: View {
    @Bindable var store: StoreOf<DebugMenuReducer>
    @Dependency(\.usageLimitClient) var usageLimitClient
    @Dependency(\.revenueCatClient) var revenueCatClient
    
    var body: some View {
        NavigationStack {
            listContent
        }
    }
    
    @ViewBuilder
    private var listContent: some View {
        List {
            usageLimitSection
            dataManagementSection
            purchaseTestSection
            screenshotSection
            crashTestSection
            appInfoSection
        }
        .navigationTitle("デバッグメニュー")
        .navigationBarTitleDisplayMode(.inline)
        .alert("リセット確認", isPresented: $store.showingResetConfirmation.sending(\.setShowingResetConfirmation)) {
            Button("キャンセル", role: .cancel) {
                store.send(.cancelReset)
            }
            Button("リセット", role: .destructive) {
                store.send(.confirmReset)
            }
        } message: {
            Text("すべてのタスクと設定がリセットされます。この操作は取り消せません。")
        }
        .alert("デバッグ", isPresented: Binding(
            get: { store.showingAlert },
            set: { _ in store.send(.setAlert(false, "")) }
        )) {
            Button("OK") {
                store.send(.setAlert(false, ""))
            }
        } message: {
            Text(store.alertMessage)
        }
        .fullScreenCover(isPresented: $store.showingScreenshotView.sending(\.setShowingScreenshotView)) {
            ScreenshotView()
        }
    }
    
    
    @ViewBuilder
    private var usageLimitRow: some View {
        HStack {
            Text("現在の使用回数")
            Spacer()
            let currentCount = usageLimitClient.currentUsageCount()
            let limitText = usageLimitClient.hasReachedLimit() ? "∞" : "3"
            Text("\(currentCount) / \(limitText)")
                .foregroundColor(.secondary)
        }
    }
    
    private var usageLimitSection: some View {
        Section("使用制限") {
            usageLimitRow
            
            Button(action: { store.send(.resetUsageLimitTapped) }) {
                Label("使用回数をリセット", systemImage: "arrow.counterclockwise")
            }
            
            Button(action: { store.send(.toggleUnlimitedUsage) }) {
                Label("無制限モードを切り替え", systemImage: "infinity")
            }
        }
    }
    
    private var dataManagementSection: some View {
        Section("データ管理") {
            Button(role: .destructive, action: { store.send(.resetAllDataTapped) }) {
                Label("すべてのデータをリセット", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    private var purchaseTestSection: some View {
        Section("課金テスト") {
            Button(action: testPurchase) {
                Label("テスト購入を実行", systemImage: "creditcard")
            }
            
            Button(action: testRestore) {
                Label("購入の復元をテスト", systemImage: "arrow.clockwise")
            }
        }
    }
    
    private var screenshotSection: some View {
        Section("スクリーンショット") {
            Button(action: { store.send(.screenshotModeTapped) }) {
                Label("スクリーンショットモード", systemImage: "camera")
            }
        }
    }
    
    private var crashTestSection: some View {
        Section("クラッシュテスト") {
            Button(role: .destructive, action: { store.send(.forceCrashTapped) }) {
                Label("強制クラッシュ", systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
            }
        }
    }
    
    private var appInfoSection: some View {
        Section("アプリ情報") {
            HStack {
                Text("Bundle ID")
                Spacer()
                Text(Bundle.main.bundleIdentifier ?? "Unknown")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            HStack {
                Text("環境")
                Spacer()
                Text("Debug")
                    .foregroundColor(.orange)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }
        }
    }
    
    private func testPurchase() {
        Task {
            do {
                try await revenueCatClient.purchase(.monthly)
                store.send(.setAlert(true, "テスト購入が完了しました"))
            } catch {
                store.send(.setAlert(true, "購入エラー: \(error.localizedDescription)"))
            }
        }
    }
    
    private func testRestore() {
        Task {
            do {
                try await revenueCatClient.restorePurchases()
                store.send(.setAlert(true, "購入の復元が完了しました"))
            } catch {
                store.send(.setAlert(true, "復元エラー: \(error.localizedDescription)"))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DebugMenuView(
        store: Store(initialState: DebugMenuReducer.State()) {
            DebugMenuReducer()
        }
    )
}
