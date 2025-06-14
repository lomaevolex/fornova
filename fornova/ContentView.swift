import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        DocumentListView()
            .environment(\.managedObjectContext,
                          PersistenceController.shared.container.viewContext)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController(inMemory: true)
        ContentView()
            .environment(\.managedObjectContext,
                          controller.container.viewContext)
    }
}
