import SwiftUI
import ComposableArchitecture

// MARK: - Task History Reducer

@Reducer
struct TaskHistoryReducer {
    @ObservableState
    struct State: Equatable {
        var savedTasks: [SavedTask] = []
        var selectedTask: SavedTask?
        var showTaskDetail = false
        var isLoading = false
        var errorMessage: String?
    }
    
    enum Action {
        case loadTasks
        case tasksLoaded([SavedTask])
        case selectTask(SavedTask)
        case deselectTask
        case deleteTask(SavedTask)
        case taskDeleted(taskId: String)
        case resumeTask(SavedTask)
        case loadFailed(String)
        case clearError
    }
    
    @Dependency(\.taskStorageClient) var taskStorageClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadTasks:
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        let tasks = try await taskStorageClient.getAllTasks()
                        await send(.tasksLoaded(tasks))
                    } catch {
                        await send(.loadFailed("タスクの読み込みに失敗しました"))
                    }
                }
                
            case let .tasksLoaded(tasks):
                state.isLoading = false
                state.savedTasks = tasks.sorted { $0.createdAt > $1.createdAt }
                return .none
                
            case let .selectTask(task):
                state.selectedTask = task
                state.showTaskDetail = true
                return .none
                
            case .deselectTask:
                state.selectedTask = nil
                state.showTaskDetail = false
                return .none
                
            case let .deleteTask(task):
                return .run { send in
                    do {
                        try await taskStorageClient.deleteTask(task.id)
                        await send(.taskDeleted(taskId: task.id))
                    } catch {
                        await send(.loadFailed("タスクの削除に失敗しました"))
                    }
                }
                
            case let .taskDeleted(taskId):
                state.savedTasks.removeAll { $0.id == taskId }
                if state.selectedTask?.id == taskId {
                    state.selectedTask = nil
                    state.showTaskDetail = false
                }
                return .none
                
            case let .resumeTask(task):
                // タスクを再開する処理（必要に応じて実装）
                return .none
                
            case let .loadFailed(message):
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

// MARK: - Task History View

struct TaskHistoryView: View {
    let store: StoreOf<TaskHistoryReducer>
    
    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.savedTasks.isEmpty {
                    EmptyHistoryView()
                } else {
                    TaskListView(store: store)
                }
            }
            .navigationTitle("タスク履歴")
            .onAppear {
                store.send(.loadTasks)
            }
            .alert("エラー", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { _ in store.send(.clearError) }
            )) {
                Button("OK") {
                    store.send(.clearError)
                }
            } message: {
                Text(store.errorMessage ?? "")
            }
            .sheet(isPresented: Binding(
                get: { store.showTaskDetail },
                set: { _ in store.send(.deselectTask) }
            )) {
                if let task = store.selectedTask {
                    TaskDetailView(task: task, store: store)
                }
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("タスク履歴がありません")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("完了したタスクがここに表示されます")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Task List View

struct TaskListView: View {
    let store: StoreOf<TaskHistoryReducer>
    
    var body: some View {
        List {
            ForEach(store.savedTasks) { task in
                TaskRowView(task: task) {
                    store.send(.selectTask(task))
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        store.send(.deleteTask(task))
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Task Row View

struct TaskRowView: View {
    let task: SavedTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    // ステータスバッジ
                    StatusBadge(task: task)
                    
                    Spacer()
                    
                    // 作成日時
                    Text(formatDate(task.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 進捗バー
                ProgressBar(completedSteps: task.completedStepCount, totalSteps: task.steps.count)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "今日 HH:mm"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "昨日 HH:mm"
        } else {
            formatter.dateFormat = "MM/dd HH:mm"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let task: SavedTask
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption)
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(6)
    }
    
    private var statusIcon: String {
        if task.isCompleted {
            return "checkmark.circle.fill"
        } else if task.completedStepCount > 0 {
            return "play.circle.fill"
        } else {
            return "circle"
        }
    }
    
    private var statusText: String {
        if task.isCompleted {
            return "完了"
        } else if task.completedStepCount > 0 {
            return "進行中"
        } else {
            return "未着手"
        }
    }
    
    private var backgroundColor: Color {
        if task.isCompleted {
            return .green.opacity(0.2)
        } else if task.completedStepCount > 0 {
            return .blue.opacity(0.2)
        } else {
            return .gray.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        if task.isCompleted {
            return .green
        } else if task.completedStepCount > 0 {
            return .blue
        } else {
            return .gray
        }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let completedSteps: Int
    let totalSteps: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(progress == 1.0 ? Color.green : Color.blue)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
    }
    
    private var progress: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return CGFloat(completedSteps) / CGFloat(totalSteps)
    }
}

// MARK: - Task Detail View

struct TaskDetailView: View {
    let task: SavedTask
    let store: StoreOf<TaskHistoryReducer>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // タスクタイトル
                    VStack(alignment: .leading, spacing: 8) {
                        Text("タスク")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(task.title)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    // ステータス情報
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ステータス")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            StatusBadge(task: task)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("進捗")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(task.completedStepCount) / \(task.steps.count) ステップ")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Divider()
                    
                    // ステップ一覧
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ステップ")
                            .font(.headline)
                        
                        ForEach(task.steps) { step in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(step.isCompleted ? .green : .gray)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.title)
                                        .strikethrough(step.isCompleted)
                                        .foregroundColor(step.isCompleted ? .secondary : .primary)
                                    
                                    if step.isCompleted, let completedAt = step.completedAt {
                                        Text("完了: \(formatDate(completedAt))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Divider()
                    
                    // 時間情報
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("作成日時:")
                                .foregroundColor(.secondary)
                            Text(formatFullDate(task.createdAt))
                        }
                        .font(.caption)
                        
                        if let completedAt = task.completedAt {
                            HStack {
                                Text("完了日時:")
                                    .foregroundColor(.secondary)
                                Text(formatFullDate(completedAt))
                            }
                            .font(.caption)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("タスク詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        store.send(.deselectTask)
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}