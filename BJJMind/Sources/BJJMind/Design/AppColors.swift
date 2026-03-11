import SwiftUI

extension Color {
    // MARK: - Brand
    static let brand        = Color(hex: "#7c3aed")
    static let brandDark    = Color(hex: "#5b21b6")
    static let brandLight   = Color(hex: "#a78bfa")
    static let brandPale    = Color(hex: "#ede9fe")
    static let brandVeryPale = Color(hex: "#f5f0ff")

    // MARK: - Backgrounds
    static let appBackground  = Color(hex: "#f9f8ff")   // main app screens
    static let screenBg       = Color(hex: "#ffffff")   // content/onboarding screens
    static let cardBg         = Color(hex: "#ffffff")
    static let surfaceBg      = Color(hex: "#f9fafb")

    // MARK: - Text
    static let textPrimary   = Color(hex: "#1a1a2e")
    static let textSecondary = Color(hex: "#6b7280")
    static let textMuted     = Color(hex: "#9ca3af")
    static let textDisabled  = Color(hex: "#d1d5db")

    // MARK: - Borders
    static let borderLight   = Color(hex: "#f3f4f6")
    static let borderMedium  = Color(hex: "#e5e7eb")
    static let borderBrand   = Color(hex: "#ede9fe")

    // MARK: - Semantic
    static let success      = Color(hex: "#22c55e")
    static let successDark  = Color(hex: "#15803d")
    static let successPale  = Color(hex: "#dcfce7")
    static let successLight = Color(hex: "#86efac")

    static let error        = Color(hex: "#ef4444")
    static let errorDark    = Color(hex: "#dc2626")
    static let errorPale    = Color(hex: "#fee2e2")
    static let errorLight   = Color(hex: "#fca5a5")

    // MARK: - Gold (Belt Test)
    static let gold         = Color(hex: "#f59e0b")
    static let goldDark     = Color(hex: "#d97706")
    static let goldPale     = Color(hex: "#fef3c7")
    static let goldVeryPale = Color(hex: "#fffbeb")

    // MARK: - Pills
    static let streakBg     = Color(hex: "#fff7ed")
    static let streakBorder = Color(hex: "#fed7aa")
    static let streakText   = Color(hex: "#ea580c")

    static let xpBg         = Color(hex: "#f5f0ff")
    static let xpBorder     = Color(hex: "#ddd6fe")
    static let xpText       = Color(hex: "#7c3aed")

    static let heartsBg     = Color(hex: "#fff1f2")
    static let heartsBorder = Color(hex: "#fecdd3")
    static let heartsText   = Color(hex: "#e11d48")

    // MARK: - Belt colors
    static func beltColor(_ belt: Belt) -> Color {
        switch belt {
        case .white:  return Color(hex: "#f3f4f6")
        case .blue:   return Color(hex: "#eff6ff")
        case .purple: return Color(hex: "#f5f0ff")
        case .brown:  return Color(hex: "#fff7ed")
        case .black:  return Color(hex: "#f9fafb")
        }
    }

    static func beltAccent(_ belt: Belt) -> Color {
        switch belt {
        case .white:  return Color(hex: "#e5e7eb")
        case .blue:   return Color(hex: "#3b82f6")
        case .purple: return Color(hex: "#7c3aed")
        case .brown:  return Color(hex: "#92400e")
        case .black:  return Color(hex: "#374151")
        }
    }
}

// MARK: - Hex init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8)*17, (int >> 4 & 0xF)*17, (int & 0xF)*17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r)/255,
                  green: Double(g)/255,
                  blue: Double(b)/255,
                  opacity: Double(a)/255)
    }
}
