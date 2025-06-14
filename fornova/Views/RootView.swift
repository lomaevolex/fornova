import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @State private var showWelcome: Bool = false

    var body: some View {
        DocumentListView()
            .onAppear {
                // Если первый запуск — открываем плашку
                if !hasSeenWelcome {
                    showWelcome = true
                }
            }
            .sheet(isPresented: $showWelcome, onDismiss: {
                // После закрытия больше не показываем
                hasSeenWelcome = true
            }) {
                WelcomeView(isPresented: $showWelcome)
            }
    }
}
