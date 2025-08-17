//
//  ProStepExecutionView.swift
//  TaskSteps
//
//  Pro会員向けのステップ実行画面（子タスク分割機能付き）
//

import SwiftUI
import ComposableArchitecture
import Dependencies

// MARK: - Pro Step Execution Reducer

@Reducer
struct ProStepExecutionReducer {
    @ObservableState
    struct State: Equatable {
        var steps: [StepItem]
        var currentStepIndex: Int = 0
        var showCompletionAlert = false
        var showCompletionAnimation = false
        var animateConfetti = false
        var animateSuccessIcon = false
        var animationScale: CGFloat = 0.1
        var isSplittingStep = false
        var splitError: String?
        var showProUpgrade = false
        var currentTask: PersistedTask?
        
        struct StepItem: Equatable, Identifiable {
            let id = UUID()
            var content: String
            var isCompleted: Bool = false
            var subSteps: [StepItem] = []
            var isExpanded: Bool = false
            var parentId: UUID?
        }
        
        var currentStep: StepItem? {
            guard currentStepIndex < steps.count else { return nil }
            return steps[currentStepIndex]
        }
        
        var allStepsCompleted: Bool {
            steps.allSatisfy { step in
                step.isCompleted && (step.subSteps.isEmpty || step.subSteps.allSatisfy { $0.isCompleted })
            }
        }
        
        var completedStepsCount: Int {
            steps.reduce(0) { count, step in
                let stepCount = step.isCompleted ? 1 : 0
                let subStepCount = step.subSteps.filter { $0.isCompleted }.count
                return count + stepCount + subStepCount
            }
        }
        
        var totalStepsCount: Int {
            steps.reduce(0) { count, step in
                return count + 1 + step.subSteps.count
            }
        }
    }
    
    enum Action {
        case completeStep(State.StepItem)
        case splitStep(State.StepItem)
        case splitStepCompleted(parentId: UUID, subSteps: [String])
        case splitStepFailed(String)
        case toggleStepExpansion(State.StepItem)
        case selectStep(Int)
        case completeTask
        case dismissCompletionAlert
        case showProUpgrade
        case dismissProUpgrade
        case saveTaskProgress
        case onAppear
    }
    
    @Dependency(\.taskSplitterClient) var taskSplitterClient
    @Dependency(\.revenueCatClient) var revenueCatClient
    @Dependency(\.taskStorageClient) var taskStorageClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .completeStep(step):
                // ステップまたはサブステップを完了
                if let parentIndex = state.steps.firstIndex(where: { $0.id == step.parentId }) {
                    // サブステップの場合
                    if let subIndex = state.steps[parentIndex].subSteps.firstIndex(where: { $0.id == step.id }) {
                        state.steps[parentIndex].subSteps[subIndex].isCompleted = true
                        
                        // 全てのサブステップが完了したら親ステップも完了
                        if state.steps[parentIndex].subSteps.allSatisfy({ $0.isCompleted }) {
                            state.steps[parentIndex].isCompleted = true
                        }
                    }
                } else if let index = state.steps.firstIndex(where: { $0.id == step.id }) {
                    // メインステップの場合
                    state.steps[index].isCompleted = true
                    
                    // 次の未完了ステップに移動
                    if let nextIndex = (index + 1..<state.steps.count).first(where: { !state.steps[$0].isCompleted }) {
                        state.currentStepIndex = nextIndex
                    }
                }
                
                // 全て完了したかチェック
                if state.allStepsCompleted {
                    return .send(.completeTask)
                }
                
                // タスクの進捗を保存
                return .send(.saveTaskProgress)
                
            case let .splitStep(step):
                // Pro会員チェック
                return .run { [step] send in
                    let isPro = await revenueCatClient.isProUser()
                    if !isPro {
                        await send(.showProUpgrade)
                        return
                    }
                    
                    do {
                        // ステップを子タスクに分割
                        let subSteps = try await taskSplitterClient.splitTask(step.content)
                        await send(.splitStepCompleted(parentId: step.id, subSteps: subSteps))
                    } catch {
                        await send(.splitStepFailed("ステップの分割に失敗しました: \(error.localizedDescription)"))
                    }
                }
                
            case let .splitStepCompleted(parentId, subSteps):
                state.isSplittingStep = false
                
