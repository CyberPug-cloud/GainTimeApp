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

    /// Returns native name of the language
    var localizedName: String {
        switch self {
        case .english:
            return "English"
        case .french:
            return "Français"
        case .german:
            return "Deutsch"
        case .polish:
            return "Polski"
        case .spanish:
            return "Español"
        case .italian:
            return "Italiano"
        }
    }
} 