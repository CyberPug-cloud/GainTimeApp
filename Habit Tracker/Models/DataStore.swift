protocol DataStore {
    func saveHabits(_ habits: [Habit])
    func loadHabits() -> [Habit]
    func deleteHabit(_ habit: Habit)
    func updateHabit(_ habit: Habit)
} 