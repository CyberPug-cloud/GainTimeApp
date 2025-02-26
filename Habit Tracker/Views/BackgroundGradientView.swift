import SwiftUI

struct BackgroundGradientView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("displayMode") private var displayMode = DisplayMode.system.rawValue
    
    private var effectiveColorScheme: ColorScheme {
        switch DisplayMode(rawValue: displayMode) ?? .system {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return colorScheme
        }
    }
    
    var body: some View {
        Group {
            if effectiveColorScheme == .dark {
                Color(.systemBackground) // iOS default dark background
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.9, blue: 0.9), // Light turquoise
                        Color(red: 0.3, green: 0.8, blue: 0.8)  // Darker turquoise
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
} 