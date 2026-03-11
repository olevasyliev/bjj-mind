import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        let _ = appState.language  // observe language changes for tab labels
        return TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(L10n.Tab.train, systemImage: selectedTab == 0 ? "map.fill" : "map")
                }
                .tag(0)

            CompeteView()
                .tabItem {
                    Label(L10n.Tab.compete, systemImage: "trophy.fill")
                }
                .tag(1)

            ProgressView()
                .tabItem {
                    Label(L10n.Tab.progress, systemImage: "chart.bar.fill")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label(L10n.Tab.profile, systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.brand)
        .preferredColorScheme(.light)
    }
}
