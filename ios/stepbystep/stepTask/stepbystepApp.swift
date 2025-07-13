//
//  stepbystepApp.swift
//  stepbystep
//
//  Created by 遠藤拓弥 on 2025/06/29.
//

import SwiftUI
import ComposableArchitecture

@main
struct stepbystepApp: App {
    init() {
        // AdMobの初期化
        _ = AdMobManager.shared
    }
    
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
