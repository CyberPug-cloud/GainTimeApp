import SwiftUI
import StoreKit

// Helper extension to provide default notification time
extension SettingsView {
    static func defaultNotificationTime() -> Date {
        let components = DateComponents(hour: 21, minute: 0)
        return Calendar.current.date(from: components) ?? Date()
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.locale) var locale
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var habitStore: HabitStore
    @AppStorage("displayMode") private var displayMode = DisplayMode.system.rawValue
    @AppStorage("hasSubmittedReview") private var hasSubmittedReview = false
    @State private var selectedMode = DisplayMode.system.rawValue
    @State private var showingResetAlert = false
    @StateObject private var localizationHelper = LocalizationHelper()
    
    // Missed habit notification settings
    @AppStorage("missedHabitNotificationsEnabled") private var missedHabitNotificationsEnabled = false
    @AppStorage("missedHabitNotificationTime") private var missedHabitNotificationTime = SettingsView.defaultNotificationTime()
    @State private var showingTimePicker = false
    
    // Time formatter for displaying the selected time
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    // MARK: - View Components
    
    // Display section
    private var displaySection: some View {
        Section {
            Menu {
                ForEach(DisplayMode.allCases, id: \.self) { mode in
                    Button {
                        selectedMode = mode.rawValue
                    } label: {
                        HStack {
                            Text(mode.localizedValue(for: locale))
                            Spacer()
                            if selectedMode == mode.rawValue {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(LocalizedStringKey("Appearance"))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(DisplayMode(rawValue: selectedMode)?.localizedValue(for: locale) ?? "")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .listRowBackground(Color(UIColor.systemBackground).opacity(0.9))
            .listRowSeparator(.hidden)
        } header: {
            Text(LocalizedStringKey("DISPLAY"))
                .foregroundColor(.white)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    // Notification settings section
    private var notificationSection: some View {
        Section {
            Toggle(LocalizedStringKey("Uncompleted Task Reminders"), isOn: $missedHabitNotificationsEnabled)
                .onChange(of: missedHabitNotificationsEnabled) { _, newValue in
                    if newValue {
                        // Request notification permissions if enabled
                        NotificationManager.shared.requestAuthorization()
                        // Schedule missed habit notifications
                        NotificationManager.shared.scheduleMissedHabitNotification(at: missedHabitNotificationTime)
                    } else {
                        // Cancel missed habit notifications
                        NotificationManager.shared.cancelMissedHabitNotifications()
                    }
                }
                .listRowBackground(Color(UIColor.systemBackground).opacity(0.9))
                .listRowSeparator(.hidden)
            
            if missedHabitNotificationsEnabled {
                Button {
                    showingTimePicker = true
                } label: {
                    HStack {
                        Text(LocalizedStringKey("Reminder Time"))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(timeFormatter.string(from: missedHabitNotificationTime))
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(Color(UIColor.systemBackground).opacity(0.9))
                .listRowSeparator(.hidden)
            }
        } header: {
            Text(LocalizedStringKey("NOTIFICATIONS"))
                .foregroundColor(.white)
                .font(.subheadline)
                .fontWeight(.medium)
        } footer: {
            Text(LocalizedStringKey("Get reminded about habits you haven't completed yet"))
                .foregroundColor(.white.opacity(0.8))
                .font(.caption)
        }
    }
    
    // Language section
    private var languageSection: some View {
        Section {
            Menu {
                ForEach(Language.allCases) { language in
                    Button(action: {
                        localizationHelper.setLanguage(language)
                    }) {
                        HStack {
                            Text(language.localizedName)
                            if localizationHelper.selectedLanguage == language {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(LocalizedStringKey("Select Language"))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(localizationHelper.selectedLanguage.localizedName)
                        .foregroundColor(.secondary)
                }
            }
            .listRowBackground(Color(UIColor.systemBackground).opacity(0.9))
            .listRowSeparator(.hidden)
        } header: {
            Text(LocalizedStringKey("LANGUAGE"))
                .foregroundColor(.white)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    // Rating section
    private var ratingSection: some View {
        Section {
            Button {
                if let url = URL(string: "https://apps.apple.com/app/id6742510279?action=write-review") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "star.bubble.fill")
                        .foregroundColor(.blue)
                    Text(LocalizedStringKey("Rate GainTime"))
                        .foregroundColor(.blue)
                }
            }
            .listRowBackground(Color(UIColor.systemBackground).opacity(0.9))
            .listRowSeparator(.hidden)
        } header: {
            Text(LocalizedStringKey("SUPPORT US"))
                .foregroundColor(.white)
                .font(.subheadline)
                .fontWeight(.medium)
        } footer: {
            Text(LocalizedStringKey("Your feedback helps us improve the app"))
                .foregroundColor(.white.opacity(0.8))
                .font(.caption)
        }
    }
    
    // Reset section
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showingResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.red)
                    Text(LocalizedStringKey("Reset Application"))
                        .foregroundColor(.red)
                }
            }
            .listRowBackground(Color(UIColor.systemBackground).opacity(0.9))
            .listRowSeparator(.hidden)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Custom background that adapts to dark mode
                LinearGradient(
                    colors: colorScheme == .dark ? [
                        Color.black, // Pure black for dark mode
                        Color.black  // Pure black for dark mode
                    ] : [
                        Color(red: 0.4, green: 0.9, blue: 0.9), // Light turquoise
                        Color(red: 0.3, green: 0.8, blue: 0.8)  // Darker turquoise
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                List {
                    displaySection
                    notificationSection
                    languageSection
                    ratingSection
                    resetSection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle(LocalizedStringKey("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(colorScheme == .dark ? 
                Color.black : 
                Color(red: 0.4, green: 0.9, blue: 0.9), 
                for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("Done")) {
                        displayMode = selectedMode
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .alert(LocalizedStringKey("Reset Application"), isPresented: $showingResetAlert) {
                Button(LocalizedStringKey("Cancel"), role: .cancel) {}
                Button(LocalizedStringKey("Reset"), role: .destructive) {
                    resetApplication()
                }
            } message: {
                Text(LocalizedStringKey("Are you sure you want to reset the application? This action cannot be undone."))
            }
            .sheet(isPresented: $showingTimePicker) {
                TimePickerView(selectedTime: $missedHabitNotificationTime, onSave: {
                    if missedHabitNotificationsEnabled {
                        // Reschedule notifications with new time
                        NotificationManager.shared.scheduleMissedHabitNotification(at: missedHabitNotificationTime)
                    }
                    showingTimePicker = false
                })
            }
            .onAppear {
                selectedMode = displayMode
            }
        }
    }
    
    private func resetApplication() {
        habitStore.habits.removeAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        displayMode = DisplayMode.system.rawValue
        selectedMode = DisplayMode.system.rawValue
        
        // Reset notification settings
        missedHabitNotificationsEnabled = false
        missedHabitNotificationTime = SettingsView.defaultNotificationTime()
    }
}

// Time picker view for selecting notification time
struct TimePickerView: View {
    @Binding var selectedTime: Date
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Custom background that adapts to dark mode
                LinearGradient(
                    colors: colorScheme == .dark ? [
                        Color.black, // Pure black for dark mode
                        Color.black  // Pure black for dark mode
                    ] : [
                        Color(red: 0.4, green: 0.9, blue: 0.9), // Light turquoise
                        Color(red: 0.3, green: 0.8, blue: 0.8)  // Darker turquoise
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding()
                        .background(Color(UIColor.systemBackground).opacity(0.9))
                        .cornerRadius(16)
                        .padding()
                }
            }
            .navigationTitle(LocalizedStringKey("Select Time"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .toolbarBackground(colorScheme == .dark ? 
                Color.black : 
                Color(red: 0.4, green: 0.9, blue: 0.9), 
                for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("Cancel")) {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("Save")) {
                        onSave()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(HabitStore.shared)
} 