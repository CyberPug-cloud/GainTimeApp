import SwiftUI

enum DisplayMode: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    
    var localizedValue: String {
        switch self {
        case .light:
            return NSLocalizedString("Light", comment: "Light display mode")
        case .dark:
            return NSLocalizedString("Dark", comment: "Dark display mode")
        case .system:
            return NSLocalizedString("System", comment: "System display mode")
        }
    }
    
    func localizedValue(for locale: Locale) -> String {
        let key: String
        switch self {
        case .light:
            key = "Light"
        case .dark:
            key = "Dark"
        case .system:
            key = "System"
        }
        
        if let languageCode = locale.language.languageCode?.identifier,
           let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            return NSLocalizedString(key, tableName: "Localizable", bundle: bundle, comment: "\(self) display mode")
        }
        
        return NSLocalizedString(key, tableName: "Localizable", bundle: Bundle.main, comment: "\(self) display mode")
    }
} 