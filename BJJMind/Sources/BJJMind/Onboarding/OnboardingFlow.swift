import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @State private var step: Step = .welcome
    @State private var selectedBelt: Belt = .white
    @State private var skillLevel: SkillLevel = .beginner
    @State private var struggles: [String] = []
    @State private var clubInfo: ClubInfo? = nil

    enum Step {
        case welcome, beltSelect, skillAssessment, struggles, clubInfo, ahaMoment, katIntro
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            switch step {
            case .welcome:
                WelcomeView { step = .beltSelect }

            case .beltSelect:
                BeltSelectView { belt in
                    selectedBelt = belt
                    step = .skillAssessment
                }

            case .skillAssessment:
                SkillAssessmentView { level in
                    skillLevel = level
                    step = .struggles
                }

            case .struggles:
                StrugglesView { selected in
                    struggles = selected
                    step = .clubInfo
                }

            case .clubInfo:
                ClubInfoView { info in
                    clubInfo = info
                    step = .ahaMoment
                }

            case .ahaMoment:
                AhaMomentView { step = .katIntro }

            case .katIntro:
                KatIntroView(belt: selectedBelt) {
                    appState.completeOnboarding(
                        belt: selectedBelt,
                        skillLevel: skillLevel,
                        struggles: struggles,
                        clubInfo: clubInfo
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }
}
