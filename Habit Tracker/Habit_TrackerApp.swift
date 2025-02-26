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
    }
}
