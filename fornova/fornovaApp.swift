// fornovaApp.swift

import SwiftUI

@main
struct fornovaApp: App {
    let persistenceController = PersistenceController.shared

    /// Флаг, видел ли пользователь welcome
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
