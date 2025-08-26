import SwiftUI

// MARK: - Task Splitting Screenshot

struct TaskSplittingScreenshotView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Spacer()
                Text("Task Steps")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.indigo)
                Spacer()
            }
            .padding()
            .background(Color.white)
            
            // Content
            VStack(spacing: 40) {
                Spacer()
                
                // Loading Animation
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.indigo.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        ProgressView()
                            .scaleEffect(2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .indigo))
                    }
                    
                    VStack(spacing: 8) {
                        Text("AIがタスクを分析中...")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("5つのステップに分割しています")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress Dots
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index < 3 ? Color.indigo : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.05))
        }
    }
}