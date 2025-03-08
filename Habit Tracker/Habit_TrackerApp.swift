//
//  Habit_TrackerApp.swift
//  Habit Tracker
//
//  Created by Adam Szydłowski on 19/02/2025.
//

import SwiftUI

@main
struct Habit_TrackerApp: App {
    /// Persistent storage for display mode preference
    @AppStorage("displayMode") private var displayMode = DisplayMode.system.rawValue
    
    /// Persistent storage for language preference
    /// Initialized with system language on first launch
    @AppStorage("selectedLanguage") private var selectedLanguage = Language.systemLanguage()
    
    /// Flag to track first launch of the app
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    
    @StateObject private var habitStore = HabitStore.shared
    
    // Environment object to detect when app becomes active
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Set initial language on first launch only
        if isFirstLaunch {
            selectedLanguage = Language.systemLanguage()
            isFirstLaunch = false
        }
        
        // Configure system-wide language setting
        UserDefaults.standard.set([selectedLanguage.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Navigation bar appearance setup
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 17)
        ]
        
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 34)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(habitStore)
                // Apply color scheme based on display mode
                .preferredColorScheme(DisplayMode(rawValue: displayMode)?.colorScheme)
                // Set locale for localization
                .environment(\.locale, Locale(identifier: selectedLanguage.rawValue))
        }
        // Monitor app lifecycle changes
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // App has become active (foreground)
                // First, cancel all delivered notifications to ensure clean slate
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                
                // Perform a thorough check for completed habits and cancel their notifications
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Force reload habits from storage to ensure we have the latest data
                    let refreshedHabits = HabitStore.shared.loadHabits()
                    
                    // Cancel notifications for completed habits
                    for habit in refreshedHabits {
                        // Use the enhanced cancellation method for completed habits
                        if habit.isCompletedToday() {
                            NotificationManager.shared.forceCancelAllNotifications(for: habit)
                        } else {
                            // For uncompleted habits, just check and cancel if needed
                            NotificationManager.shared.cancelNotificationsIfCompletedToday(for: habit)
                        }
                    }
                    
                    // Check if all habits are completed and cancel missed habit notifications if needed
                    NotificationManager.shared.checkAndCancelMissedHabitNotificationsIfAllCompleted()
                    
                    // After ensuring all completed habits have their notifications canceled,
                    // check for missed habits and send notifications if needed
                    if UserDefaults.standard.bool(forKey: "missedHabitNotificationsEnabled") {
                        // Use a delay to ensure all cancellations have completed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // Only check for missed habits if not all habits are completed
                            if !NotificationManager.shared.areAllHabitsCompletedToday() {
                                NotificationManager.shared.checkForMissedHabits()
                            }
                        }
                    }
                }
            case .background:
                // App has moved to background
                // Schedule the daily missed habits notification if enabled
                if UserDefaults.standard.bool(forKey: "missedHabitNotificationsEnabled") {
                    // First check if all habits are completed
                    if !NotificationManager.shared.areAllHabitsCompletedToday() {
                        if let timeData = UserDefaults.standard.object(forKey: "missedHabitNotificationTime") as? Date {
                            NotificationManager.shared.scheduleMissedHabitNotification(at: timeData)
                        }
                    } else {
                        // All habits are completed, cancel any missed habit notifications
                        NotificationManager.shared.cancelMissedHabitNotifications()
                    }
                }
            case .inactive:
                // App is inactive but still visible (e.g., in app switcher)
                break
            @unknown default:
                break
            }
        }
    }
}
