import Foundation
import Dependencies

// MARK: - API Environment

enum APIEnvironment: CaseIterable {
    case local      // Firebase Emulator (開発用)
    case production // Firebase Functions (本番用)
    
    var baseURL: String {
        switch self {
        case .local:
            return "http://127.0.0.1:5001/stepbystep-tasks/us-central1"
        case .production:
            // TODO: 本番URL設定時に更新
            return ""
        }
    }
    
    var description: String {
        switch self {
        case .local:
            return "Local Emulator"
        case .production:
            return "Production Server (未設定)"
        }
    }
}

// MARK: - Response Models

struct TaskSplitResponse: Codable {
    let success: Bool
    let steps: [String]
    let originalTask: String
}

struct TaskSplitRequest: Codable {
    let task: String
}

struct APIError: Codable {
    let error: String
    let message: String?
}

// MARK: - Client Protocol

protocol TaskSplitterClient {
    var environment: APIEnvironment { get set }
    func splitTask(_ task: String) async throws -> [String]
}

// MARK: - Dependency Key

private enum TaskSplitterClientKey: DependencyKey {
    static let liveValue: TaskSplitterClient = LiveTaskSplitterClient()
    static let testValue: TaskSplitterClient = MockTaskSplitterClient()
}

extension DependencyValues {
    var taskSplitterClient: TaskSplitterClient {
        get { self[TaskSplitterClientKey.self] }
        set { self[TaskSplitterClientKey.self] = newValue }
    }
}

// MARK: - Custom Errors

enum TaskSplitterError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    case invalidTask
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidTask:
            return "Task must be between 5 and 100 characters"
        }
    }
}