                // 親ステップを見つけて子ステップを追加
                if let index = state.steps.firstIndex(where: { $0.id == parentId }) {
                    state.steps[index].subSteps = subSteps.map { content in
                        State.StepItem(content: content, parentId: parentId)
                    }
                    state.steps[index].isExpanded = true
                }
                
                return .none
                
            case let .splitStepFailed(error):
                state.isSplittingStep = false
                state.splitError = error
                return .none
                
            case let .toggleStepExpansion(step):
                if let index = state.steps.firstIndex(where: { $0.id == step.id }) {
                    state.steps[index].isExpanded.toggle()
                }
                return .none
                
            case let .selectStep(index):
                state.currentStepIndex = index
                return .none
                
            case .completeTask:
                state.showCompletionAnimation = true
                // アニメーション後にアラートを表示
                return .run { send in
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒待機
                    await send(.dismissCompletionAlert)
                }
                
            case .dismissCompletionAlert:
                state.showCompletionAlert = true
                return .none
                
            case .showProUpgrade:
                state.showProUpgrade = true
                return .none
                
            case .dismissProUpgrade:
                state.showProUpgrade = false
                return .none
                
            case .saveTaskProgress:
                // タスクの進捗を保存
                guard var task = state.currentTask else { return .none }
                
                // StepItemからTaskStepに変換して保存
                task.steps = state.steps.map { stepItem in
                    var taskStep = TaskStep(
                        content: stepItem.content,
                        isCompleted: stepItem.isCompleted,
                        subSteps: stepItem.subSteps.map { subItem in
                            TaskStep(
                                content: subItem.content,
                                isCompleted: subItem.isCompleted,
                                depth: 1,
                                parentId: stepItem.id
                            )
                        },
                        depth: 0,
                        parentId: nil
                    )
                    if stepItem.isCompleted {
                        taskStep.setCompleted(true)
                    }
                    return taskStep
                }
                
                // タスクが完了していれば完了日時を設定
                if task.isCompleted {
                    task.completedAt = Date()
                }
                
