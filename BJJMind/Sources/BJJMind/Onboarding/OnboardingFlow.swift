import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @State private var step: Step = .welcome
    @State private var selectedBelt: Belt = .white
    @State private var selectedTags: Set<String> = []

    enum Step {
        case welcome, beltSelect, problemSelect, ahaMoment
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            switch step {
            case .welcome:
                WelcomeView { step = .beltSelect }
            case .beltSelect:
                BeltSelectView(selectedBelt: $selectedBelt) { step = .problemSelect }
            case .problemSelect:
                ProblemSelectView(selectedTags: $selectedTags) { step = .ahaMoment }
            case .ahaMoment:
                AhaMomentView {
                    appState.completeOnboarding(
                        belt: selectedBelt,
                        weakTags: Array(selectedTags)
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }
}
