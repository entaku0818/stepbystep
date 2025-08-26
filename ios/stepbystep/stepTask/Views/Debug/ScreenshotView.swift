import SwiftUI

// MARK: - Screenshot View

struct ScreenshotView: View {
    @State private var currentIndex: Int = 0
    @Environment(\.dismiss) var dismiss
    
    enum ScreenshotType: String, CaseIterable {
        case taskInput = "タスク入力"
        case taskSplitting = "タスク分割中"
        case stepExecution = "ステップ実行"
        case completion = "完了画面"
        case history = "履歴"
        case subscription = "サブスクリプション"
        
        var description: String {
            switch self {
            case .taskInput:
                return "タスクを入力する初期画面"
            case .taskSplitting:
                return "AIがタスクを分割している画面"
            case .stepExecution:
                return "ステップを一つずつ実行する画面"
            case .completion:
                return "タスク完了のお祝い画面"
            case .history:
                return "完了したタスクの履歴画面"
            case .subscription:
                return "Pro版の紹介画面"
            }
        }
    }
    
    private let screens = ScreenshotType.allCases
    
    var body: some View {
        ZStack {
            // 背景を白に
            Color.white
                .ignoresSafeArea()
            
            // TabViewでスワイプ可能にする
            TabView(selection: $currentIndex) {
                ForEach(0..<screens.count, id: \.self) { index in
                    screenView(for: screens[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // 右上に小さくインジケーターと閉じるボタン
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        // 現在のページ表示
                        Text("\(currentIndex + 1) / \(screens.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                        
                        // 閉じるボタン
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .preferredColorScheme(.light) // Force light mode for screenshots
        .statusBar(hidden: true) // ステータスバーを非表示
        .onChange(of: currentIndex) { oldValue, newValue in
            // 最後のスクリーンの後でスワイプしたら終了
            if newValue >= screens.count {
                dismiss()
            }
        }
    }
    
    // 各スクリーンのビューを返す
    private func screenView(for type: ScreenshotType) -> some View {
        Group {
            switch type {
            case .taskInput:
                TaskInputScreenshotView()
            case .taskSplitting:
                TaskSplittingScreenshotView()
            case .stepExecution:
                StepExecutionScreenshotView()
            case .completion:
                CompletionScreenshotView()
            case .history:
                HistoryScreenshotView()
            case .subscription:
                SubscriptionScreenshotView()
            }
        }
    }
}