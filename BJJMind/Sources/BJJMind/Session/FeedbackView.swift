import SwiftUI

struct FeedbackView: View {
    let isCorrect: Bool
    let explanation: String
    var coachNote: String? = nil
    var characterComment: String? = nil
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Sheet top handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "#e5e7eb"))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Header row
            HStack(alignment: .top, spacing: 16) {
                // Ghost avatar
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(isCorrect ? Color.successPale : Color.errorPale)
                            .frame(width: 80, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .strokeBorder(isCorrect ? Color.successLight : Color.errorLight, lineWidth: 2.5)
                            )
                        Text(isCorrect ? "🥋" : "😓")
                            .font(.system(size: 40))
                    }

                    // Expression badge
                    Text(isCorrect ? "✓" : "✗")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(isCorrect ? Color.success : Color.error)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 2.5))
                        .offset(x: 4, y: 4)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(isCorrect ? L10n.Session.correct : L10n.Session.notQuite)
                        .font(.feedbackTitle)
                        .foregroundColor(isCorrect ? Color(hex: "#16a34a") : Color(hex: "#dc2626"))

                    // XP badge (only on correct)
                    if isCorrect {
                        Text(L10n.Session.xpEarned(10))
                            .font(.nunito(12, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(Color.brand)
                            .clipShape(Capsule())
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Explanation
            VStack(alignment: .leading, spacing: 12) {
                Text(explanation)
                    .font(.feedbackRule)
                    .foregroundColor(isCorrect ? Color(hex: "#14532d") : Color(hex: "#7f1d1d"))
                    .lineSpacing(3)

                if let note = coachNote, !isCorrect {
                    HStack(alignment: .top, spacing: 8) {
                        Text("👨‍🏫")
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.Coach.name)
                                .font(.nunito(11, weight: .black))
                                .foregroundColor(.brand)
                            Text(note)
                                .font(.nunito(13, weight: .semiBold))
                                .foregroundColor(Color(hex: "#374151"))
                                .lineSpacing(2)
                        }
                    }
                    .padding(12)
                    .background(Color.brandVeryPale)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let comment = characterComment {
                    HStack(alignment: .top, spacing: 8) {
                        Text("👻")
                            .font(.system(size: 16))
                        Text(comment)
                            .font(.nunito(13, weight: .semiBold))
                            .foregroundColor(Color(hex: "#374151"))
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .background(Color(hex: "#f5f3ff"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)

            // Continue button
            Button(action: onContinue) {
                Text(L10n.Session.continueCta)
                    .font(.buttonLg)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(isCorrect ? Color.success : Color.error)
                    .clipShape(Capsule())
                    .shadow(color: isCorrect ? Color.successDark : Color.errorDark, radius: 0, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 44)
        }
        .background(isCorrect ? Color(hex: "#f0fdf4") : Color(hex: "#fff1f2"))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(
                    isCorrect ? Color.successLight : Color.errorLight,
                    lineWidth: 3
                )
                .mask(
                    VStack(spacing: 0) {
                        Color.black.frame(height: 3)
                        Color.clear
                    }
                )
        )
    }
}
