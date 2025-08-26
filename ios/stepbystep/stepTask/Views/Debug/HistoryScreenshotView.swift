import SwiftUI

// MARK: - History Screenshot

struct HistoryScreenshotView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Spacer()
                Text("タスク履歴")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            .background(Color.white)
            
            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // Summary Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("今月の達成")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("12タスク")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Task List
                    ForEach(0..<3) { index in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(index == 0 ? "部屋を片付ける" : 
                                         index == 1 ? "レポートを書く" : "買い物に行く")
                                        .font(.headline)
                                    
                                    Text(index == 0 ? "今日 14:30" : 
                                         index == 1 ? "昨日 10:15" : "3日前")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("完了")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(4)
                                    
                                    Text(index == 0 ? "25分" : 
                                         index == 1 ? "45分" : "15分")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Steps Summary
                            HStack(spacing: 4) {
                                ForEach(0..<5) { _ in
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                }
                                
                                Spacer()
                                
                                Text("5/5 ステップ")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                    }
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            
            // Tab Bar
            HStack {
                ForEach(["タスク", "履歴", "設定"], id: \.self) { tab in
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: tab == "タスク" ? "plus.circle" : 
                              tab == "履歴" ? "clock.fill" : "gearshape")
                            .font(.title2)
                        Text(tab)
                            .font(.caption2)
                    }
                    .foregroundColor(tab == "履歴" ? .blue : .gray)
                    Spacer()
                }
            }
            .padding(.vertical, 8)
            .background(Color.white)
        }
    }
}