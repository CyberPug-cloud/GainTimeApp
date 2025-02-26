import SwiftUI

/// Helper class to manage app-wide localization
/// Handles language changes and view updates
class LocalizationHelper: ObservableObject {
    /// Stores selected language persistently using UserDefaults
    @AppStorage("selectedLanguage") var selectedLanguage: Language = .english

    /// Changes the app's language and updates the UI
    /// - Parameter language: The new language to set
    func setLanguage(_ language: Language) {
        // Update stored language preference
        selectedLanguage = language
        
        // Update system-wide language preference
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Reschedule all notifications with new language
        rescheduleAllNotifications()
        
        // Force refresh all views while preserving state
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let rootView = ContentView()
                    .environment(\.locale, Locale(identifier: language.rawValue))
                    .environmentObject(HabitStore.shared) // Inject the shared store
                window.rootViewController = UIHostingController(rootView: rootView)
            }
        }
    }
    
    private func rescheduleAllNotifications() {
        // Use HabitStore instead of reading directly from UserDefaults
        HabitStore.shared.habits.forEach { habit in
            if habit.notificationsEnabled {
                NotificationManager.shared.scheduleHabitReminder(for: habit)
            }
        }
    }
}

/// Extension to simplify string localization in SwiftUI views
extension View {
    /// Returns localized string for given key
    /// - Parameter key: Localization key from Localizable.strings
    func localized(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
} 