import SwiftUI

struct CompletionButton: View {
    // MARK: - Properties
    
    @Binding var habit: Habit
    let selectedDate: Date
    
    // App Storage properties for tracking
    @AppStorage("consecutiveCompletionDays") private var consecutiveCompletionDays = 0
    
    // Rating manager instance
    private let ratingManager = RatingManager.shared
    
    // MARK: - Methods
    
    /// Toggles the completion status of a habit for the selected date
    private func toggleCompletion() {
        let calendar = Calendar.current
        let startOfSelectedDate = calendar.startOfDay(for: selectedDate)
        let today = calendar.startOfDay(for: Date())
        let isToday = calendar.isDate(startOfSelectedDate, inSameDayAs: today)
        
        // Prevent completing habits for future dates or past dates
        if startOfSelectedDate > today || startOfSelectedDate < today {
            return
        }
        
        if habit.isCompletedOn(selectedDate) {
            // Use the new helper method to find the exact date to remove
            if let dateToRemove = habit.findCompletionDate(for: selectedDate) {
                habit.completedDates.remove(dateToRemove)
                
                if isToday && habit.notificationsEnabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        NotificationManager.shared.scheduleHabitReminder(for: habit)
                    }
                }
                
                // If uncompleting a habit for today, check if we need to update consecutive days
                if isToday {
                    // Reset consecutive days counter if this was a completed day
                    consecutiveCompletionDays = 0
                }
            }
        } else {
            // Only allow completing habits for today
            if isToday {
                // Use the start of day for consistency
                habit.completedDates.insert(startOfSelectedDate)
                
                // Track completion for rating prompt
                ratingManager.trackCompletion(for: habit)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    NotificationManager.shared.forceCancelAllNotifications(for: habit)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if NotificationManager.shared.areAllHabitsCompletedToday() {
                            NotificationManager.shared.cancelMissedHabitNotifications()
                            
                            // If all habits are completed today, increment consecutive days
                            consecutiveCompletionDays += 1
                        }
                    }
                }
            }
        }
        
        if let index = HabitStore.shared.habits.firstIndex(where: { $0.id == habit.id }) {
            HabitStore.shared.habits[index] = habit
            HabitStore.shared.saveHabits(HabitStore.shared.habits)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Button {
            withAnimation {
                toggleCompletion()
            }
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(Color.teal, lineWidth: 2)
                    .frame(width: 35, height: 35)
                
                if habit.isCompletedOn(selectedDate) {
                    Image(systemName: "hourglass.bottomhalf.filled")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.teal)
                }
            }
        }
        // Disable the button for future dates and past dates
        .disabled(!Calendar.current.isDate(Calendar.current.startOfDay(for: selectedDate), 
                                         inSameDayAs: Calendar.current.startOfDay(for: Date())))
        // Visual indication that future/past dates can't be completed
        .opacity(!Calendar.current.isDate(Calendar.current.startOfDay(for: selectedDate), 
                                        inSameDayAs: Calendar.current.startOfDay(for: Date())) ? 0.5 : 1.0)
        // Add tooltip explaining why the button is disabled
        .help(Calendar.current.startOfDay(for: selectedDate) > Calendar.current.startOfDay(for: Date()) ?
              "Future date: Habits cannot be completed" :
              Calendar.current.startOfDay(for: selectedDate) < Calendar.current.startOfDay(for: Date()) ?
              "Past date: Habits cannot be completed retroactively" : "")
    }
} 