//
//  ContentView.swift
//  stepbystep
//
//  Created by 遠藤拓弥 on 2025/06/29.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct TaskInputReducer {
    @ObservableState
    struct State: Equatable {
        var taskTitle: String = ""
        var isLoading: Bool = false
        var errorMessage: String?
        
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
        case taskSaved
        case showError(String)
        case clearError
    }
    
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
                
                return .run { send in
                    try await Task.sleep(for: .seconds(1))
                    await send(.taskSaved)
                }
                
            case .taskSaved:
                state.isLoading = false
                state.taskTitle = ""
                return .none
                
            case let .showError(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            case .clearError:
                state.errorMessage = nil
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
                        Text(store.isLoading ? "保存中..." : "タスクを作成")
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
