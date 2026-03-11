import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Text("📊")
                    .font(.system(size: 64))
                Text(L10n.Progress.title)
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)
                Text(L10n.Progress.comingSoon)
                    .font(.bodyMd)
                    .foregroundColor(.textMuted)
                Spacer()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(L10n.Progress.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
