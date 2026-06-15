import SwiftUI

@main
struct AlgoRhythmApp: App {
    @StateObject private var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .preferredColorScheme(.dark)
        }
    }
}
