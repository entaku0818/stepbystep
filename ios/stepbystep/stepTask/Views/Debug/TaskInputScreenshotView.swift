import SwiftUI

// MARK: - Task Input Screenshot

struct TaskInputScreenshotView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // ヘッダーセクション
                Text("ステップタスクAIでタスクを分割して管理する")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
                
                // タスク入力セクション
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("タスク名")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 残り使用回数を表示
                        Text("本日の残り: 3回")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // TextEditor風の入力欄
                    Text("部屋を片付ける")
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(12)
                        .frame(minHeight: 80, maxHeight: 120)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // 保存ボタン
                Button(action: {}) {
                    Text("タスクを分割")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("新しいタスク")
        }
    }
}