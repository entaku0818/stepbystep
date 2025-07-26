//
//  stepbystepTests.swift
//  stepbystepTests
//
//  Created by 遠藤拓弥 on 2025/06/29.
//

import Testing
import ComposableArchitecture
@testable import TaskSteps

@MainActor
struct TaskInputReducerTests {
    
    @Test func taskTitleChanged() async throws {
        let store = TestStore(initialState: TaskInputReducer.State()) {
            TaskInputReducer()
        } withDependencies: {
            $0.taskSplitterClient = MockTaskSplitterClient()
            $0.taskStorageClient = MockTaskStorageClient()
        }
        
        await store.send(.taskTitleChanged("新しいタスク")) {
            $0.taskTitle = "新しいタスク"
        }
    }
    
    @Test func validationShortTitle() async throws {
        let store = TestStore(initialState: TaskInputReducer.State()) {
            TaskInputReducer()
        } withDependencies: {
            $0.taskSplitterClient = MockTaskSplitterClient()
            $0.taskStorageClient = MockTaskStorageClient()
        }
        
        await store.send(.taskTitleChanged("短い")) {
            $0.taskTitle = "短い"
        }
        
        #expect(store.state.isValid == false)
        #expect(store.state.validationMessage == "タスク名は5文字以上で入力してください")
    }
    
    @Test func validationLongTitle() async throws {
        let longTitle = String(repeating: "あ", count: 101)
        let store = TestStore(initialState: TaskInputReducer.State()) {
            TaskInputReducer()
        } withDependencies: {
            $0.taskSplitterClient = MockTaskSplitterClient()
            $0.taskStorageClient = MockTaskStorageClient()
        }
        
        await store.send(.taskTitleChanged(longTitle)) {
            $0.taskTitle = longTitle
        }
        
        #expect(store.state.isValid == false)
        #expect(store.state.validationMessage == "タスク名は100文字以内で入力してください")
    }
    
    @Test func validTitle() async throws {
        let store = TestStore(initialState: TaskInputReducer.State()) {
            TaskInputReducer()
        } withDependencies: {
            $0.taskSplitterClient = MockTaskSplitterClient()
            $0.taskStorageClient = MockTaskStorageClient()
        }
        
        await store.send(.taskTitleChanged("有効なタスク名")) {
            $0.taskTitle = "有効なタスク名"
        }
        
        #expect(store.state.isValid == true)
        #expect(store.state.validationMessage == nil)
    }
    
    @Test func saveButtonTappedWithInvalidTitle() async throws {
        let store = TestStore(initialState: TaskInputReducer.State()) {
            TaskInputReducer()
        } withDependencies: {
            $0.taskSplitterClient = MockTaskSplitterClient()
            $0.taskStorageClient = MockTaskStorageClient()
        }
        
        await store.send(.taskTitleChanged("短い")) {
            $0.taskTitle = "短い"
        }
        
        await store.send(.saveButtonTapped) {
            $0.errorMessage = "タスク名は5文字以上で入力してください"
        }
    }
    
    @Test func showError() async throws {
        let store = TestStore(initialState: TaskInputReducer.State()) {
            TaskInputReducer()
        } withDependencies: {
            $0.taskSplitterClient = MockTaskSplitterClient()
            $0.taskStorageClient = MockTaskStorageClient()
        }
        
        await store.send(.showError("エラーメッセージ")) {
            $0.isLoading = false
            $0.errorMessage = "エラーメッセージ"
        }
    }
    
    @Test func clearError() async throws {
        let store = TestStore(
            initialState: TaskInputReducer.State(
                errorMessage: "既存のエラー"
            )
        ) {
            TaskInputReducer()
        } withDependencies: {
            $0.taskSplitterClient = MockTaskSplitterClient()
            $0.taskStorageClient = MockTaskStorageClient()
        }
        
        await store.send(.clearError) {
            $0.errorMessage = nil
        }
    }
    
    @Test func taskTitleChangedClearsError() async throws {
        let store = TestStore(
            initialState: TaskInputReducer.State(
                errorMessage: "既存のエラー"
            )
        ) {
            TaskInputReducer()
        } withDependencies: {
            $0.taskSplitterClient = MockTaskSplitterClient()
            $0.taskStorageClient = MockTaskStorageClient()
        }
        
        await store.send(.taskTitleChanged("新しいタスク")) {
            $0.taskTitle = "新しいタスク"
            $0.errorMessage = nil
        }
    }
}
