//
//  TaskStorage.swift
//  stepbystep
//
//  Created by Claude on 2025/06/29.
//

import Foundation
import Dependencies

// MARK: - Data Models

struct PersistedTask: Codable, Equatable, Identifiable {
    let id: UUID
    let title: String
    var steps: [TaskStep]
    let createdAt: Date
    var completedAt: Date?
    var isCompleted: Bool {
        steps.allSatisfy { $0.isCompleted }
    }
    
    var completedStepCount: Int {
        steps.filter { $0.isCompleted }.count
    }
    
    init(id: UUID = UUID(), title: String, steps: [TaskStep], createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.steps = steps
        self.createdAt = createdAt
        self.completedAt = nil
    }
}

struct TaskStep: Codable, Equatable, Identifiable {
    let id: UUID
    let content: String
    var isCompleted: Bool
    var completedAt: Date?
    var subSteps: [TaskStep]
    let depth: Int // 0=root, 1=sub, 2=subsub (最大3階層)
    let parentId: UUID?
    
    init(
        id: UUID = UUID(),
        content: String,
        isCompleted: Bool = false,
        subSteps: [TaskStep] = [],
        depth: Int = 0,
        parentId: UUID? = nil
    ) {
        self.id = id
        self.content = content
        self.isCompleted = isCompleted
        self.completedAt = nil
        self.subSteps = subSteps
        self.depth = min(depth, 2) // 最大2（3階層制限）
        self.parentId = parentId
    }
    
    /// 完了状態を変更（completedAtも更新）
    mutating func setCompleted(_ completed: Bool) {
        isCompleted = completed
        completedAt = completed ? Date() : nil
    }
    
    /// サブステップを追加（階層制限チェック）
    mutating func addSubStep(_ step: TaskStep) {
        guard depth < 2 else { return } // 3階層制限
        var newStep = step
        newStep = TaskStep(
            id: newStep.id,
            content: newStep.content,
            isCompleted: newStep.isCompleted,
            subSteps: newStep.subSteps,
            depth: depth + 1,
            parentId: id
        )
        subSteps.append(newStep)
    }
    
    /// 全サブステップが完了しているかチェック
    var allSubStepsCompleted: Bool {
        subSteps.isEmpty || subSteps.allSatisfy { $0.isCompleted }
    }
    
    /// 階層内での進捗率
    var completionProgress: Double {
        guard !subSteps.isEmpty else { return isCompleted ? 1.0 : 0.0 }
        let completedCount = subSteps.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(subSteps.count)
    }
}

// MARK: - Storage Client Protocol

protocol TaskStorageClient {
    func saveTasks(_ tasks: [PersistedTask]) async throws
    func loadTasks() async throws -> [PersistedTask]
    func saveCurrentTask(_ task: PersistedTask?) async throws
    func loadCurrentTask() async throws -> PersistedTask?
    func deleteTask(id: UUID) async throws
    func clearAllTasks() async throws
}

// MARK: - UserDefaults Implementation

class UserDefaultsTaskStorageClient: TaskStorageClient {
    private let userDefaults: UserDefaults
    private let tasksKey = "stepbystep_tasks"
    private let currentTaskKey = "stepbystep_current_task"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func saveTasks(_ tasks: [PersistedTask]) async throws {
        let data = try JSONEncoder().encode(tasks)
        userDefaults.set(data, forKey: tasksKey)
    }
    
    func loadTasks() async throws -> [PersistedTask] {
        guard let data = userDefaults.data(forKey: tasksKey) else {
            return []
        }
        return try JSONDecoder().decode([PersistedTask].self, from: data)
    }
    
    func saveCurrentTask(_ task: PersistedTask?) async throws {
        if let task = task {
            let data = try JSONEncoder().encode(task)
            userDefaults.set(data, forKey: currentTaskKey)
        } else {
            userDefaults.removeObject(forKey: currentTaskKey)
        }
    }
    
    func loadCurrentTask() async throws -> PersistedTask? {
        guard let data = userDefaults.data(forKey: currentTaskKey) else {
            return nil
        }
        return try JSONDecoder().decode(PersistedTask.self, from: data)
    }
    
    func deleteTask(id: UUID) async throws {
        var tasks = try await loadTasks()
        tasks.removeAll { $0.id == id }
        try await saveTasks(tasks)
        
        // 現在のタスクが削除されたタスクの場合、クリア
        if let currentTask = try await loadCurrentTask(), currentTask.id == id {
            try await saveCurrentTask(nil)
        }
    }
    
    func clearAllTasks() async throws {
        userDefaults.removeObject(forKey: tasksKey)
        userDefaults.removeObject(forKey: currentTaskKey)
    }
}

// MARK: - Mock Implementation for Testing

class MockTaskStorageClient: TaskStorageClient {
    private var tasks: [PersistedTask] = []
    private var currentTask: PersistedTask?
    
    // テスト用の設定
    var shouldFail = false
    var failureError: Error = TaskStorageError.saveFailed
    
    func saveTasks(_ tasks: [PersistedTask]) async throws {
        if shouldFail { throw failureError }
        self.tasks = tasks
    }
    
    func loadTasks() async throws -> [PersistedTask] {
        if shouldFail { throw failureError }
        return tasks
    }
    
    func saveCurrentTask(_ task: PersistedTask?) async throws {
        if shouldFail { throw failureError }
        self.currentTask = task
    }
    
    func loadCurrentTask() async throws -> PersistedTask? {
        if shouldFail { throw failureError }
        return currentTask
    }
    
    func deleteTask(id: UUID) async throws {
        if shouldFail { throw failureError }
        tasks.removeAll { $0.id == id }
        if currentTask?.id == id {
            currentTask = nil
        }
    }
    
    func clearAllTasks() async throws {
        if shouldFail { throw failureError }
        tasks.removeAll()
        currentTask = nil
    }
    
    // テスト用ヘルパー
    func reset() {
        tasks.removeAll()
        currentTask = nil
        shouldFail = false
        failureError = TaskStorageError.saveFailed
    }
}

// MARK: - Dependency Key

private enum TaskStorageClientKey: DependencyKey {
    static let liveValue: TaskStorageClient = UserDefaultsTaskStorageClient()
    static let testValue: TaskStorageClient = MockTaskStorageClient()
}

extension DependencyValues {
    var taskStorageClient: TaskStorageClient {
        get { self[TaskStorageClientKey.self] }
        set { self[TaskStorageClientKey.self] = newValue }
    }
}

// MARK: - Custom Errors

enum TaskStorageError: LocalizedError {
    case saveFailed
    case loadFailed
    case taskNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "タスクの保存に失敗しました"
        case .loadFailed:
            return "タスクの読み込みに失敗しました"
        case .taskNotFound:
            return "タスクが見つかりません"
        case .invalidData:
            return "無効なデータです"
        }
    }
}

// MARK: - Helper Extensions

extension PersistedTask {
    /// String配列からTaskStepを作成する便利メソッド
    static func createFromSteps(_ title: String, stepContents: [String]) -> PersistedTask {
        let steps = stepContents.enumerated().map { index, content in
            TaskStep(
                content: content,
                depth: 0,
                parentId: nil
            )
        }
        return PersistedTask(title: title, steps: steps)
    }
    
    /// 完了タスクをマーク
    mutating func markAsCompleted() {
        completedAt = Date()
    }
    
    /// 進捗率を計算
    var progressPercentage: Double {
        guard !steps.isEmpty else { return 0.0 }
        let completedCount = steps.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(steps.count)
    }
}