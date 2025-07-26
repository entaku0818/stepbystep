import SwiftUI
import ComposableArchitecture

// MARK: - Settings Reducer

@Reducer
struct SettingsReducer {
    @ObservableState
    struct State: Equatable {
        var isProUser: Bool = false
        var showingSubscription = false
        var showingPrivacyPolicy = false
        var showingTermsOfService = false
        var showingSupport = false
        var appVersion: String {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
            return "\(version) (\(build))"
        }
    }
    
    enum Action {
        case onAppear
        case subscriptionTapped
        case privacyPolicyTapped
        case termsOfServiceTapped
        case supportTapped
        case reviewTapped
        case setShowingSubscription(Bool)
        case setShowingPrivacyPolicy(Bool)
        case setShowingTermsOfService(Bool)
        case setShowingSupport(Bool)
        case checkProStatus
        case setProStatus(Bool)
    }
    
    @Dependency(\.revenueCatClient) var revenueCatClient
    @Dependency(\.openURL) var openURL
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.checkProStatus)
                
            case .subscriptionTapped:
                state.showingSubscription = true
                return .none
                
            case .privacyPolicyTapped:
                state.showingPrivacyPolicy = true
                return .none
                
            case .termsOfServiceTapped:
                state.showingTermsOfService = true
                return .none
                
            case .supportTapped:
                state.showingSupport = true
                return .none
                
            case .reviewTapped:
                return .run { _ in
                    // TODO: Replace with actual App Store ID
                    let appStoreURL = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID?action=write-review")!
                    await openURL(appStoreURL)
                }
                
            case let .setShowingSubscription(showing):
                state.showingSubscription = showing
                return .none
                
            case let .setShowingPrivacyPolicy(showing):
                state.showingPrivacyPolicy = showing
                return .none
                
            case let .setShowingTermsOfService(showing):
                state.showingTermsOfService = showing
                return .none
                
            case let .setShowingSupport(showing):
                state.showingSupport = showing
                return .none
                
            case .checkProStatus:
                return .run { send in
                    let isPro = await revenueCatClient.isProUser()
                    await send(.setProStatus(isPro))
                }
                
            case let .setProStatus(isPro):
                state.isProUser = isPro
                return .none
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsReducer>
    
    var body: some View {
        NavigationStack {
            List {
                // Pro Section
                Section {
                    Button(action: { store.send(.subscriptionTapped) }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.isProUser ? "Pro会員" : "Task Steps Pro")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                if store.isProUser {
                                    Text("ご利用いただきありがとうございます")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("無制限のタスク分割・広告なし")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Support Section
                Section("サポート") {
                    Button(action: { store.send(.reviewTapped) }) {
                        SettingsRow(
                            icon: "star.fill",
                            iconColor: .yellow,
                            title: "アプリを評価する"
                        )
                    }
                    
                    Button(action: { store.send(.supportTapped) }) {
                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            iconColor: .blue,
                            title: "お問い合わせ"
                        )
                    }
                }
                
                // Legal Section
                Section("その他") {
                    Button(action: { store.send(.privacyPolicyTapped) }) {
                        SettingsRow(
                            icon: "lock.fill",
                            iconColor: .green,
                            title: "プライバシーポリシー"
                        )
                    }
                    
                    Button(action: { store.send(.termsOfServiceTapped) }) {
                        SettingsRow(
                            icon: "doc.text.fill",
                            iconColor: .blue,
                            title: "利用規約"
                        )
                    }
                }
                
                // About Section
                Section("アプリについて") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text(store.appVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $store.showingSubscription.sending(\.setShowingSubscription)) {
                SubscriptionView(
                    store: Store(initialState: SubscriptionReducer.State()) {
                        SubscriptionReducer()
                    }
                )
            }
            .sheet(isPresented: $store.showingPrivacyPolicy.sending(\.setShowingPrivacyPolicy)) {
                WebPolicyView(
                    title: "プライバシーポリシー",
                    urlString: "https://stepbystep-tasks.web.app/privacy.html"
                )
            }
            .sheet(isPresented: $store.showingTermsOfService.sending(\.setShowingTermsOfService)) {
                WebPolicyView(
                    title: "利用規約",
                    urlString: "https://stepbystep-tasks.web.app/terms.html"
                )
            }
            .sheet(isPresented: $store.showingSupport.sending(\.setShowingSupport)) {
                SupportView()
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Web Policy View

struct WebPolicyView: View {
    let title: String
    let urlString: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            WebView(urlString: urlString)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("閉じる") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Support View

struct SupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var feedbackText = ""
    @State private var feedbackType = FeedbackType.general
    
    enum FeedbackType: String, CaseIterable {
        case general = "一般的な質問"
        case bug = "不具合報告"
        case feature = "機能リクエスト"
        case other = "その他"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("フィードバックの種類") {
                    Picker("種類", selection: $feedbackType) {
                        ForEach(FeedbackType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("メッセージ") {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 200)
                }
                
                Section {
                    Button(action: sendFeedback) {
                        Text("送信")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("お問い合わせ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendFeedback() {
        // TODO: Implement feedback submission
        // For now, just dismiss
        dismiss()
    }
}

// MARK: - Web View

import WebKit

struct WebView: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        // Add navigation delegate methods if needed
    }
}

// MARK: - Preview

#Preview {
    SettingsView(
        store: Store(initialState: SettingsReducer.State()) {
            SettingsReducer()
        }
    )
}