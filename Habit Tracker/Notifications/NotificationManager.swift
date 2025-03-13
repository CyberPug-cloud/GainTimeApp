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
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { success, _ in
            DispatchQueue.main.async {
                self.isPermissionGranted = success
            }
        }
    }
    
    private func createLocalizedContent(for habit: Habit, isEveningReminder: Bool) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Get the current language code
        _ = selectedLanguage.rawValue
        
        // Create a bundle with the appropriate language
        let bundle = Bundle.main
        
        if isEveningReminder {
            content.title = NSLocalizedString("Habit Reminder", tableName: nil, bundle: bundle, value: "Habit Reminder", comment: "Notification title")
            let formatString = NSLocalizedString("Don't forget to complete: %@", tableName: nil, bundle: bundle, value: "Don't forget to complete: %@", comment: "Evening reminder text")
            content.body = String(format: formatString, habit.title)
        } else {
            let formatString = NSLocalizedString("Time for: %@", tableName: nil, bundle: bundle, value: "Time for: %@", comment: "Regular reminder title")
            content.title = String(format: formatString, habit.title)
            content.body = habit.description
        }
        
        content.sound = .default
        // Add the habit ID as user info to help identify which habit this notification is for
        content.userInfo = ["habitId": habit.id.uuidString]
        return content
    }
    
    func scheduleHabitReminder(for habit: Habit) {
        guard isPermissionGranted else { return }
        
        // First check if the habit is already completed today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let isCompletedToday = habit.completedDates.contains { completedDate in
            calendar.isDate(completedDate, inSameDayAs: today)
        }
        
        // Don't schedule reminders for habits that are already completed today
        if isCompletedToday {
            cancelHabitReminders(for: habit)
            return
        }
        
        // Cancel any existing reminders before scheduling new ones
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
    }
    
    func cancelHabitReminders(for habit: Habit) {
        // Enhanced cancellation: Use multiple approaches to ensure all notifications are canceled
        
        // 1. Cancel by known identifiers
        let identifiers = [
            "\(habit.id)-preferred", 
            "\(habit.id)-evening", 
            "\(habit.id)-missed",
            "missed-habits-reminder",
            "missed-habits-check"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
        
        // 2. Find and cancel all notifications containing this habit's ID in the identifier
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let habitIdentifiers = requests.filter { request in
                // Check if the identifier contains the habit ID
                return request.identifier.contains(habit.id.uuidString)
            }.map { $0.identifier }
            
            if !habitIdentifiers.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: habitIdentifiers)
            }
        }
        
        // 3. Find and cancel all notifications with this habit's ID in userInfo
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let habitIdentifiers = requests.filter { request in
                if let habitIdString = request.content.userInfo["habitId"] as? String,
                   let notificationHabitId = UUID(uuidString: habitIdString),
                   notificationHabitId == habit.id {
                    return true
                }
                return false
            }.map { $0.identifier }
            
            if !habitIdentifiers.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: habitIdentifiers)
            }
        }
        
        // 4. Also check delivered notifications with this habit's ID in userInfo
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let habitIdentifiers = notifications.filter { notification in
                if let habitIdString = notification.request.content.userInfo["habitId"] as? String,
                   let notificationHabitId = UUID(uuidString: habitIdString),
                   notificationHabitId == habit.id {
                    return true
                }
                return false
            }.map { $0.request.identifier }
            
            if !habitIdentifiers.isEmpty {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: habitIdentifiers)
            }
        }
        
        // 5. Check if all habits are completed and cancel the general reminder if needed
        checkAndCancelMissedHabitNotificationsIfAllCompleted()
    }
    
    // MARK: - Missed Habit Notifications
    
    /// Checks if all active habits are completed today
    /// - Returns: True if all active habits are completed today, false otherwise
    func areAllHabitsCompletedToday() -> Bool {
        let habitStore = HabitStore.shared
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get all active habits (without end date)
        let activeHabits = habitStore.habits.filter { habit in
            // Skip completed habits (with end date)
            if habit.endDate != nil {
                return false
            }
            
            // Check if the habit was created before or on today
            let startOfCreationDate = calendar.startOfDay(for: habit.creationDate)
            return startOfCreationDate <= today
        }
        
        // If there are no active habits, consider all completed
        if activeHabits.isEmpty {
            return true
        }
        
        // Check if all active habits are completed today
        let allCompleted = activeHabits.allSatisfy { habit in
            habit.completedDates.contains { completedDate in
                calendar.isDate(completedDate, inSameDayAs: today)
            }
        }
        
        return allCompleted
    }
    
    /// Checks if all habits are completed and cancels missed habit notifications if needed
    func checkAndCancelMissedHabitNotificationsIfAllCompleted() {
        if areAllHabitsCompletedToday() {
            // All habits are completed, cancel missed habit notifications
            cancelMissedHabitNotifications()
        }
    }
    
    /// Schedules a daily notification for uncompleted habits at the specified time
    /// - Parameter time: The time when the notification should be triggered
    func scheduleMissedHabitNotification(at time: Date) {
        guard isPermissionGranted else { return }
        
        // First check if all habits are already completed today
        if areAllHabitsCompletedToday() {
            // All habits are completed, don't schedule the notification
            cancelMissedHabitNotifications()
            return
        }
        
        // Cancel any existing missed habit notifications
        cancelMissedHabitNotifications()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        
        // Get the current language bundle
        let bundle = Bundle.main
        
        content.title = NSLocalizedString("Uncompleted Habits", tableName: nil, bundle: bundle, value: "Uncompleted Habits", comment: "Missed habits notification title")
        content.body = NSLocalizedString("You have habits that haven't been completed today. Tap to view them.", tableName: nil, bundle: bundle, value: "You have habits that haven't been completed today. Tap to view them.", comment: "Missed habits notification body")
        content.sound = .default
        
        // Create time-based trigger
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create and schedule the notification request
        let request = UNNotificationRequest(
            identifier: "missed-habits-reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Cancels all scheduled missed habit notifications
    func cancelMissedHabitNotifications() {
        // Cancel known missed habit notification identifiers
        let knownIdentifiers = ["missed-habits-reminder", "missed-habits-check"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: knownIdentifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: knownIdentifiers)
        
        // Also remove any individual missed habit notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let missedIdentifiers = requests.filter { 
                $0.identifier.contains("-missed") || 
                $0.identifier.contains("missed-habits")
            }.map { $0.identifier }
            
            if !missedIdentifiers.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: missedIdentifiers)
            }
        }
        
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let missedIdentifiers = notifications.filter { 
                $0.request.identifier.contains("-missed") || 
                $0.request.identifier.contains("missed-habits")
            }.map { $0.request.identifier }
            
            if !missedIdentifiers.isEmpty {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: missedIdentifiers)
            }
        }
    }
    
    /// Checks for missed habits and sends a notification if needed
    func checkForMissedHabits() {
        guard isPermissionGranted else { return }
        
        // Get all active habits that haven't been completed today
        let habitStore = HabitStore.shared
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let uncompletedHabits = habitStore.habits.filter { habit in
            // Skip completed habits (with end date)
            if habit.endDate != nil {
                return false
            }
            
            // Check if the habit was created before or on today
            let startOfCreationDate = calendar.startOfDay(for: habit.creationDate)
            if startOfCreationDate > today {
                return false
            }
            
            // Check if the habit is already completed today
            return !habit.isCompletedToday()
        }
        
        // If there are no uncompleted habits, don't send a notification
        if uncompletedHabits.isEmpty {
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        
        // Get the current language code and bundle
        let bundle = Bundle.main
        
        content.title = NSLocalizedString("Uncompleted Habits", tableName: nil, bundle: bundle, value: "Uncompleted Habits", comment: "Missed habits notification title")
        
        // Use the correct format string based on the number of uncompleted habits
        let formatString = NSLocalizedString("You have %d uncompleted habits today", tableName: nil, bundle: bundle, value: "You have %d uncompleted habits today", comment: "Multiple uncompleted habits text")
        content.body = String(format: formatString, uncompletedHabits.count)
        
        content.sound = .default
        
        // Create a time-based trigger for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create and schedule the notification request
        let request = UNNotificationRequest(
            identifier: "missed-habits-check",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Cancels all pending notifications for a habit if it has been completed today
    /// - Parameter habit: The habit to check and cancel notifications for
    func cancelNotificationsIfCompletedToday(for habit: Habit) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if the habit has been completed today
        let isCompletedToday = habit.completedDates.contains { completedDate in
            calendar.isDate(completedDate, inSameDayAs: today)
        }
        
        if isCompletedToday {
            // Use the enhanced cancellation method
            cancelHabitReminders(for: habit)
            
            // Also check for and cancel any delivered notifications
            UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                let habitIdentifiers = notifications.filter { notification in
                    // Check if this notification is for this habit
                    if let habitIdString = notification.request.content.userInfo["habitId"] as? String,
                       let notificationHabitId = UUID(uuidString: habitIdString),
                       notificationHabitId == habit.id {
                        return true
                    }
                    
                    // Also check by identifier pattern
                    return notification.request.identifier.contains(habit.id.uuidString)
                }.map { $0.request.identifier }
                
                if !habitIdentifiers.isEmpty {
                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: habitIdentifiers)
                }
            }
            
            // Also check for and cancel any missed habit notifications that might include this habit
            checkAndCancelMissedHabitNotificationsIfAllCompleted()
        }
    }
    
    /// Reschedules all notifications with the current language
    func rescheduleAllNotifications() {
        // Cancel all existing notifications first
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Get all active habits
        let habitStore = HabitStore.shared
        
        // Reschedule notifications for each habit
        for habit in habitStore.habits {
            // Skip completed habits
            if habit.endDate != nil {
                continue
            }
            
            // Skip habits that are already completed today
            if habit.isCompletedToday() {
                continue
            }
            
            // Only schedule for habits with notifications enabled
            if habit.notificationsEnabled {
                scheduleHabitReminder(for: habit)
            }
        }
        
        // Reschedule missed habit notification if enabled
        if UserDefaults.standard.bool(forKey: "missedHabitNotificationsEnabled") {
            if let timeData = UserDefaults.standard.object(forKey: "missedHabitNotificationTime") as? Date {
                scheduleMissedHabitNotification(at: timeData)
            }
        }
    }
    
    /// Force cancels all notifications for a specific habit, regardless of completion status
    /// - Parameter habit: The habit to cancel notifications for
    func forceCancelAllNotifications(for habit: Habit) {
        cancelHabitReminders(for: habit)
    }
} 