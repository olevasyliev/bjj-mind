import SwiftUI

// MARK: - MiniTheoryView

struct MiniTheoryView: View {
    let data: MiniTheoryData
    let unitTitle: String
    let onComplete: () -> Void

    @State private var currentScreen: Int = 0

    private var screens: [MiniTheoryScreen] { data.screens }
    private var isLastScreen: Bool { currentScreen == screens.count - 1 }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: progress dots + skip button
                topBar

                // Swipeable content area
                TabView(selection: $currentScreen) {
                    ForEach(Array(screens.enumerated()), id: \.offset) { index, screen in
                        ScreenPage(
                            screen: screen,
                            unitTitle: unitTitle
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentScreen)

                // Bottom action bar
                bottomBar
            }
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<screens.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(index == currentScreen ? Color.brand : Color.brandPale)
                        .frame(width: index == currentScreen ? 20 : 8, height: 6)
                        .animation(.easeInOut(duration: 0.25), value: currentScreen)
                }
            }

            Spacer()

            // Skip / close button
            Button(action: onComplete) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Color.cardBg)
                    .overlay(
                        Circle().strokeBorder(Color.borderMedium, lineWidth: 1.5)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 56)
        .padding(.bottom, 16)
    }

    private var bottomBar: some View {
        HStack {
            // Skip link (left)
            Button(action: onComplete) {
                Text("Skip")
                    .font(.nunito(14, weight: .semiBold))
                    .foregroundColor(.textMuted)
            }
            .buttonStyle(.plain)

            Spacer()

            // Next / Done button (right)
            Button(action: advance) {
                Text(isLastScreen ? data.buttonLabel : "Next →")
                    .font(.nunito(16, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .frame(height: 50)
                    .background(Color.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.brandDark, radius: 0, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .padding(.top, 12)
    }

    // MARK: - Actions

    private func advance() {
        if isLastScreen {
            onComplete()
        } else {
            withAnimation(.easeInOut) {
                currentScreen += 1
            }
        }
    }
}

// MARK: - Screen Page

private struct ScreenPage: View {
    let screen: MiniTheoryScreen
    let unitTitle: String

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Unit title (small, muted)
                Text(unitTitle.uppercased())
                    .font(.nunito(11, weight: .black))
                    .foregroundColor(.textMuted)
                    .tracking(1.4)
                    .padding(.bottom, 16)

                // Screen title (large, bold) — optional
                if let title = screen.title {
                    Text(title)
                        .font(.nunito(26, weight: .black))
                        .foregroundColor(.textPrimary)
                        .lineSpacing(2)
                        .padding(.bottom, 20)
                }

                // Body text
                Text(screen.body)
                    .font(.nunito(17, weight: .semiBold))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, screen.coachLine != nil ? 24 : 0)

                // Coach line (smaller, italic, accent) — optional
                if let coachLine = screen.coachLine {
                    HStack(alignment: .top, spacing: 10) {
                        Rectangle()
                            .fill(Color.brand)
                            .frame(width: 3)
                            .cornerRadius(2)

                        Text(coachLine)
                            .font(.system(size: 14, weight: .medium).italic())
                            .foregroundColor(Color(hex: "#6d28d9"))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, screen.show3D ? 24 : 0)
                }

                // 3D Position placeholder (Phase 5)
                if screen.show3D {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "#e2e8f0"))
                            .frame(height: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color(hex: "#cbd5e1"), lineWidth: 1.5)
                            )

                        VStack(spacing: 8) {
                            Image(systemName: "cube")
                                .font(.system(size: 36))
                                .foregroundColor(Color(hex: "#94a3b8"))

                            Text("3D Position")
                                .font(.nunito(13, weight: .bold))
                                .foregroundColor(Color(hex: "#94a3b8"))
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
