import SwiftUI

struct InlineTheoryCardView: View {
    let data: MiniTheoryData
    let subTopicSlug: String
    let onDismiss: () -> Void

    @State private var currentScreen: Int = 0

    private var screen: MiniTheoryScreen {
        data.screens[min(currentScreen, data.screens.count - 1)]
    }

    private var isLastScreen: Bool {
        currentScreen >= data.screens.count - 1
    }

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    // Title
                    if let title = screen.title {
                        Text(title)
                            .font(.nunito(22, weight: .black))
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Body
                    Text(screen.body)
                        .font(.bodyMd)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)

                    // Coach line
                    if let coachLine = screen.coachLine {
                        HStack(spacing: 10) {
                            Image("marco")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())

                            Text(coachLine)
                                .font(.nunito(14, weight: .semiBold))
                                .foregroundColor(.textMuted)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 32)
                    }
                }

                Spacer()

                // Progress dots for multiple screens
                if data.screens.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<data.screens.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentScreen ? Color.brand : Color.brandPale)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 16)
                }

                // Action button
                if isLastScreen {
                    Button(action: onDismiss) {
                        Text(data.buttonLabel)
                            .font(.buttonLg)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(Color.brand)
                            .clipShape(Capsule())
                            .shadow(color: Color(hex: "#5b21b6"), radius: 0, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 52)
                } else {
                    Button(action: { currentScreen += 1 }) {
                        Text(L10n.Session.continueCta)
                            .font(.buttonLg)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(Color.brand)
                            .clipShape(Capsule())
                            .shadow(color: Color(hex: "#5b21b6"), radius: 0, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 52)
                }
            }
        }
    }
}
