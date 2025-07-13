import Foundation

// MARK: - Live Implementation

class LiveTaskSplitterClient: TaskSplitterClient {
    var environment: APIEnvironment = .production // デフォルトは本番環境
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func splitTask(_ task: String) async throws -> [String] {
        // バリデーション
        guard task.count >= 5 && task.count <= 100 else {
            throw TaskSplitterError.invalidTask
        }
        
        // 本番環境設定済み
        
        // URL構築
        guard let url = URL(string: "\(environment.baseURL)/splitTask") else {
            throw TaskSplitterError.invalidURL
        }
        
        // リクエスト構築
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = TaskSplitRequest(task: task)
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw TaskSplitterError.networkError(error)
        }
        
        // API呼び出し
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TaskSplitterError.invalidResponse
            }
            
            // ステータスコードチェック
            switch httpResponse.statusCode {
            case 200:
                // 成功レスポンスをパース
                let splitResponse = try JSONDecoder().decode(TaskSplitResponse.self, from: data)
                return splitResponse.steps
                
            case 400...499:
                // クライアントエラー
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    throw TaskSplitterError.serverError(apiError.error)
                } else {
                    throw TaskSplitterError.serverError("Client error: \(httpResponse.statusCode)")
                }
                
            case 500...599:
                // サーバーエラー
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    throw TaskSplitterError.serverError(apiError.error)
                } else {
                    throw TaskSplitterError.serverError("Server error: \(httpResponse.statusCode)")
                }
                
            default:
                throw TaskSplitterError.serverError("Unexpected status code: \(httpResponse.statusCode)")
            }
            
        } catch {
            if error is TaskSplitterError {
                throw error
            } else {
                throw TaskSplitterError.networkError(error)
            }
        }
    }
}

// MARK: - Environment Switching Helper

extension LiveTaskSplitterClient {
    /// 現在の環境情報を取得
    var currentEnvironmentInfo: String {
        return "\(environment.description): \(environment.baseURL)"
    }
}