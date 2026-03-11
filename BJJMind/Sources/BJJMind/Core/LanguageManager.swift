import Foundation

final class LanguageManager: @unchecked Sendable {
    static let shared = LanguageManager()

    private(set) var bundle: Bundle = .main
    private(set) var code: String = "en"

    private init() {
        apply(UserDefaults.standard.string(forKey: "appLanguage") ?? "en")
    }

    func setLanguage(_ newCode: String) {
        UserDefaults.standard.set(newCode, forKey: "appLanguage")
        apply(newCode)
    }

    private func apply(_ newCode: String) {
        code = newCode
        if let path = Bundle.main.path(forResource: newCode, ofType: "lproj"),
           let b = Bundle(path: path) {
            bundle = b
        } else {
            bundle = .main
        }
    }
}
