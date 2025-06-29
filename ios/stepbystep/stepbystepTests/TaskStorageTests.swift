//
//  TaskStorageTests.swift
//  stepbystepTests
//
//  Created by Claude on 2025/06/29.
//

import XCTest
import Dependencies
import ComposableArchitecture
@testable import stepbystep

@MainActor
final class TaskStorageTests: XCTestCase {
    
    func testTaskStepCreation() {
        let step = TaskStep(content: "テストステップ", depth: 0)
        
        XCTAssertEqual(step.content, "テストステップ")
        XCTAssertFalse(step.isCompleted)
        XCTAssertEqual(step.depth, 0)
        XCTAssertNil(step.parentId)
        XCTAssertTrue(step.subSteps.isEmpty)
    }
    
    func testTaskStepCompletion() {
        var step = TaskStep(content: "テストステップ")
        
        XCTAssertFalse(step.isCompleted)
        XCTAssertNil(step.completedAt)
        
        step.setCompleted(true)
        
        XCTAssertTrue(step.isCompleted)
        XCTAssertNotNil(step.completedAt)
        
        step.setCompleted(false)
        
        XCTAssertFalse(step.isCompleted)
        XCTAssertNil(step.completedAt)
    }
    
    func testTaskStepDepthLimit() {
        var rootStep = TaskStep(content: "ルートステップ", depth: 0)
        let subStep = TaskStep(content: "サブステップ", depth: 1)
        let invalidStep = TaskStep(content: "無効なステップ", depth: 3)
        
        // 正常なサブステップ追加
        rootStep.addSubStep(subStep)
        XCTAssertEqual(rootStep.subSteps.count, 1)
        XCTAssertEqual(rootStep.subSteps[0].depth, 1)
        
        // 階層制限を超えるステップ
        var deepStep = TaskStep(content: "深いステップ", depth: 2)
        deepStep.addSubStep(invalidStep) // 3階層制限により追加されない
        XCTAssertEqual(deepStep.subSteps.count, 0)
    }
    
    func testPersistedTaskCreation() {
        let steps = [
            "ステップ1",
            "ステップ2",
            "ステップ3"
        ]
        
        let task = PersistedTask.createFromSteps("テストタスク", stepContents: steps)
        
        XCTAssertEqual(task.title, "テストタスク")
        XCTAssertEqual(task.steps.count, 3)
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.progressPercentage, 0.0)
        
        for (index, step) in task.steps.enumerated() {
            XCTAssertEqual(step.content, steps[index])
            XCTAssertEqual(step.depth, 0)
            XCTAssertFalse(step.isCompleted)
        }
    }
    
    func testPersistedTaskProgress() {
        var task = PersistedTask.createFromSteps("プログレステスト", stepContents: [
            "ステップ1", "ステップ2", "ステップ3", "ステップ4", "ステップ5"
        ])
        
        // 初期状態
        XCTAssertEqual(task.progressPercentage, 0.0)
        XCTAssertFalse(task.isCompleted)
        
        // TaskStepが値型なので、配列から取り出して修正して戻す必要がある
        var step0 = task.steps[0]
        step0.setCompleted(true)
        task.steps[0] = step0
        
        var step1 = task.steps[1]
        step1.setCompleted(true)
        task.steps[1] = step1
        
        // プログレス確認（2/5 = 0.4）
        XCTAssertEqual(task.progressPercentage, 0.4)
        
        // 残りも完了
        for i in 2..<task.steps.count {
            var step = task.steps[i]
            step.setCompleted(true)
            task.steps[i] = step
        }
        XCTAssertEqual(task.progressPercentage, 1.0)
        XCTAssertTrue(task.isCompleted)
    }
    
    func testMockTaskStorageClient() async throws {
        let mockClient = MockTaskStorageClient()
        
        // 初期状態
        let initialTasks = try await mockClient.loadTasks()
        XCTAssertTrue(initialTasks.isEmpty)
        
        let initialCurrentTask = try await mockClient.loadCurrentTask()
        XCTAssertNil(initialCurrentTask)
        
        // タスク保存
        let task = PersistedTask.createFromSteps("テストタスク", stepContents: ["ステップ1", "ステップ2"])
        let tasks = [task]
        
        try await mockClient.saveTasks(tasks)
        try await mockClient.saveCurrentTask(task)
        
        // データ取得
        let savedTasks = try await mockClient.loadTasks()
        XCTAssertEqual(savedTasks.count, 1)
        XCTAssertEqual(savedTasks[0].title, "テストタスク")
        
        let currentTask = try await mockClient.loadCurrentTask()
        XCTAssertNotNil(currentTask)
        XCTAssertEqual(currentTask?.title, "テストタスク")
        
        // タスク削除
        try await mockClient.deleteTask(id: task.id)
        let tasksAfterDelete = try await mockClient.loadTasks()
        XCTAssertTrue(tasksAfterDelete.isEmpty)
        
        let currentTaskAfterDelete = try await mockClient.loadCurrentTask()
        XCTAssertNil(currentTaskAfterDelete)
    }
    
    func testMockTaskStorageClientError() async {
        let mockClient = MockTaskStorageClient()
        mockClient.shouldFail = true
        mockClient.failureError = TaskStorageError.saveFailed
        
        do {
            try await mockClient.saveTasks([])
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is TaskStorageError)
        }
        
        do {
            _ = try await mockClient.loadTasks()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is TaskStorageError)
        }
    }
    
    func testTaskInputReducerWithStorage() async {
        await withDependencies {
            $0.taskStorageClient = MockTaskStorageClient()
            $0.taskSplitterClient = MockTaskSplitterClient()
        } operation: {
            let store = TestStore(initialState: TaskInputReducer.State()) {
                TaskInputReducer()
            }
            
            // アプリ起動時のデータ読み込み
            await store.send(.onAppear)
            await store.receive(.tasksLoaded([])) {
                $0.savedTasks = []
            }
            await store.receive(.currentTaskLoaded(nil)) {
                $0.currentTask = nil
            }
            
            // タスク作成
            await store.send(.taskTitleChanged("新しいテストタスク")) {
                $0.taskTitle = "新しいテストタスク"
            }
            
            await store.send(.saveButtonTapped) {
                $0.isLoading = true
                $0.errorMessage = nil
            }
            
            let expectedSteps = [
                "新しいテストタスクの準備をする",
                "新しいテストタスクの計画を立てる",
                "新しいテストタスクを実行する",
                "新しいテストタスクの確認をする",
                "新しいテストタスクを完了させる"
            ]
            
            await store.receive(.taskSplitCompleted(expectedSteps)) {
                $0.isLoading = false
                $0.steps = expectedSteps
                $0.showSteps = true
                $0.taskTitle = ""
                $0.currentTask = PersistedTask.createFromSteps("新しいテストタスク", stepContents: expectedSteps)
            }
            
            // タスク保存完了
            if let currentTask = store.state.currentTask {
                await store.receive(.taskSaved(currentTask)) { state in
                    state.savedTasks = [currentTask]
                }
            }
        }
    }
}