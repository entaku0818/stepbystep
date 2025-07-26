//
//  stepbystepApp.swift
//  stepbystep
//
//  Created by 遠藤拓弥 on 2025/06/29.
//

import SwiftUI
import FirebaseCore
import ComposableArchitecture

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // AdMobの初期化
        _ = AdMobManager.shared
        
        return true
    }
}

@main
struct stepbystepApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            MainTabView(
                store: Store(initialState: MainTabReducer.State()) {
                    MainTabReducer()
                }
            )
        }
    }
}
