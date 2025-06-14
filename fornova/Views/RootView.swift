import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @State private var showWelcome: Bool = false

    var body: some View {
        DocumentListView()
            .onAppear {
                if !hasSeenWelcome {
                    showWelcome = true
                }
            }
            .sheet(isPresented: $showWelcome, onDismiss: {
                hasSeenWelcome = true
            }) {
                WelcomeView(isPresented: $showWelcome)
            }
    }
}
