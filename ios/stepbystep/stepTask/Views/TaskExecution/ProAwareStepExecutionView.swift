import SwiftUI
import ComposableArchitecture
import Dependencies

struct ProAwareStepExecutionView: View {
    let steps: [String]
    let currentTask: PersistedTask?
    let onTaskCompleted: () -> Void
    
    var taskTitle: String {
        currentTask?.title ?? "タスク"
    }
    
    @Dependency(\.revenueCatClient) var revenueCatClient
    @State private var isProUser: Bool = false
    
    var body: some View {
        Group {
            if isProUser {
                // Pro会員用の画面
                ProStepExecutionView(
                    store: Store(
                        initialState: ProStepExecutionReducer.State(
                            steps: steps.map { ProStepExecutionReducer.State.StepItem(content: $0) },
                            currentTask: currentTask
                        ),
                        reducer: {
                            ProStepExecutionReducer()
                        }
                    ),
                    onTaskCompleted: onTaskCompleted
                )
            } else {
                // 通常の画面
                StepExecutionView(
                    steps: steps,
                    taskTitle: taskTitle,
                    onTaskCompleted: onTaskCompleted
                )
            }
        }
        .task {
            isProUser = await revenueCatClient.isProUser()
        }
    }
}