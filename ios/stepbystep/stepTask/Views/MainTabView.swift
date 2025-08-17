import SwiftUI
import ComposableArchitecture

// MARK: - Main Tab Reducer

@Reducer
struct MainTabReducer {
    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .tasks
        var taskInputState = TaskInputReducer.State()
        var taskHistoryState = TaskHistoryReducer.State()
        var settingsState = SettingsReducer.State()
    }
    
    enum Action {
        case tabSelected(Tab)
        case taskInput(TaskInputReducer.Action)
        case taskHistory(TaskHistoryReducer.Action)
        case settings(SettingsReducer.Action)
    }
    
    enum Tab: String, CaseIterable {
        case tasks = "タスク"
        case history = "履歴"
        case settings = "設定"
        
        var systemImage: String {
            switch self {
            case .tasks:
                return "plus.circle"
            case .history:
                return "clock"
            case .settings:
                return "gearshape"
            }
        }
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.taskInputState, action: \.taskInput) {
            TaskInputReducer()
        }
        
        Scope(state: \.taskHistoryState, action: \.taskHistory) {
            TaskHistoryReducer()
        }
        
        Scope(state: \.settingsState, action: \.settings) {
            SettingsReducer()
        }
        
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                
                // タブが切り替わったときに履歴を再読み込み
                if tab == .history {
                    return .send(.taskHistory(.loadTasks))
                }
                return .none
                
            case .taskInput(.taskSaved):
                // タスクが保存されたら履歴タブの状態を更新
                return .send(.taskHistory(.loadTasks))
                
            case .taskInput(.taskDeleted):
                // タスクが削除されたら履歴タブの状態を更新
                return .send(.taskHistory(.loadTasks))
                
            case .taskInput:
                return .none
                
            case .taskHistory:
                return .none
                
            case .settings:
                return .none
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    let store: StoreOf<MainTabReducer>
    
    var body: some View {
        TabView(selection: Binding(
            get: { store.selectedTab },
            set: { store.send(.tabSelected($0)) }
        )) {
            // タスク入力タブ
            TaskInputView(
                store: store.scope(
                    state: \.taskInputState,
                    action: \.taskInput
                )
            )
            .tabItem {
                Label(MainTabReducer.Tab.tasks.rawValue, 
                      systemImage: MainTabReducer.Tab.tasks.systemImage)
            }
            .tag(MainTabReducer.Tab.tasks)
            
            // タスク履歴タブ
            TaskHistoryView(
                store: store.scope(
                    state: \.taskHistoryState,
                    action: \.taskHistory
                )
            )
            .tabItem {
                Label(MainTabReducer.Tab.history.rawValue,
                      systemImage: MainTabReducer.Tab.history.systemImage)
            }
            .tag(MainTabReducer.Tab.history)
            
            // 設定タブ
            SettingsView(
                store: store.scope(
                    state: \.settingsState,
                    action: \.settings
                )
            )
            .tabItem {
                Label(MainTabReducer.Tab.settings.rawValue,
                      systemImage: MainTabReducer.Tab.settings.systemImage)
            }
            .tag(MainTabReducer.Tab.settings)
        }
    }
}