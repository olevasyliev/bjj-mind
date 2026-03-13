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

    // MARK: Skill Assessment
    enum Assessment {
        static var blockATitle: String    { l("assessment.block_a.intro_title") }
        static var blockASubtitle: String { l("assessment.block_a.intro_subtitle") }
        static var blockBTitle: String    { l("assessment.block_b.intro_title") }
        static var blockBSubtitle: String { l("assessment.block_b.intro_subtitle") }
        static var resultCta: String      { l("assessment.result.cta") }
        static func progress(_ n: Int) -> String { lf("assessment.progress", n) }
        static func result(for level: SkillLevel) -> String {
            switch level {
            case .beginner:     return l("assessment.result.beginner")
            case .intermediate: return l("assessment.result.intermediate")
            case .advanced:     return l("assessment.result.advanced")
            }
        }
        static var q1Prompt: String  { l("assessment.q1.prompt") }
        static var q1Options: [String] { [
            l("assessment.q1.opt1"), l("assessment.q1.opt2"),
            l("assessment.q1.opt3"), l("assessment.q1.opt4")
        ]}
        static var q2Prompt: String  { l("assessment.q2.prompt") }
        static var q2Options: [String] { [
            l("assessment.q2.opt1"), l("assessment.q2.opt2"),
            l("assessment.q2.opt3"), l("assessment.q2.opt4")
        ]}
    }

    // MARK: Club Info
    enum ClubInfoL10n {
        static var title: String              { l("club_info.title") }
        static var subtitle: String           { l("club_info.subtitle") }
        static var countryPlaceholder: String { l("club_info.country_placeholder") }
        static var cityPlaceholder: String    { l("club_info.city_placeholder") }
        static var clubPlaceholder: String    { l("club_info.club_placeholder") }
        static var detectLocation: String     { l("club_info.detect_location") }
        static var skip: String               { l("club_info.skip") }
        static var continueCta: String        { l("club_info.continue") }
    }

    // MARK: Kat Intro
    enum KatIntro {
        static var eyebrow: String    { l("kat_intro.eyebrow") }
        static var name: String       { l("kat_intro.name") }
        static var record: String     { l("kat_intro.record") }
        static var cta: String        { l("kat_intro.cta") }
        static var unlockNote: String { l("kat_intro.unlock_note") }
        static func message(for level: SkillLevel) -> String {
            switch level {
            case .beginner:     return l("kat_intro.message.beginner")
            case .intermediate: return l("kat_intro.message.intermediate")
            case .advanced:     return l("kat_intro.message.advanced")
            }
        }
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
