import SwiftUI

// MARK: - Step Execution Screenshot

struct StepExecutionScreenshotView: View {
    var body: some View {
        VStack(spacing: 24) {
                // Task title display
                Text("部屋を片付ける")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Progress indicator
                VStack(alignment: .leading, spacing: 8) {
                    Text("進捗: 2/5")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: 0.4, total: 1.0)
                        .tint(.blue)
                }
                
                // Current step display
                VStack(spacing: 16) {
                    HStack {
                        Text("ステップ 2")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                    
                    Text("不要なものを仕分けして捨てるか、保管する場所を決める")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                
                // Complete button
                Button(action: {}) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("完了")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Spacer()
        }
        .padding()
        .navigationTitle("ステップ実行")
    }
}