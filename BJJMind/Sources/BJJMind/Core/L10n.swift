import Foundation

// MARK: - Localization helper

private func l(_ key: String) -> String {
    NSLocalizedString(key, bundle: LanguageManager.shared.bundle, comment: "")
}

private func lf(_ key: String, _ args: CVarArg...) -> String {
    String(format: NSLocalizedString(key, bundle: LanguageManager.shared.bundle, comment: ""), arguments: args)
}

// MARK: - L10n namespace

enum L10n {

    // MARK: Belt names
    enum Belt {
        static func name(_ belt: BJJMind.Belt) -> String { l("belt.\(belt.rawValue)") }
        static func fullName(_ belt: BJJMind.Belt) -> String { lf("belt.full_name", name(belt)) }
        static func description(_ belt: BJJMind.Belt) -> String { l("belt.\(belt.rawValue).desc") }
    }

    // MARK: Welcome
    enum Welcome {
        static var subtitle: String    { l("welcome.subtitle") }
        static var getStarted: String  { l("welcome.get_started") }
        static var haveAccount: String { l("welcome.have_account") }
    }

    // MARK: Belt Select
    enum BeltSelect {
        static var step: String     { l("belt_select.step") }
        static var title: String    { l("belt_select.title") }
        static var subtitle: String { l("belt_select.subtitle") }
        static var cta: String      { l("belt_select.continue") }
    }

    // MARK: Problem Select
    enum ProblemSelect {
        static var step: String       { l("problem_select.step") }
        static var title: String      { l("problem_select.title") }
        static var subtitle: String   { l("problem_select.subtitle") }
        static var skip: String       { l("problem_select.skip") }
        static func cta(_ n: Int) -> String { lf("problem_select.continue_selected", n) }

        // Problem items: (nameKey, descKey, emoji, tagKey)
        static var items: [(name: String, desc: String, emoji: String, tag: String)] { [
            (l("problem.takedowns.name"),    l("problem.takedowns.desc"),    "🤼", "takedowns"),
            (l("problem.guard_passing.name"),l("problem.guard_passing.desc"),"🛡️", "guard_passing"),
            (l("problem.closed_guard.name"), l("problem.closed_guard.desc"), "🔒", "guard"),
            (l("problem.half_guard.name"),   l("problem.half_guard.desc"),   "🦵", "half_guard"),
            (l("problem.side_control.name"), l("problem.side_control.desc"), "⛓️", "side_control"),
            (l("problem.mount.name"),        l("problem.mount.desc"),        "🏔️", "mount"),
            (l("problem.back_control.name"), l("problem.back_control.desc"), "🎯", "back_control"),
            (l("problem.submissions.name"),  l("problem.submissions.desc"),  "🔴", "submissions"),
            (l("problem.escapes.name"),      l("problem.escapes.desc"),      "🚪", "escapes"),
            (l("problem.leg_locks.name"),    l("problem.leg_locks.desc"),    "🦿", "leg_locks"),
        ] }
    }

    // MARK: Aha Moment
    enum Aha {
        static var title: String    { l("aha.title") }
        static var subtitle: String { l("aha.subtitle") }
        static var cta: String      { l("aha.cta") }
        static var insights: [(emoji: String, text: String)] {[
            ("🗺️", l("aha.insight1")),
            ("❤️", l("aha.insight2")),
            ("🔥", l("aha.insight3")),
            ("🏆", l("aha.insight4")),
        ]}
    }

    // MARK: Home
    enum Home {
        static var currentUnit: String { l("home.current_unit") }
        static var questions: String   { l("home.questions") }
    }

    // MARK: Tabs
    enum Tab {
        static var train: String    { l("tab.train") }
        static var compete: String  { l("tab.compete") }
        static var progress: String { l("tab.progress") }
        static var profile: String  { l("tab.profile") }
    }

    // MARK: Session
    enum Session {
        static var position: String      { l("session.position") }
        static var beltTestChip: String  { l("session.belt_test_chip") }
        static var correct: String       { l("session.correct") }
        static var notQuite: String      { l("session.not_quite") }
        static func xpEarned(_ n: Int) -> String { lf("session.xp_earned", n) }
        static var continueCta: String   { l("session.continue") }
        static var fillBlankHint: String { l("session.fill_blank_hint") }
    }

    // MARK: Summary
    enum Summary {
        static var title: String          { l("summary.title") }
        static var subtitle: String       { l("summary.subtitle") }
        static var accuracy: String       { l("summary.accuracy") }
        static var heartsLeft: String     { l("summary.hearts_left") }
        static var streak: String         { l("summary.streak") }
        static var keepIt: String         { l("summary.keep_it") }
        static var continueCta: String    { l("summary.continue") }
        static var reviewMistakes: String { l("summary.review_mistakes") }
    }

    // MARK: Game Over
    enum GameOver {
        static var title: String   { l("game_over.title") }
        static var message: String { l("game_over.message") }
        static var exit: String    { l("game_over.exit") }
    }

    // MARK: Belt Test
    enum BeltTest {
        static var description: String      { l("belt_test.description") }
        static var rulesHeader: String      { l("belt_test.rules_header") }
        static var topicsHeader: String     { l("belt_test.topics_header") }
        static var startCta: String         { l("belt_test.start") }
        static var retryMessage: String     { l("belt_test.retry_message") }

        static var rules: [(emoji: String, text: String)] {[
            ("❤️", l("belt_test.rule1")),
            ("⏱️", l("belt_test.rule2")),
            ("🚫", l("belt_test.rule3")),
            ("🔄", l("belt_test.rule4")),
            ("🎯", l("belt_test.rule5")),
        ]}

        // Pass
        static var passTitle: String      { l("belt_test.pass_title") }
        static var passSubtitle: String   { l("belt_test.pass_subtitle") }
        static func passAccuracy(_ n: Int) -> String { lf("belt_test.pass_accuracy", n) }
        static var passCta: String        { l("belt_test.pass_continue") }

        // Fail
        static var failTitle: String                  { l("belt_test.fail_title") }
        static var failHeartsMessage: String          { l("belt_test.fail_hearts_message") }
        static var failAccuracyMessage: String        { l("belt_test.fail_accuracy_message") }
        static var failYourScore: String              { l("belt_test.fail_your_score") }
        static var failAccuracyLabel: String          { l("belt_test.fail_accuracy_label") }
        static var failMistakesLeft: String           { l("belt_test.fail_mistakes_left") }
        static var failRequired: String               { l("belt_test.fail_required") }
        static var failCta: String                    { l("belt_test.fail_cta") }
    }

    // MARK: Coach Marco
    enum Coach {
        static var name: String       { l("coach.name") }
        static var tapToStart: String { l("coach.tap_to_start") }
    }

    // MARK: Profile
    enum Profile {
        static var title: String      { l("profile.title") }
        static var totalXP: String    { l("profile.total_xp") }
        static var bestStreak: String { l("profile.best_streak") }
        static var gems: String       { l("profile.gems") }
    }

    // MARK: Progress
    enum Progress {
        static var title: String      { l("progress.title") }
        static var comingSoon: String { l("progress.coming_soon") }
    }

    // MARK: Compete
    enum Compete {
        static var title: String      { l("compete.title") }
        static var comingSoon: String { l("compete.coming_soon") }
    }
}
