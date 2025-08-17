import SwiftUI

struct StepExecutionView: View {
    let steps: [String]
    let taskTitle: String
    let onTaskCompleted: () -> Void
    
    @State private var currentStepIndex: Int = 0
    @State private var completedSteps: Set<Int> = []
    @State private var showCompletionAlert = false
    @State private var showCompletionAnimation = false
    @State private var animateConfetti = false
    @State private var animateSuccessIcon = false
    @State private var animationScale: CGFloat = 0.1
    
    init(steps: [String], taskTitle: String = "", onTaskCompleted: @escaping () -> Void) {
        self.steps = steps
        self.taskTitle = taskTitle
        self.onTaskCompleted = onTaskCompleted
    }
    
    private var allStepsCompleted: Bool {
        completedSteps.count == steps.count
    }
    
    private var currentStep: String? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                // Task title display
                if !taskTitle.isEmpty {
                    Text(taskTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Progress indicator
                VStack(alignment: .leading, spacing: 8) {
                    Text("進捗: \(completedSteps.count)/\(steps.count)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: Double(completedSteps.count), total: Double(steps.count))
                        .tint(.blue)
                }
                .padding(.horizontal)
            
            // Current step display
            if let step = currentStep {
                VStack(spacing: 16) {
                    Text("ステップ \(currentStepIndex + 1)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text(step)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    
                    HStack(spacing: 16) {
                        Button("完了") {
                            completeCurrentStep()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(completedSteps.contains(currentStepIndex))
                        
                        if currentStepIndex > 0 {
                            Button("前のステップ") {
                                currentStepIndex = max(0, currentStepIndex - 1)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if currentStepIndex < steps.count - 1 {
                            Button("次のステップ") {
                                currentStepIndex = min(steps.count - 1, currentStepIndex + 1)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        
        // Completion Animation
        if showCompletionAnimation {
            CompletionAnimationView(
                animateConfetti: $animateConfetti,
                animateSuccessIcon: $animateSuccessIcon,
                animationScale: $animationScale
            )
        }
    }
    .navigationTitle("ステップ実行")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(allStepsCompleted)
    .toolbar {
        if !allStepsCompleted {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    onTaskCompleted()
                }
            }
        }
    }
    .alert("タスク完了！", isPresented: $showCompletionAlert) {
        Button("OK") {
            onTaskCompleted()
        }
    } message: {
        Text("おめでとうございます！\nすべてのステップを完了しました。")
    }
}

    private func completeCurrentStep() {
        completedSteps.insert(currentStepIndex)
        
        if allStepsCompleted {
            showCompletionAnimation = true
            animateConfetti = true
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateSuccessIcon = true
                animationScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showCompletionAlert = true
                showCompletionAnimation = false
            }
        } else if currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
        }
    }
}

// MARK: - Completion Animation View

struct CompletionAnimationView: View {
    @Binding var animateConfetti: Bool
    @Binding var animateSuccessIcon: Bool
    @Binding var animationScale: CGFloat
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                    .scaleEffect(animationScale)
                    .opacity(animateSuccessIcon ? 1 : 0)
                
                Text("素晴らしい！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(animateSuccessIcon ? 1 : 0)
                
                Text("すべてのステップを完了しました")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(animateSuccessIcon ? 1 : 0)
            }
            
            // Confetti
            if animateConfetti {
                ConfettiView()
            }
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    Rectangle()
                        .fill(piece.color)
                        .frame(width: 10, height: 10)
                        .position(piece.position)
                        .opacity(piece.opacity)
                        .rotationEffect(piece.rotation)
                }
            }
            .onAppear {
                createConfetti(in: geometry.size)
            }
        }
    }
    
    private func createConfetti(in size: CGSize) {
        for _ in 0..<50 {
            let piece = ConfettiPiece(
                position: CGPoint(x: CGFloat.random(in: 0...size.width),
                                 y: -20),
                color: [Color.red, Color.blue, Color.green, Color.yellow, Color.purple].randomElement()!,
                rotation: Angle(degrees: Double.random(in: 0...360))
            )
            confettiPieces.append(piece)
        }
        
        // Animate falling
        withAnimation(.linear(duration: 3)) {
            for index in confettiPieces.indices {
                confettiPieces[index].position.y = size.height + 20
                confettiPieces[index].opacity = 0
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    var rotation: Angle
    var opacity: Double = 1
}