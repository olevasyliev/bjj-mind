import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    let onContinue: () -> Void

    var body: some View {
        let _ = appState.language  // observe language for re-render
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.brandVeryPale)
                        .frame(width: 200, height: 200)
                        .shadow(color: Color.brand.opacity(0.22), radius: 20, x: 0, y: 16)
                    Text("🥋")
                        .font(.system(size: 90))
                }
                .padding(.bottom, 32)

                VStack(spacing: 8) {
                    Text("BJJ Mind")
                        .font(.appTitle)
                        .foregroundColor(.brand)
                        .tracking(-1.5)

                    Text(L10n.Welcome.subtitle)
                        .font(.bodyLg)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 28)

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
        .background(Color.screenBg.ignoresSafeArea())
    }
}