                return .run { [task] send in
                    do {
                        // 現在のタスクを保存
                        try await taskStorageClient.saveCurrentTask(task)
                        
                        // タスク履歴も更新
                        var tasks = try await taskStorageClient.loadTasks()
                        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                            tasks[index] = task
                            try await taskStorageClient.saveTasks(tasks)
                        }
                    } catch {
                        print("Failed to save task progress: \(error)")
                    }
                }
                
            case .onAppear:
                // 現在のタスクを読み込む
                return .run { send in
                    do {
                        if let task = try await taskStorageClient.loadCurrentTask() {
                            // タスクが読み込まれた場合の処理はViewで行う
                        }
                    } catch {
                        print("Failed to load current task: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - Pro Step Execution View

struct ProStepExecutionView: View {
    let store: StoreOf<ProStepExecutionReducer>
    let onTaskCompleted: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                // Progress indicator
                VStack(alignment: .leading, spacing: 8) {
                    Text("進捗: \(store.completedStepsCount)/\(store.totalStepsCount)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: Double(store.completedStepsCount), total: Double(store.totalStepsCount))
                        .tint(.blue)
                }
                .padding(.horizontal)
                
                // Current step display
                if let currentStep = store.currentStep {
                    CurrentStepCard(step: currentStep, store: store)
                }
                
                // All steps overview
                StepListView(store: store)
                
                Spacer()
                
                // Task completion button
                if store.allStepsCompleted && !store.showCompletionAnimation {
                    Button("タスクを完了") {
                        store.send(.completeTask)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding()
                }
            }
            .navigationTitle("ステップ実行")
            .navigationBarBackButtonHidden(true)
            .onAppear {
                store.send(.onAppear)
            }
            
            // Completion Animation
            if store.showCompletionAnimation {
                CompletionAnimationView(
                    animateConfetti: .constant(true),
                    animateSuccessIcon: .constant(true),
                    animationScale: .constant(1.0)
                )
                .transition(.opacity)
            }
        }
        .alert("タスク完了！", isPresented: Binding(
            get: { store.showCompletionAlert },
            set: { _ in onTaskCompleted() }
        )) {
            Button("OK") {
                onTaskCompleted()
            }
        } message: {
            Text("すべてのステップが完了しました。\nお疲れさまでした！")
        }
        .sheet(isPresented: Binding(
            get: { store.showProUpgrade },
            set: { _ in store.send(.dismissProUpgrade) }
        )) {
            ProUpgradePromptView()
        }
    }
}

// MARK: - Current Step Card

struct CurrentStepCard: View {
    let step: ProStepExecutionReducer.State.StepItem
    let store: StoreOf<ProStepExecutionReducer>
    
    var body: some View {
        VStack(spacing: 16) {
            Text("現在のステップ")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Text(step.content)
                .font(.title3)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            
            HStack(spacing: 16) {
                Button("完了") {
                    store.send(.completeStep(step))
                }
                .buttonStyle(.borderedProminent)
                .disabled(step.isCompleted)
                
                Button {
                    store.send(.splitStep(step))
                } label: {
                    Label("分割", systemImage: "square.split.2x1")
                }
                .buttonStyle(.bordered)
                .disabled(step.isCompleted || !step.subSteps.isEmpty)
            }
        }
        .padding()
    }
}

// MARK: - Step List View

struct StepListView: View {
    let store: StoreOf<ProStepExecutionReducer>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("全ステップ一覧")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(store.steps.enumerated()), id: \.element.id) { index, step in
                        VStack(spacing: 0) {
                            StepRowView(
                                step: step,
                                index: index,
                                isCurrentStep: index == store.currentStepIndex,
                                onTap: {
                                    store.send(.selectStep(index))
                                },
                                onComplete: {
                                    store.send(.completeStep(step))
                                },
                                onSplit: {
                                    store.send(.splitStep(step))
                                },
                                onToggleExpansion: {
                                    store.send(.toggleStepExpansion(step))
                                }
                            )
                            
                            // サブステップ
                            if step.isExpanded && !step.subSteps.isEmpty {
                                VStack(spacing: 4) {
                                    ForEach(step.subSteps) { subStep in
                                        SubStepRowView(
                                            subStep: subStep,
                                            onComplete: {
                                                store.send(.completeStep(subStep))
                                            }
                                        )
                                        .padding(.leading, 40)
                                    }
                                }
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.05))
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Step Row View

struct StepRowView: View {
    let step: ProStepExecutionReducer.State.StepItem
    let index: Int
    let isCurrentStep: Bool
    let onTap: () -> Void
    let onComplete: () -> Void
    let onSplit: () -> Void
    let onToggleExpansion: () -> Void
    
    var body: some View {
        HStack {
            // Step number circle
            ZStack {
                Circle()
                    .fill(stepColor)
                    .frame(width: 32, height: 32)
                
                if step.isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                } else {
                    Text("\(index + 1)")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
            
            Text(step.content)
                .font(.body)
                .opacity(step.isCompleted ? 0.7 : 1.0)
                .strikethrough(step.isCompleted)
            
            Spacer()
            
            if !step.subSteps.isEmpty {
                Button(action: onToggleExpansion) {
                    Image(systemName: step.isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            
            if isCurrentStep {
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
        .background(isCurrentStep ? Color.blue.opacity(0.05) : Color.clear)
        .cornerRadius(8)
        .onTapGesture(perform: onTap)
    }
    
    private var stepColor: Color {
        if step.isCompleted {
            return .green
        } else if isCurrentStep {
            return .blue
        } else {
            return .gray
        }
    }
}

// MARK: - Sub Step Row View

struct SubStepRowView: View {
    let subStep: ProStepExecutionReducer.State.StepItem
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: subStep.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(subStep.isCompleted ? .green : .gray)
                .font(.body)
            
            Text(subStep.content)
                .font(.subheadline)
                .opacity(subStep.isCompleted ? 0.7 : 1.0)
                .strikethrough(subStep.isCompleted)
            
            Spacer()
            
            if !subStep.isCompleted {
                Button("完了") {
                    onComplete()
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - Pro Upgrade Prompt View

struct ProUpgradePromptView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .padding(.top, 40)
                
                Text("Pro会員限定機能")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("ステップをさらに細かく分割する機能は\nPro会員限定です")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "square.split.2x1", text: "ステップを子タスクに分割")
                    FeatureRow(icon: "infinity", text: "無制限のタスク分割")
                    FeatureRow(icon: "play.slash", text: "広告なし")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                NavigationLink(destination: SubscriptionView(
                    store: Store(initialState: SubscriptionReducer.State()) {
                        SubscriptionReducer()
                    }
                )) {
                    Text("Proにアップグレード")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal)
                
                Button("後で") {
                    dismiss()
                }
                .foregroundColor(.gray)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}
