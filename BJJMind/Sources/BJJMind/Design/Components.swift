import SwiftUI

// MARK: - Primary Button (pill with 3D shadow)

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var color: Color = .brand
    var shadowColor: Color = .brandDark
    var isLoading: Bool = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.buttonLg)
                        .foregroundColor(.white)
                        .tracking(-0.3)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(color)
            .clipShape(Capsule())
            .shadow(color: shadowColor, radius: 0, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button (outline)

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.buttonMd)
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .overlay(
                    Capsule().strokeBorder(Color.borderMedium, lineWidth: 2.5)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Heart Bar

struct HeartBar: View {
    let current: Int
    let max: Int = UserProfile.maxHearts

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<max, id: \.self) { index in
                Text("❤️")
                    .font(.system(size: 17))
                    .opacity(index < current ? 1.0 : 0.25)
            }
        }
    }
}

// MARK: - Streak Pill

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 5) {
            Text("🔥")
                .font(.system(size: 14))
            Text("\(streak)")
                .font(.labelMd)
                .foregroundColor(.streakText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.streakBg)
        .overlay(Capsule().strokeBorder(Color.streakBorder, lineWidth: 2))
        .clipShape(Capsule())
    }
}

// MARK: - XP Pill

struct XPBadge: View {
    let xp: Int

    var body: some View {
        HStack(spacing: 5) {
            Text("⭐️")
                .font(.system(size: 14))
            Text("\(xp) XP")
                .font(.labelMd)
                .foregroundColor(.xpText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.xpBg)
        .overlay(Capsule().strokeBorder(Color.xpBorder, lineWidth: 2))
        .clipShape(Capsule())
    }
}

// MARK: - Hearts Pill

struct HeartsPill: View {
    let count: Int

    var body: some View {
        HStack(spacing: 5) {
            Text("❤️")
                .font(.system(size: 14))
            Text("\(count)")
                .font(.labelMd)
                .foregroundColor(.heartsText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.heartsBg)
        .overlay(Capsule().strokeBorder(Color.heartsBorder, lineWidth: 2))
        .clipShape(Capsule())
    }
}

// MARK: - Progress Bar

struct AppProgressBar: View {
    let progress: Double
    var height: CGFloat = 10
    var trackColor: Color = Color(hex: "#f3f0ff")
    var fillColor: Color = .brand

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(trackColor)
                Capsule()
                    .fill(fillColor)
                    .frame(width: geo.size.width * max(0, min(1, progress)))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Close Button (rounded square)

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textMuted)
                .frame(width: 32, height: 32)
                .background(Color.surfaceBg)
                .overlay(Circle().strokeBorder(Color.brandPale, lineWidth: 1.5))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step Label (uppercase brand)

struct StepLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.labelSm)
            .foregroundColor(.brand)
            .tracking(1)
    }
}
