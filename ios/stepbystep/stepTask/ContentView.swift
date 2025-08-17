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