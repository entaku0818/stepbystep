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
        var showUsageLimitAlert: Bool = false
        var remainingUsage: Int = 5
        var isShowingAd: Bool = false
        var adLoadingMessage: String?
        var showAdWarningAlert: Bool = false
        
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
        
        // 使用制限関連のアクション
        case updateRemainingUsage
        case dismissUsageLimitAlert
        
        // 広告関連のアクション
        case showAdBeforeTaskSplit
        case adShown(Bool)
        case adLoadingStarted
        case adLoadingCompleted
        case showAdWarning
        case confirmAdShow
        case cancelAdShow
    }
    
    @Dependency(\.taskSplitterClient) var taskSplitterClient
    @Dependency(\.taskStorageClient) var taskStorageClient
    @Dependency(\.adClient) var adClient
    @Dependency(\.usageLimitClient) var usageLimitClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .taskTitleChanged(title):
                state.taskTitle = title
                state.errorMessage = nil
                return .none
                
            case .onAppear:
                // 使用制限の残り回数を更新
                state.remainingUsage = usageLimitClient.remainingUsage()
                
                return .run { send in
                    do {
                        let tasks = try await taskStorageClient.loadTasks()
                        await send(.tasksLoaded(tasks))
                        
                        let currentTask = try await taskStorageClient.loadCurrentTask()
                        await send(.currentTaskLoaded(currentTask))
                        
                        // 広告をプリロード
                        await adClient.loadAd()
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
                
                // 使用制限チェック
                if usageLimitClient.hasReachedLimit() {
                    state.showUsageLimitAlert = true
                    return .none
                }
                
                // 広告表示の警告アラートを表示
                state.showAdWarningAlert = true
                return .none
                
            case .showAdBeforeTaskSplit:
                state.isLoading = true
                state.adLoadingMessage = "広告を読み込み中..."
                state.errorMessage = nil
                
                return .run { send in
                    await send(.adLoadingStarted)
                    
                    // 広告が利用可能かチェック
                    let isAdAvailable = await adClient.isAdAvailable()
                    
                    if isAdAvailable {
                        // 広告を表示
                        let adResult = await adClient.showAd()
                        await send(.adShown(adResult))
                    } else {
                        // 広告が利用できない場合は直接タスク分割を実行
                        await send(.adShown(false))
                    }
                }
                
            case .adLoadingStarted:
                return .none
                
            case .adLoadingCompleted:
                state.adLoadingMessage = nil
                return .none
                
            case let .adShown(success):
                state.adLoadingMessage = nil
                
                // 広告表示の成否に関わらず、タスク分割を実行
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
                
                // 使用回数をインクリメント
                usageLimitClient.incrementUsage()
                state.remainingUsage = usageLimitClient.remainingUsage()
                
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
                
            case .updateRemainingUsage:
                state.remainingUsage = usageLimitClient.remainingUsage()
                return .none
                
            case .dismissUsageLimitAlert:
                state.showUsageLimitAlert = false
                return .none
                
            case .showAdWarning:
                state.showAdWarningAlert = true
                return .none
                
            case .confirmAdShow:
                state.showAdWarningAlert = false
                // 広告を表示してからタスク分割を行う
                return .send(.showAdBeforeTaskSplit)
                
            case .cancelAdShow:
                state.showAdWarningAlert = false
                return .none
            }
        }
    }
}