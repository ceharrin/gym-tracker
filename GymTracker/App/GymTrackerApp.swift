import SwiftUI

@main
struct GymTrackerApp: App {
    let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistence.context)
        }
    }
}
