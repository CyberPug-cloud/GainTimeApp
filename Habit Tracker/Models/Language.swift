import Foundation

/// Represents supported languages in the application
enum Language: String, CaseIterable, Identifiable {
    // Language cases with their ISO 639-1 codes
    case english = "en"
    case french = "fr"
    case german = "de"
    case polish = "pl"
    case spanish = "es"
    case italian = "it"

    // Conformance to Identifiable protocol
    var id: String { rawValue }

    /// Detects and returns the system language
    /// If system language is not supported, returns English
    static func systemLanguage() -> Language {
        // Get the preferred language from system (e.g., "en-US", "fr-FR")
        let preferredLanguage = Bundle.main.preferredLocalizations.first ?? "en"
        // Extract base language code (e.g., "en" from "en-US")
        let baseCode = preferredLanguage.split(separator: "-").first.map(String.init) ?? preferredLanguage
        
        // Find matching supported language or default to English
        return Language.allCases.first { $0.rawValue == baseCode } ?? .english
    }

    /// Returns localized name of the language
    /// Uses NSLocalizedString for translation
    var localizedName: String {
        switch self {
        case .english:
            return NSLocalizedString("English", comment: "English language name")
        case .french:
            return NSLocalizedString("French", comment: "French language name")
        case .german:
            return NSLocalizedString("German", comment: "German language name")
        case .polish:
            return NSLocalizedString("Polish", comment: "Polski language name")
        case .spanish:
            return NSLocalizedString("Spanish", comment: "Spanish language name")
        case .italian:
            return NSLocalizedString("Italian", comment: "Italian language name")
        }
    }
} 