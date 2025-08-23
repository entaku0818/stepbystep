import SwiftUI
import ComposableArchitecture
import Dependencies

struct TaskInputView: View {
    let store: StoreOf<TaskInputReducer>
    @Dependency(\.usageLimitClient) var usageLimitClient
    
    private func loadingText(store: StoreOf<TaskInputReducer>) -> String {
        if let adMessage = store.adLoadingMessage {
            return adMessage
        } else if store.isLoading {
            return "AI分割中..."
        } else {
            return "タスクを分割"
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // ステップタスクAIの説明
                Text("ステップタスクAIでタスクを分割して管理する")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("タスク名")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 残り使用回数を表示
                        Text("本日の残り: \(store.remainingUsage)回")
                            .font(.caption)
                            .foregroundColor(store.remainingUsage > 0 ? .blue : .red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    TextEditor(text: Binding(
                        get: { store.taskTitle },
                        set: { store.send(.taskTitleChanged($0)) }
                    ))
                        .frame(minHeight: 60, maxHeight: 120)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .disabled(store.isLoading)
                        .overlay(
                            // プレースホルダー
                            Group {
                                if store.taskTitle.isEmpty {
                                    Text("やりたいことを入力してください")
                                        .foregroundColor(Color.gray.opacity(0.5))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 12)
                                        .allowsHitTesting(false)
                                }
                            }, alignment: .topLeading
                        )
                    
                    if let validationMessage = store.validationMessage {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Button(action: {
                    store.send(.saveButtonTapped)
                }) {
                    HStack {
                        if store.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(loadingText(store: store))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(buttonBackgroundColor(store: store))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!store.isValid || store.isLoading || store.currentTask != nil)
                
                if store.currentTask != nil {
                    Text("現在進行中のタスクを完了してから新しいタスクを追加してください")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
                
                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("新しいタスク")
            .onAppear {
                store.send(.onAppear)
            }
            .navigationDestination(isPresented: Binding(
                get: { store.showSteps },
                set: { _ in }
            )) {
                // Pro会員チェックして適切な画面を表示
                ProAwareStepExecutionView(
                    steps: store.steps,
                    currentTask: store.currentTask,
                    onTaskCompleted: {
                        store.send(.dismissSteps)
                    }
                )
            }
            .sheet(isPresented: Binding(
                get: { store.showProUpgradePrompt },
                set: { _ in store.send(.dismissProUpgradePrompt) }
            )) {
                ProUpgradePromptView(
                    onDismiss: {
                        store.send(.dismissProUpgradePrompt)
                    },
                    message: "無料利用回数（5回）を使い切りました。タスク分割機能を継続してご利用いただくには、プレミアムプランへのアップグレードが必要です。"
                )
            }
            .alert("広告が表示されます", isPresented: Binding(
                get: { store.showAdWarningAlert },
                set: { _ in }
            )) {
                Button("OK") {
                    store.send(.confirmAdShow)
                }
            } message: {
                Text("タスク分割の前に短い広告が表示されます。")
            }
        }
    }
    
    private func buttonBackgroundColor(store: StoreOf<TaskInputReducer>) -> Color {
        if store.currentTask != nil {
            return Color.gray
        } else if store.isValid {
            return Color.blue
        } else {
            return Color.gray
        }
    }
}