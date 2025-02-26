import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var isPermissionGranted = false
    
    private var selectedLanguage: Language {
        let rawValue = UserDefaults.standard.string(forKey: "selectedLanguage") ?? Language.english.rawValue
        return Language(rawValue: rawValue) ?? .english
    }
    
    init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { success, _ in
            DispatchQueue.main.async {
                self.isPermissionGranted = success
            }
        }
    }
    
    private func createLocalizedContent(for habit: Habit, isEveningReminder: Bool) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        if isEveningReminder {
            content.title = NSLocalizedString("Habit Reminder", comment: "Notification title")
            content.body = String(format: NSLocalizedString("Don't forget to complete: %@", comment: "Evening reminder text"), habit.title)
        } else {
            content.title = String(format: NSLocalizedString("Time for: %@", comment: "Regular reminder title"), habit.title)
            content.body = habit.description
        }
        
        content.sound = .default
        return content
    }
    
    func scheduleHabitReminder(for habit: Habit) {
        guard isPermissionGranted else { return }
        
        cancelHabitReminders(for: habit)
        
        if let preferredTime = habit.notificationTime {
            let content = createLocalizedContent(for: habit, isEveningReminder: false)
            let components = Calendar.current.dateComponents([.hour, .minute], from: preferredTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "\(habit.id)-preferred",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
        
        // Evening reminder
        var components = DateComponents()
        components.hour = 19
        components.minute = 0
        
        let eveningContent = createLocalizedContent(for: habit, isEveningReminder: true)
        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let eveningRequest = UNNotificationRequest(
            identifier: "\(habit.id)-evening",
            content: eveningContent,
            trigger: eveningTrigger
        )
        
        UNUserNotificationCenter.current().add(eveningRequest)
    }
    
    func cancelHabitReminders(for habit: Habit) {
        let identifiers = ["\(habit.id)-preferred", "\(habit.id)-evening"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
} 