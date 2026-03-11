import SwiftUI

@main
struct BJJMindApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.currentScreen {
            case .onboarding:
                OnboardingFlow()
            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
    }
}
