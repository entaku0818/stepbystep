import XCTest

final class ScreenshotUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testCaptureAllScreenshots() throws {
        navigateToDebugMenu()
        navigateToScreenshotMode()
        
        captureTaskInputScreen()
        captureTaskSplittingScreen()
        captureStepExecutionScreen()
        captureCompletionScreen()
        captureHistoryScreen()
        captureSubscriptionScreen()
    }
    
    private func navigateToDebugMenu() {
        let settingsButton = app.buttons["settings"]
        if settingsButton.exists {
            settingsButton.tap()
        }
        
        let debugMenuItem = app.buttons["デバッグメニュー"]
        if debugMenuItem.exists {
            debugMenuItem.tap()
        }
    }
    
    private func navigateToScreenshotMode() {
        let screenshotSection = app.staticTexts["スクリーンショット"]
        if screenshotSection.exists {
            screenshotSection.swipeUp()
        }
        
        let screenshotModeButton = app.buttons["スクリーンショットモード"]
        if screenshotModeButton.exists {
            screenshotModeButton.tap()
            sleep(1)
        }
    }
    
    private func captureTaskInputScreen() {
        snapshot("01_TaskInput")
        swipeToNextScreen()
    }
    
    private func captureTaskSplittingScreen() {
        snapshot("02_TaskSplitting")
        swipeToNextScreen()
    }
    
    private func captureStepExecutionScreen() {
        snapshot("03_StepExecution")
        swipeToNextScreen()
    }
    
    private func captureCompletionScreen() {
        snapshot("04_Completion")
        swipeToNextScreen()
    }
    
    private func captureHistoryScreen() {
        snapshot("05_History")
        swipeToNextScreen()
    }
    
    private func captureSubscriptionScreen() {
        snapshot("06_Subscription")
    }
    
    private func swipeToNextScreen() {
        app.swipeLeft()
        sleep(1)
    }
    
    private func setupSnapshot(_ app: XCUIApplication) {
        Snapshot.setupSnapshot(app)
    }
    
    private func snapshot(_ name: String) {
        Snapshot.snapshot(name)
    }
}

class Snapshot: NSObject {
    
    static var app: XCUIApplication?
    static var deviceLanguage = ""
    static var locale = ""
    
    @objc class func setupSnapshot(_ app: XCUIApplication) {
        Snapshot.app = app
        
        do {
            let launchArguments = try String(contentsOf: URL(fileURLWithPath: "/tmp/SnapshotHelperArguments.txt"), encoding: .utf8)
            let arguments = launchArguments.components(separatedBy: "\n")
            
            deviceLanguage = arguments[0]
            locale = arguments[1]
            app.launchArguments += ["-AppleLanguages", "(\(deviceLanguage))", "-AppleLocale", locale]
        } catch {
            print("Couldn't detect App arguments")
        }
    }
    
    @objc class func snapshot(_ name: String, waitForLoadingIndicator: Bool = true) {
        guard let app = app else {
            print("XCUIApplication is not set. Please call setupSnapshot(app) before snapshot().")
            return
        }
        
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "Screenshot: \(name)") { activity in
            activity.add(attachment)
        }
    }
}