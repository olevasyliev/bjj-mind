import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    let onContinue: () -> Void

    var body: some View {
        let _ = appState.language
        ZStack(alignment: .topTrailing) {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image("gi-ghost")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 420)
                    .padding(.bottom, 8)

                VStack(spacing: 10) {
                    Text("BJJ Mind")
                        .font(.appTitle)
                        .foregroundColor(.brand)
                        .tracking(-1.5)

                    Text(L10n.Welcome.subtitle)
                        .font(.bodyLg)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton(title: L10n.Welcome.getStarted, action: onContinue)
                    SecondaryButton(title: L10n.Welcome.haveAccount, action: {})
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
            }

            LanguageToggleButton()
                .padding(.top, 56)
                .padding(.trailing, 24)
        }
    }
}
