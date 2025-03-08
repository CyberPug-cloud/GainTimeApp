import Foundation

class HabitStore: ObservableObject, DataStore {
    static let shared = HabitStore()
    @Published var habits: [Habit] = [] {
        didSet {
            saveHabits(habits)
        }
    }
    
    private let defaults = UserDefaults.standard
    
    init() {
        habits = loadHabits()
        
        // Cancel notifications for habits that are already completed today
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.cancelNotificationsForCompletedHabits()
            
            // Check if all habits are completed and cancel missed habit notifications if needed
            NotificationManager.shared.checkAndCancelMissedHabitNotificationsIfAllCompleted()
        }
    }
    
    func saveHabits(_ habits: [Habit]) {
        if let encoded = try? JSONEncoder().encode(habits) {
            defaults.set(encoded, forKey: "habits")
            defaults.synchronize() // Force immediate save
        }
    }
    
    func loadHabits() -> [Habit] {
        if let data = defaults.data(forKey: "habits"),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            return decoded
        }
        return []
    }
    
    func deleteHabit(_ habit: Habit) {
        // Cancel all notifications for this habit before deleting
        NotificationManager.shared.forceCancelAllNotifications(for: habit)
        
        habits.removeAll { $0.id == habit.id }
        
        // Check if all remaining habits are completed and cancel missed habit notifications if needed
        NotificationManager.shared.checkAndCancelMissedHabitNotificationsIfAllCompleted()
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            // Store the old habit to check if completion status changed
            let oldHabit = habits[index]
            
            // Update the habit
            habits[index] = habit
            
            // Check if the habit was completed today and cancel notifications if needed
            let wasCompletedToday = oldHabit.isCompletedToday()
            let isCompletedToday = habit.isCompletedToday()
            
            if !wasCompletedToday && isCompletedToday {
                // Habit was just completed today, cancel all notifications
                NotificationManager.shared.forceCancelAllNotifications(for: habit)
                
                // Check if this was the last habit to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationManager.shared.checkAndCancelMissedHabitNotificationsIfAllCompleted()
                }
            } else if wasCompletedToday && !isCompletedToday {
                // Habit was uncompleted today, reschedule notifications if enabled
                if habit.notificationsEnabled {
                    NotificationManager.shared.scheduleHabitReminder(for: habit)
                }
            } else {
                // Just check and update notifications as needed
                NotificationManager.shared.cancelNotificationsIfCompletedToday(for: habit)
            }
        }
    }
    
    /// Cancels notifications for all habits that are completed today
    func cancelNotificationsForCompletedHabits() {
        let calendar = Calendar.current
        _ = calendar.startOfDay(for: Date())
        
        for habit in habits {
            // Check if the habit has been completed today using the isCompletedToday method
            if habit.isCompletedToday() {
                // Use the enhanced cancellation method for completed habits
                NotificationManager.shared.forceCancelAllNotifications(for: habit)
            }
        }
        
        // Also cancel any missed habit notifications if all habits are completed
        NotificationManager.shared.checkAndCancelMissedHabitNotificationsIfAllCompleted()
    }
} 