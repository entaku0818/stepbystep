//
//  ContentView.swift
//  stepbystep
//
//  Created by 遠藤拓弥 on 2025/06/29.
//

import SwiftUI
import ComposableArchitecture
import Dependencies

@Reducer
struct TaskInputReducer {
    @ObservableState
    struct State: Equatable {
        var taskTitle: String = ""
        var isLoading: Bool = false
        var errorMessage: String?
        var steps: [String] = []
        var showSteps: Bool = false
        
        var isValid: Bool {
            taskTitle.count >= 5 && taskTitle.count <= 100
        }
        
        var validationMessage: String? {
            if taskTitle.isEmpty { return nil }
            if taskTitle.count < 5 { return "タスク名は5文字以上で入力してください" }
            if taskTitle.count > 100 { return "タスク名は100文字以内で入力してください" }
            return nil
        }
    }
    
    enum Action: Equatable {
        case taskTitleChanged(String)
        case saveButtonTapped
        case taskSplitCompleted([String])
        case taskSplitFailed(String)
        case showError(String)
        case clearError
        case dismissSteps
    }
    
    @Dependency(\.taskSplitterClient) var taskSplitterClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .taskTitleChanged(title):
                state.taskTitle = title
                state.errorMessage = nil
                return .none
                
            case .saveButtonTapped:
                guard state.isValid else {
                    state.errorMessage = state.validationMessage
                    return .none
                }
                
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { [task = state.taskTitle] send in
                    do {
                        let steps = try await taskSplitterClient.splitTask(task)
                        await send(.taskSplitCompleted(steps))
                    } catch {
                        let errorMessage = if let taskError = error as? TaskSplitterError {
                            taskError.localizedDescription
                        } else {
                            "タスクの分割に失敗しました: \(error.localizedDescription)"
                        }
                        await send(.taskSplitFailed(errorMessage))
                    }
                }
                
            case let .taskSplitCompleted(steps):
                state.isLoading = false
                state.steps = steps
                state.showSteps = true
                state.taskTitle = ""
                return .none
                
            case let .taskSplitFailed(errorMessage):
                state.isLoading = false
                state.errorMessage = errorMessage
                return .none
                
            case let .showError(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            case .clearError:
                state.errorMessage = nil
                return .none
                
            case .dismissSteps:
                state.showSteps = false
                state.steps = []
                return .none
            }
        }
    }
}

struct TaskInputView: View {
    let store: StoreOf<TaskInputReducer>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("タスク名")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("やりたいことを入力してください", text: Binding(
                        get: { store.taskTitle },
                        set: { store.send(.taskTitleChanged($0)) }
                    ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(store.isLoading)
                    
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
                        Text(store.isLoading ? "AI分割中..." : "タスクを分割")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(store.isValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!store.isValid || store.isLoading)
                
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
            .sheet(isPresented: Binding(
                get: { store.showSteps },
                set: { _ in store.send(.dismissSteps) }
            )) {
                StepsDisplayView(steps: store.steps) {
                    store.send(.dismissSteps)
                }
            }
        }
    }
}

struct StepsDisplayView: View {
    let steps: [String]
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("タスクが5つのステップに分割されました！")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                List {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack {
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.blue)
                                .clipShape(Circle())
                            
                            Text(step)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
                
                Button("完了") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("分割されたステップ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        TaskInputView(
            store: Store(initialState: TaskInputReducer.State()) {
                TaskInputReducer()
            }
        )
    }
}

#Preview {
    ContentView()
}
