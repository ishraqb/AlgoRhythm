import SwiftUI

/// Top-level gate. Until the user is signed in we show the auth flow; after
/// that, the three-tab study experience. The deck view model lives here so the
/// Study and Progress tabs share one source of truth.
struct RootView: View {
    @EnvironmentObject private var auth: AuthManager
    @StateObject private var deck = DeckViewModel()

    var body: some View {
        Group {
            if auth.isAuthenticated {
                mainTabs
            } else {
                AuthView()
            }
        }
        .tint(Theme.accent)
        .onAppear { auth.attach(to: deck) }
    }

    private var mainTabs: some View {
        TabView {
            StudyView()
                .tabItem { Label("Study", systemImage: "rectangle.stack.fill") }

            StatsView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }

            CreditsView()
                .tabItem { Label("Credits", systemImage: "info.circle.fill") }
        }
        .environmentObject(deck)
    }
}
