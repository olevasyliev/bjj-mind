import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @State private var step: Step = .welcome
    @State private var skillLevel: SkillLevel = .beginner
    @State private var clubInfo: ClubInfo? = nil

    enum Step {
        case welcome, skillAssessment, clubInfo, ahaMoment, katIntro
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            switch step {
            case .welcome:
                WelcomeView { step = .skillAssessment }

            case .skillAssessment:
                SkillAssessmentView { level in
                    skillLevel = level
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
                KatIntroView(skillLevel: skillLevel) {
                    appState.completeOnboarding(skillLevel: skillLevel, clubInfo: clubInfo)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }
}
