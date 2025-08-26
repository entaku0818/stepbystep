import XCTest

class SnapshotHelper: NSObject {
    
    static func setupSnapshot(_ app: XCUIApplication) {
        Snapshot.setupSnapshot(app)
    }
    
    static func snapshot(_ name: String) {
        Snapshot.snapshot(name)
    }
}

extension XCUIElement {
    func waitForExistence(timeout: TimeInterval) -> Bool {
        return self.waitForExistence(timeout: timeout)
    }
}