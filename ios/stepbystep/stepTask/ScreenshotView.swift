import SwiftUI

// MARK: - Screenshot View

struct ScreenshotView: View {
    @State private var selectedScreen: ScreenshotType = .taskInput
    @Environment(\.dismiss) var dismiss
    
    enum ScreenshotType: String, CaseIterable {
        case taskInput = "タスク入力"
        case taskSplitting = "タスク分割中"
        case stepExecution = "ステップ実行"
        case completion = "完了画面"
        case history = "履歴"
        case subscription = "サブスクリプション"
        
        var description: String {
            switch self {
            case .taskInput:
                return "タスクを入力する初期画面"
            case .taskSplitting:
                return "AIがタスクを分割している画面"
            case .stepExecution:
                return "ステップを一つずつ実行する画面"
            case .completion:
                return "タスク完了のお祝い画面"
            case .history:
                return "完了したタスクの履歴画面"
            case .subscription:
                return "Pro版の紹介画面"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("閉じる") {
                        dismiss()
                    }
                    Spacer()
                    Text("スクリーンショットモード")
                        .font(.headline)
                    Spacer()
                    Text("5.5\"用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                
                // Screen Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ScreenshotType.allCases, id: \.self) { type in
                            Button(action: { selectedScreen = type }) {
                                VStack(spacing: 4) {
                                    Text(type.rawValue)
                                        .font(.caption)
                                        .fontWeight(selectedScreen == type ? .bold : .regular)
                                    
                                    if selectedScreen == type {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.blue)
                                            .frame(height: 3)
                                    } else {
                                        Color.clear.frame(height: 3)
                                    }
                                }
                                .foregroundColor(selectedScreen == type ? .blue : .secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
                
                // Preview Area
                GeometryReader { geometry in
                    ZStack {
                        // Background
                        Color(UIColor.systemGroupedBackground)
                        
                        // Content
                        selectedScreenView
                            .frame(width: 428, height: 926) // iPhone 14 Pro Max size
                            .scaleEffect(min(geometry.size.width / 428, geometry.size.height / 926))
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(radius: 10)
                    }
                }
            }
        }
        .preferredColorScheme(.light) // Force light mode for screenshots
    }
    
    @ViewBuilder
    var selectedScreenView: some View {
        switch selectedScreen {
        case .taskInput:
            TaskInputScreenshotView()
        case .taskSplitting:
            TaskSplittingScreenshotView()
        case .stepExecution:
            StepExecutionScreenshotView()
        case .completion:
            CompletionScreenshotView()
        case .history:
            HistoryScreenshotView()
        case .subscription:
            SubscriptionScreenshotView()
        }
    }
}

// MARK: - Task Input Screenshot

struct TaskInputScreenshotView: View {
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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("ステップタスク")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("AIでタスクを分割して管理する")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Task Input Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("新しいタスク")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("タスクを入力")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("部屋を片付ける")
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("AIで5つのステップに分割")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
                    
                    // Usage Limit
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("今日の残り使用回数: 2回")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            
            // Tab Bar
            HStack {
                ForEach(["タスク", "履歴", "設定"], id: \.self) { tab in
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: tab == "タスク" ? "plus.circle.fill" : 
                              tab == "履歴" ? "clock" : "gearshape")
                            .font(.title2)
                        Text(tab)
                            .font(.caption2)
                    }
                    .foregroundColor(tab == "タスク" ? .blue : .gray)
                    Spacer()
                }
            }
            .padding(.vertical, 8)
            .background(Color.white)
        }
    }
}

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
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

// MARK: - Step Execution Screenshot

struct StepExecutionScreenshotView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("ステップ 2/5")
                    .font(.headline)
                
                Spacer()
                
                Button("完了") {
                    
                }
                .foregroundColor(.blue)
                .fontWeight(.medium)
            }
            .padding()
            .background(Color.white)
            
            // Content
            VStack(spacing: 0) {
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(Color.indigo)
                            .frame(width: geometry.size.width * 0.4, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                // Current Step
                VStack(spacing: 32) {
                    // Step Number
                    ZStack {
                        Circle()
                            .fill(Color.indigo)
                            .frame(width: 80, height: 80)
                        
                        Text("2")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Step Content
                    VStack(spacing: 16) {
                        Text("本を本棚に戻す")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("散らばっている本を集めて、本棚の適切な場所に戻しましょう")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Complete Button
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("このステップを完了")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Navigation Hint
                HStack {
                    Text("前のステップ")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("次のステップ")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

// MARK: - Completion Screenshot

struct CompletionScreenshotView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Content
            VStack(spacing: 40) {
                Spacer()
                
                // Trophy Icon
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                }
                
                // Congratulations Text
                VStack(spacing: 16) {
                    Text("おめでとう！")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("タスクを完了しました")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Stats
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("5/5 ステップ完了")
                            .font(.headline)
                    }
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("所要時間: 25分")
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {}) {
                        Text("新しいタスクを始める")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {}) {
                        Text("履歴を見る")
                            .font(.headline)
                            .foregroundColor(.indigo)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.indigo.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

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
            .background(Color(UIColor.systemGroupedBackground))
            
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
                        
                        FeatureRowScreenshot(
                            icon: "star.fill",
                            title: "優先サポート",
                            description: "お問い合わせに優先的に対応"
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
            .background(Color(UIColor.systemGroupedBackground))
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