import SwiftUI

// MARK: - Subscription Screenshot

struct SubscriptionScreenshotView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: {}) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("Task Steps Pro")
                    .font(.headline)
                
                Spacer()
                
                Color.clear
                    .frame(width: 24, height: 24)
            }
            .padding()
            .background(Color.white)
            
            // Content
            ScrollView {
                VStack(spacing: 32) {
                    // Crown Icon
                    Image(systemName: "crown.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                        .padding(.top, 40)
                    
                    // Title
                    VStack(spacing: 12) {
                        Text("Task Steps Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("すべての機能を無制限に")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRowScreenshot(
                            icon: "infinity",
                            title: "無制限のタスク分割",
                            description: "1日の使用回数制限なし"
                        )
                        
                        FeatureRowScreenshot(
                            icon: "square.split.2x1",
                            title: "ステップを子タスクに分割",
                            description: "複雑なステップをさらに細分化"
                        )
                        
                        FeatureRowScreenshot(
                            icon: "play.slash",
                            title: "広告なし",
                            description: "集中を妨げる広告を完全に除去"
                        )
                        
                    }
                    .padding()
                    .background(Color.indigo.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Price
                    VStack(spacing: 8) {
                        Text("月額")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("¥500")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.indigo)
                        
                        Text("いつでもキャンセル可能")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Subscribe Button
                    Button(action: {}) {
                        Text("今すぐ始める")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Restore
                    Button(action: {}) {
                        Text("購入を復元")
                            .font(.caption)
                            .foregroundColor(.indigo)
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(Color.gray.opacity(0.05))
        }
    }
}

struct FeatureRowScreenshot: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.indigo)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}