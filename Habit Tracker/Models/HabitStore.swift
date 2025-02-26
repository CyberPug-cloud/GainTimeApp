import Foundation

class HabitStore: ObservableObject, DataStore {
    static let shared = HabitStore()
    @Published var habits: [Habit] = [] {
        didSet {
            saveHabits(habits)
        }
    }
    
    private let defaults = UserDefaults.standard
    
    func saveHabits(_ habits: [Habit]) {
        if let encoded = try? JSONEncoder().encode(habits) {
            defaults.set(encoded, forKey: "habits")
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
        habits.removeAll { $0.id == habit.id }
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
        }
    }
} 