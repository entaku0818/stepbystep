import Foundation

// MARK: - Mock Implementation

class MockTaskSplitterClient: TaskSplitterClient {
    var environment: APIEnvironment = .production
    
    // テスト用の設定
    var shouldSucceed: Bool = true
    var mockDelay: TimeInterval = 0.5
    var customSteps: [String]?
    var customError: TaskSplitterError?
    
    func splitTask(_ task: String) async throws -> [String] {
        // バリデーション（実装と同じ）
        guard task.count >= 5 && task.count <= 100 else {
            throw TaskSplitterError.invalidTask
        }
        
        // 遅延をシミュレート
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        // カスタムエラーが設定されている場合
        if let error = customError {
            throw error
        }
        
        // 失敗を設定されている場合
        if !shouldSucceed {
            throw TaskSplitterError.serverError("Mock server error")
        }
        
        // カスタムステップが設定されている場合
        if let steps = customSteps {
            return steps
        }
        
        // デフォルトのモック実装（サーバーと同じロジック）
        return [
            "\(task)の準備をする",
            "\(task)の計画を立てる",
            "\(task)を実行する",
            "\(task)の確認をする",
            "\(task)を完了させる"
        ]
    }
}

// MARK: - Test Helpers

extension MockTaskSplitterClient {
    /// 成功レスポンスを設定
    func configureSuccess(steps: [String]? = nil, delay: TimeInterval = 0.5) {
        shouldSucceed = true
        customSteps = steps
        mockDelay = delay
        customError = nil
    }
    
    /// エラーレスポンスを設定
    func configureError(_ error: TaskSplitterError, delay: TimeInterval = 0.5) {
        shouldSucceed = false
        customError = error
        mockDelay = delay
        customSteps = nil
    }
    
    /// ネットワークエラーを設定
    func configureNetworkError(delay: TimeInterval = 0.5) {
        configureError(.networkError(URLError(.networkConnectionLost)), delay: delay)
    }
    
    /// サーバーエラーを設定
    func configureServerError(_ message: String = "Server temporarily unavailable", delay: TimeInterval = 0.5) {
        configureError(.serverError(message), delay: delay)
    }
    
    /// 設定をリセット
    func reset() {
        shouldSucceed = true
        mockDelay = 0.5
        customSteps = nil
        customError = nil
        environment = .production
    }
}