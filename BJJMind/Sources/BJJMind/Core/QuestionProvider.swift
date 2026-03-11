import Foundation

enum QuestionProvider {
    static var whitebelt: [Unit] {
        LanguageManager.shared.code == "es" ? Unit.whitebelt_es : Unit.whitebelt_en
    }
}
