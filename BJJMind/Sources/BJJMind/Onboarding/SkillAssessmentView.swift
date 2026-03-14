import SwiftUI

struct SkillAssessmentView: View {
    let onComplete: (SkillLevel) -> Void

    private enum Phase {
        case intro
        case q1
        case q2
    }

    @State private var phase: Phase = .intro
    @State private var duration: TrainingDuration = .lessThan6Months
    @State private var frequency: TrainingFrequency = .justStarted

    private var progressStep: Int {
        switch phase {
        case .intro: return 0
        case .q1:    return 1
        case .q2:    return 2
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if phase != .intro {
                AppProgressBar(progress: Double(progressStep) / 2.0)
                    .accessibilityLabel(L10n.Assessment.progress(progressStep))
                    .padding(.horizontal, 24)
                    .padding(.top, 52)
            }

            switch phase {
            case .intro:
                AssessmentIntroBlock(
                    title: L10n.Assessment.blockATitle,
                    subtitle: L10n.Assessment.blockASubtitle,
                    onContinue: { phase = .q1 }
                )

            case .q1:
                ExperienceQuestionView(
                    prompt: L10n.Assessment.q1Prompt,
                    options: L10n.Assessment.q1Options,
                    onSelect: { selectedIdx in
                        duration = TrainingDuration(rawValue: selectedIdx) ?? .lessThan6Months
                        phase = .q2
                    },
                    icon: "calendar"
                )

            case .q2:
                ExperienceQuestionView(
                    prompt: L10n.Assessment.q2Prompt,
                    options: L10n.Assessment.q2Options,
                    onSelect: { selectedIdx in
                        frequency = TrainingFrequency(rawValue: selectedIdx) ?? .justStarted
                        let level = SkillAssessmentEngine.computeSkillLevel(
                            duration: duration, frequency: frequency)
                        onComplete(level)
                    },
                    icon: "flame.fill"
                )
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: progressStep)
    }
}

// MARK: - Sub-views

private struct AssessmentIntroBlock: View {
    let title: String
    let subtitle: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image("marco")
                .resizable()
                .scaledToFit()
                .frame(height: 432)
                .padding(.top, 40)

            Spacer()

            VStack(spacing: 12) {
                Text(title)
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.bodyMd)
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            PrimaryButton(title: L10n.Assessment.blockIntroCta, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
    }
}

private struct ExperienceQuestionView: View {
    let prompt: String
    let options: [String]
    let onSelect: (Int) -> Void
    var icon: String = "calendar"

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.brandVeryPale)
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundColor(.brand)
            }
            .padding(.top, 32)
            .padding(.bottom, 16)

            Text(prompt)
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)
                .tracking(-0.5)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.bottom, 24)

            VStack(spacing: 10) {
                ForEach(options.indices, id: \.self) { idx in
                    Button(action: { onSelect(idx) }) {
                        HStack {
                            Text(options[idx])
                                .font(.labelXL)
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(Color.cardBg)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color(hex: "#f3f4f6"), lineWidth: 2.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }
}

