import Foundation

enum Currency: String, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case jpy = "JPY"
    case gbp = "GBP"
    case cny = "CNY"
    case aud = "AUD"
    case cad = "CAD"
    case chf = "CHF"
    case pln = "PLN"
    case sek = "SEK"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .jpy: return "¥"
        case .gbp: return "£"
        case .cny: return "¥"
        case .aud: return "A$"
        case .cad: return "C$"
        case .chf: return "Fr"
        case .pln: return "zł"
        case .sek: return "kr"
        }
    }
    
    var name: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .jpy: return "Japanese Yen"
        case .gbp: return "British Pound"
        case .cny: return "Chinese Yuan"
        case .aud: return "Australian Dollar"
        case .cad: return "Canadian Dollar"
        case .chf: return "Swiss Franc"
        case .pln: return "Polish Złoty"
        case .sek: return "Swedish Krona"
        }
    }
} 