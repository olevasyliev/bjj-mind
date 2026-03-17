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
        static var blockIntroCta: String { l("assessment.block_intro_cta") }
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
        static func message(for belt: BJJMind.Belt) -> String {
            switch belt {
            case .white:  return l("kat_intro.message.white")
            case .blue:   return l("kat_intro.message.blue")
            case .purple: return l("kat_intro.message.purple")
            case .brown:  return l("kat_intro.message.brown")
            case .black:  return l("kat_intro.message.black")
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
        static var currentUnit: String  { l("home.current_unit") }
        static var questions: String    { l("home.questions") }
        static var startSession: String { l("home.start_session") }
        static var strengthLabel: String { l("home.strength_label") }
        static var locked: String       { l("home.locked") }
        static var bossLockedHint: String { l("home.boss_locked_hint") }
        static var bossUnlocked: String { l("home.boss_unlocked") }
    }

    // MARK: Cycle
    enum Cycle {
        static var closedGuard: String      { l("cycle.closed_guard") }
        static var guardPassing: String     { l("cycle.guard_passing") }
        static var sideControlMount: String { l("cycle.side_control_mount") }
        static var backControl: String      { l("cycle.back_control") }
    }

    // MARK: SubTopic
    enum SubTopic {
        static var postureDefense: String      { l("subtopic.posture_defense") }
        static var guardAttacks: String        { l("subtopic.guard_attacks") }
        static var sweeps: String              { l("subtopic.sweeps") }
        static var guardBreaks: String         { l("subtopic.guard_breaks") }
        static var postureInGuard: String      { l("subtopic.posture_in_guard") }
        static var kneelingPass: String        { l("subtopic.kneeling_pass") }
        static var standingPass: String        { l("subtopic.standing_pass") }
        static var openGuardPassing: String    { l("subtopic.open_guard_passing") }
        static var sideControlDefense: String  { l("subtopic.side_control_defense") }
        static var sideControlAttacks: String  { l("subtopic.side_control_attacks") }
        static var mountTransitions: String    { l("subtopic.mount_transitions") }
        static var mountDefense: String        { l("subtopic.mount_defense") }
        static var mountAttacks: String        { l("subtopic.mount_attacks") }
        static var backDefense: String         { l("subtopic.back_defense") }
        static var backControlMaintain: String { l("subtopic.back_control_maintain") }
        static var backSubmissions: String     { l("subtopic.back_submissions") }
        static var backCombinations: String    { l("subtopic.back_combinations") }
    }

    // MARK: Theory Card
    enum TheoryCard {
        static var gotIt: String      { l("theory_card.got_it") }
        static var swipeHint: String  { l("theory_card.swipe_hint") }
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
        static var newTopic: String      { l("session.new_topic") }
        static var characterCommentPreviouslyWrong: String { l("session.character_comment.previously_wrong") }
        static var characterCommentThreeInARow: String     { l("session.character_comment.three_in_a_row") }
        static var characterCommentFirstWrong: String      { l("session.character_comment.first_wrong") }
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
