//
//  ContentView.swift
//  stepbystep
//
//  Created by 遠藤拓弥 on 2025/06/29.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    var body: some View {
        TaskInputView(
            store: Store(initialState: TaskInputReducer.State()) {
                TaskInputReducer()
            }
        )
    }
}

#Preview {
    ContentView()
}
