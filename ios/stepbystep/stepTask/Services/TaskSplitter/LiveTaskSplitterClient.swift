import Foundation

// MARK: - Live Implementation

class LiveTaskSplitterClient: TaskSplitterClient {
    var environment: APIEnvironment = .production // デフォルトは本番環境
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func splitTask(_ task: String) async throws -> [String] {
        print("🔵 [TaskSplitter] Starting task split for: '\(task)'")
        
        // バリデーション
        guard task.count >= 5 && task.count <= 100 else {
            print("❌ [TaskSplitter] Task validation failed. Length: \(task.count) (must be 5-100)")
            throw TaskSplitterError.invalidTask
        }
        
        // 本番環境設定済み
        print("🔵 [TaskSplitter] Using environment: \(environment.description)")
        print("🔵 [TaskSplitter] Base URL: \(environment.baseURL)")
        
        // URL構築
        let urlString = "\(environment.baseURL)/splitTask"
        print("🔵 [TaskSplitter] Full URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [TaskSplitter] Failed to create URL from: \(urlString)")
            throw TaskSplitterError.invalidURL
        }
        
        // リクエスト構築
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.stepByStepApiKey, forHTTPHeaderField: "X-API-Key")
        
        let requestBody = TaskSplitRequest(task: task)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            request.httpBody = try encoder.encode(requestBody)
            
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("🔵 [TaskSplitter] Request body: \(bodyString)")
            }
        } catch {
            print("❌ [TaskSplitter] Failed to encode request body: \(error)")
            throw TaskSplitterError.networkError(error)
        }
        
        // API呼び出し
        do {
            print("🔵 [TaskSplitter] Sending request...")
            let (data, response) = try await session.data(for: request)
            
            print("🔵 [TaskSplitter] Response received. Data size: \(data.count) bytes")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔵 [TaskSplitter] Response body: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [TaskSplitter] Response is not HTTPURLResponse")
                throw TaskSplitterError.invalidResponse
            }
            
            print("🔵 [TaskSplitter] HTTP Status Code: \(httpResponse.statusCode)")
            print("🔵 [TaskSplitter] Response headers: \(httpResponse.allHeaderFields)")
            
            // ステータスコードチェック
            switch httpResponse.statusCode {
            case 200:
                // 成功レスポンスをパース
                print("✅ [TaskSplitter] Success response. Parsing JSON...")
                do {
                    let splitResponse = try JSONDecoder().decode(TaskSplitResponse.self, from: data)
                    print("✅ [TaskSplitter] Successfully parsed response with \(splitResponse.steps.count) steps")
                    for (index, step) in splitResponse.steps.enumerated() {
                        print("  Step \(index + 1): \(step)")
                    }
                    return splitResponse.steps
                } catch {
                    print("❌ [TaskSplitter] Failed to decode success response: \(error)")
                    throw TaskSplitterError.networkError(error)
                }
                
            case 400...499:
                // クライアントエラー
                print("⚠️ [TaskSplitter] Client error: \(httpResponse.statusCode)")
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    print("⚠️ [TaskSplitter] API error message: \(apiError.error)")
                    throw TaskSplitterError.serverError(apiError.error)
                } else {
                    throw TaskSplitterError.serverError("Client error: \(httpResponse.statusCode)")
                }
                
            case 500...599:
                // サーバーエラー
                print("⚠️ [TaskSplitter] Server error: \(httpResponse.statusCode)")
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    print("⚠️ [TaskSplitter] API error message: \(apiError.error)")
                    throw TaskSplitterError.serverError(apiError.error)
                } else {
                    throw TaskSplitterError.serverError("Server error: \(httpResponse.statusCode)")
                }
                
            default:
                print("❌ [TaskSplitter] Unexpected status code: \(httpResponse.statusCode)")
                throw TaskSplitterError.serverError("Unexpected status code: \(httpResponse.statusCode)")
            }
            
        } catch {
            print("❌ [TaskSplitter] Request failed with error: \(error)")
            print("❌ [TaskSplitter] Error type: \(type(of: error))")
            print("❌ [TaskSplitter] Error description: \(error.localizedDescription)")
            
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