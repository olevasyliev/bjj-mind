import SwiftUI

// MARK: - Nunito font helpers

extension Font {
    static func nunito(_ size: CGFloat, weight: NunitoWeight = .regular) -> Font {
        .custom(weight.fontName, size: size)
    }
}

enum NunitoWeight {
    case regular, semiBold, bold, extraBold, black

    var fontName: String {
        switch self {
        case .regular:   return "Nunito-Regular"
        case .semiBold:  return "Nunito-SemiBold"
        case .bold:      return "Nunito-Bold"
        case .extraBold: return "Nunito-ExtraBold"
        case .black:     return "Nunito-Black"
        }
    }
}

// MARK: - Semantic type scale (matching HTML prototypes)

extension Font {
    // Titles
    static let appTitle    = Font.nunito(40, weight: .black)    // Welcome screen
    static let screenTitle = Font.nunito(28, weight: .black)    // Home/Summary titles
    static let sectionTitle = Font.nunito(26, weight: .black)   // Onboarding question title

    // Question text
    static let questionLg  = Font.nunito(20, weight: .black)    // Micro-round
    static let questionMd  = Font.nunito(18, weight: .black)    // 4-choice

    // Body
    static let bodyLg      = Font.nunito(16, weight: .regular)  // Tagline
    static let bodyMd      = Font.nunito(15, weight: .semiBold) // Subtitles, descriptions
    static let bodySm      = Font.nunito(14, weight: .semiBold) // Small text

    // Labels
    static let labelXL     = Font.nunito(17, weight: .extraBold) // Belt name
    static let labelLg     = Font.nunito(16, weight: .extraBold) // Unit name
    static let labelMd     = Font.nunito(14, weight: .black)     // Pills, badges
    static let labelSm     = Font.nunito(13, weight: .bold)      // Step label (uppercase)
    static let labelXS     = Font.nunito(11, weight: .extraBold) // Mastery %, tab
    static let labelXXS    = Font.nunito(10, weight: .extraBold) // Tab label

    // Buttons
    static let buttonLg    = Font.nunito(17, weight: .bold)
    static let buttonMd    = Font.nunito(16, weight: .extraBold)

    // Option text
    static let optionText  = Font.nunito(15, weight: .bold)
    static let optionLetter = Font.nunito(15, weight: .black)

    // Feedback
    static let feedbackTitle = Font.nunito(22, weight: .black)
    static let feedbackRule  = Font.nunito(15, weight: .extraBold)
    static let feedbackExp   = Font.nunito(14, weight: .semiBold)
}
