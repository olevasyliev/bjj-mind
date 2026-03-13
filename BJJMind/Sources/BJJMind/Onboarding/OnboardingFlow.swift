import SwiftUI

// Temporary bridge — will be fully replaced in Task 8
struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @State private var step: Step = .welcome

    enum Step { case welcome, ahaMoment }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            switch step {
            case .welcome:
                WelcomeView { step = .ahaMoment }
            case .ahaMoment:
                AhaMomentView {
                    appState.completeOnboarding(skillLevel: .beginner, clubInfo: nil)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }
}
