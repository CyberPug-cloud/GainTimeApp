import Foundation
@testable import Habit_Tracker

class MockDataStore: DataStore {
    private var habits: [Habit] = []
    
    func saveHabits(_ habits: [Habit]) {
        self.habits = habits
    }
    
    func loadHabits() -> [Habit] {
        return habits
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
        }
    }
} 