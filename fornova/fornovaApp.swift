import SwiftUI

@main
struct fornovaApp: App {
    let persistenceController = PersistenceController.shared

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false

    var body: some Scene {
        WindowGroup {
            if hasSeenWelcome {
                DocumentListView()
                    .environment(\.managedObjectContext,
                                  persistenceController.container.viewContext)
            } else {
                WelcomeFirstView(isPresented: $hasSeenWelcome)
            }
        }
    }
}
