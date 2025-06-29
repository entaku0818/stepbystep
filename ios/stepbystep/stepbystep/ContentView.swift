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
        var currentTask: PersistedTask?
        var savedTasks: [PersistedTask] = []
        
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
        
        // 永続化関連のアクション
        case onAppear
        case tasksLoaded([PersistedTask])
        case currentTaskLoaded(PersistedTask?)
        case taskSaved(PersistedTask)
        case taskDeleted(UUID)
        case storageFailed(String)
    }
    
    @Dependency(\.taskSplitterClient) var taskSplitterClient
    @Dependency(\.taskStorageClient) var taskStorageClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .taskTitleChanged(title):
                state.taskTitle = title
                state.errorMessage = nil
                return .none
                
            case .onAppear:
                return .run { send in
                    do {
                        let tasks = try await taskStorageClient.loadTasks()
                        await send(.tasksLoaded(tasks))
                        
                        let currentTask = try await taskStorageClient.loadCurrentTask()
                        await send(.currentTaskLoaded(currentTask))
                    } catch {
                        await send(.storageFailed("データの読み込みに失敗しました: \(error.localizedDescription)"))
                    }
                }
                
            case let .tasksLoaded(tasks):
                state.savedTasks = tasks
                return .none
                
            case let .currentTaskLoaded(task):
                state.currentTask = task
                if let task = task {
                    // 進行中のタスクがある場合、ステップ実行画面に遷移
                    state.steps = task.steps.map { $0.content }
                    state.showSteps = true
                }
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
                
                // タスクを永続化
                let newTask = PersistedTask.createFromSteps(state.taskTitle, stepContents: steps)
                state.currentTask = newTask
                state.taskTitle = ""
                
                return .run { [task = newTask] send in
                    do {
                        try await taskStorageClient.saveCurrentTask(task)
                        var tasks = try await taskStorageClient.loadTasks()
                        tasks.append(task)
                        try await taskStorageClient.saveTasks(tasks)
                        await send(.taskSaved(task))
                    } catch {
                        await send(.storageFailed("タスクの保存に失敗しました: \(error.localizedDescription)"))
                    }
                }
                
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
                state.currentTask = nil
                
                // 現在のタスクをクリア
                return .run { send in
                    do {
                        try await taskStorageClient.saveCurrentTask(nil)
                    } catch {
                        await send(.storageFailed("タスクのクリアに失敗しました"))
                    }
                }
                
            case let .taskSaved(task):
                // タスクが保存されたときの追加処理（必要に応じて）
                if !state.savedTasks.contains(where: { $0.id == task.id }) {
                    state.savedTasks.append(task)
                }
                return .none
                
            case let .taskDeleted(taskId):
                state.savedTasks.removeAll { $0.id == taskId }
                if state.currentTask?.id == taskId {
                    state.currentTask = nil
                    state.showSteps = false
                    state.steps = []
                }
                return .none
                
            case let .storageFailed(errorMessage):
                state.errorMessage = errorMessage
                return .none
            }
        }
    }
}

struct TaskInputView: View {
    let store: StoreOf<TaskInputReducer>
    
    var body: some View {
        NavigationStack {
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
            .onAppear {
                store.send(.onAppear)
            }
            .navigationDestination(isPresented: Binding(
                get: { store.showSteps },
                set: { _ in }
            )) {
                StepExecutionView(steps: store.steps, onTaskCompleted: {
                    store.send(.dismissSteps)
                })
            }
        }
    }
}

// MARK: - Step Execution View (Task completion enforced)

struct StepExecutionView: View {
    let steps: [String]
    let onTaskCompleted: () -> Void
    
    @State private var currentStepIndex: Int = 0
    @State private var completedSteps: Set<Int> = []
    @State private var showCompletionAlert = false
    
    private var allStepsCompleted: Bool {
        completedSteps.count == steps.count
    }
    
    private var currentStep: String? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Progress indicator
            VStack(alignment: .leading, spacing: 8) {
                Text("進捗: \(completedSteps.count)/\(steps.count)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ProgressView(value: Double(completedSteps.count), total: Double(steps.count))
                    .tint(.blue)
            }
            .padding(.horizontal)
            
            // Current step display
            if let step = currentStep {
                VStack(spacing: 16) {
                    Text("ステップ \(currentStepIndex + 1)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text(step)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    
                    HStack(spacing: 16) {
                        Button("完了") {
                            completeCurrentStep()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(completedSteps.contains(currentStepIndex))
                        
                        if currentStepIndex > 0 {
                            Button("前のステップ") {
                                currentStepIndex = max(0, currentStepIndex - 1)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if currentStepIndex < steps.count - 1 && completedSteps.contains(currentStepIndex) {
                            Button("次のステップ") {
                                currentStepIndex = min(steps.count - 1, currentStepIndex + 1)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
            }
            
            // All steps overview
            VStack(alignment: .leading, spacing: 12) {
                Text("全ステップ一覧")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack {
                            // Step number circle
                            ZStack {
                                Circle()
                                    .fill(stepColor(for: index))
                                    .frame(width: 32, height: 32)
                                
                                if completedSteps.contains(index) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                } else {
                                    Text("\(index + 1)")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            Text(step)
                                .font(.body)
                                .opacity(completedSteps.contains(index) ? 0.7 : 1.0)
                                .strikethrough(completedSteps.contains(index))
                            
                            Spacer()
                            
                            if index == currentStepIndex {
                                Text("現在")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(index == currentStepIndex ? Color.blue.opacity(0.05) : Color.clear)
                        .cornerRadius(8)
                        .onTapGesture {
                            // Allow navigation to completed steps or current step
                            if completedSteps.contains(index) || index == currentStepIndex {
                                currentStepIndex = index
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Task completion button (only when all steps are done)
            if allStepsCompleted {
                Button("タスクを完了") {
                    showCompletionAlert = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
            }
        }
        .navigationTitle("ステップ実行")
        .navigationBarBackButtonHidden(true) // 戻るボタンを非表示
        .alert("タスク完了！", isPresented: $showCompletionAlert) {
            Button("OK") {
                onTaskCompleted()
            }
        } message: {
            Text("すべてのステップが完了しました。\nお疲れさまでした！")
        }
    }
    
    private func completeCurrentStep() {
        completedSteps.insert(currentStepIndex)
        
        // Move to next uncompleted step
        if let nextIndex = (currentStepIndex + 1..<steps.count).first(where: { !completedSteps.contains($0) }) {
            currentStepIndex = nextIndex
        }
    }
    
    private func stepColor(for index: Int) -> Color {
        if completedSteps.contains(index) {
            return .green
        } else if index == currentStepIndex {
            return .blue
        } else {
            return .gray
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
