import SwiftUI
import Photos

struct ScreenshotCaptureView: View {
    @State private var currentIndex: Int = 0
    @State private var capturedImages: [UIImage] = []
    @State private var isCapturing = false
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var captureProgress: Double = 0
    @Environment(\.dismiss) var dismiss
    
    enum ScreenshotType: String, CaseIterable {
        case taskInput = "タスク入力"
        case taskSplitting = "タスク分割中"
        case stepExecution = "ステップ実行"
        case completion = "完了画面"
        case history = "履歴"
        case subscription = "サブスクリプション"
        
        var fileName: String {
            switch self {
            case .taskInput: return "01_task_input"
            case .taskSplitting: return "02_task_splitting"
            case .stepExecution: return "03_step_execution"
            case .completion: return "04_completion"
            case .history: return "05_history"
            case .subscription: return "06_subscription"
            }
        }
    }
    
    private let screens = ScreenshotType.allCases
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            if isCapturing {
                captureProgressView
            } else {
                mainContent
            }
        }
        .preferredColorScheme(.light)
        .statusBar(hidden: true)
        .alert("保存完了", isPresented: $showingSaveAlert) {
            Button("OK") { 
                if saveAlertMessage.contains("成功") {
                    dismiss()
                }
            }
        } message: {
            Text(saveAlertMessage)
        }
    }
    
    private var mainContent: some View {
        VStack {
            TabView(selection: $currentIndex) {
                ForEach(0..<screens.count, id: \.self) { index in
                    screenView(for: screens[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            controlPanel
        }
    }
    
    private var controlPanel: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(0..<screens.count, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(screens[currentIndex].rawValue)
                .font(.headline)
            
            HStack(spacing: 30) {
                Button(action: captureAllScreenshots) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.title)
                        Text("全て撮影")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Button(action: captureCurrentScreen) {
                    VStack {
                        Image(systemName: "camera")
                            .font(.title)
                        Text("現在の画面")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(Color.green)
                    .cornerRadius(12)
                }
                
                Button(action: { dismiss() }) {
                    VStack {
                        Image(systemName: "xmark")
                            .font(.title)
                        Text("閉じる")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(Color.gray)
                    .cornerRadius(12)
                }
            }
            .padding(.bottom, 30)
        }
        .padding()
        .background(
            Color.white
                .shadow(color: .gray.opacity(0.2), radius: 10, y: -5)
        )
    }
    
    private var captureProgressView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("スクリーンショット撮影中...")
                .font(.headline)
            
            Text("\(Int(captureProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: captureProgress)
                .frame(width: 200)
        }
        .padding(40)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    private func screenView(for type: ScreenshotType) -> some View {
        Group {
            switch type {
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
    
    private func captureCurrentScreen() {
        let view = screenView(for: screens[currentIndex])
        let hostingController = UIHostingController(rootView: view)
        
        let targetSize = CGSize(width: 393, height: 852)
        hostingController.view.bounds = CGRect(origin: .zero, size: targetSize)
        hostingController.view.backgroundColor = .white
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { _ in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
        
        saveImageToPhotos(image, fileName: screens[currentIndex].fileName)
    }
    
    private func captureAllScreenshots() {
        isCapturing = true
        captureProgress = 0
        capturedImages = []
        
        Task {
            for (index, screen) in screens.enumerated() {
                await captureScreen(type: screen)
                await MainActor.run {
                    captureProgress = Double(index + 1) / Double(screens.count)
                }
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            
            await MainActor.run {
                isCapturing = false
                saveAllImages()
            }
        }
    }
    
    @MainActor
    private func captureScreen(type: ScreenshotType) async {
        let view = screenView(for: type)
        let hostingController = UIHostingController(rootView: view)
        
        let targetSize = CGSize(width: 393, height: 852)
        hostingController.view.bounds = CGRect(origin: .zero, size: targetSize)
        hostingController.view.backgroundColor = .white
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { _ in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
        
        capturedImages.append(image)
    }
    
    private func saveAllImages() {
        var savedCount = 0
        var failedCount = 0
        
        for (index, image) in capturedImages.enumerated() {
            let fileName = screens[index].fileName
            saveImageToPhotos(image, fileName: fileName) { success in
                if success {
                    savedCount += 1
                } else {
                    failedCount += 1
                }
                
                if savedCount + failedCount == capturedImages.count {
                    if failedCount == 0 {
                        saveAlertMessage = "\(savedCount)枚のスクリーンショットを保存しました"
                    } else {
                        saveAlertMessage = "\(savedCount)枚保存成功、\(failedCount)枚保存失敗"
                    }
                    showingSaveAlert = true
                }
            }
        }
    }
    
    private func saveImageToPhotos(_ image: UIImage, fileName: String, completion: ((Bool) -> Void)? = nil) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    PHPhotoLibrary.shared().performChanges {
                        let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                        request.creationDate = Date()
                    } completionHandler: { success, error in
                        DispatchQueue.main.async {
                            if let completion = completion {
                                completion(success)
                            } else {
                                if success {
                                    saveAlertMessage = "保存に成功しました"
                                } else {
                                    saveAlertMessage = "保存に失敗しました: \(error?.localizedDescription ?? "不明なエラー")"
                                }
                                showingSaveAlert = true
                            }
                        }
                    }
                } else {
                    if let completion = completion {
                        completion(false)
                    } else {
                        saveAlertMessage = "写真へのアクセス権限が必要です"
                        showingSaveAlert = true
                    }
                }
            }
        }
    }
}

#Preview {
    ScreenshotCaptureView()
}