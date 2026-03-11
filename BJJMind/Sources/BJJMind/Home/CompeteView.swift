import SwiftUI

struct CompeteView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🏆")
                .font(.system(size: 64))
            Text(L10n.Compete.title)
                .font(.screenTitle)
                .foregroundColor(.textPrimary)
            Text(L10n.Compete.comingSoon)
                .font(.bodyMd)
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}
