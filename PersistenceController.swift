import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Habit_Tracker")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error loading Core Data stores: \(error)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // Save helper
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    // Data migration from UserDefaults
    func migrateFromUserDefaults(habitStore: HabitStore) {
        let context = container.viewContext
        
        for habit in habitStore.habits {
            let newHabit = HabitEntity(context: context)
            newHabit.id = habit.id
            newHabit.title = habit.title
            newHabit.desc = habit.description
            newHabit.creationDate = habit.creationDate
            newHabit.endDate = habit.endDate
            newHabit.priority = habit.priority.rawValue
            newHabit.frequency = habit.frequency.rawValue
            newHabit.notificationsEnabled = habit.notificationsEnabled
            newHabit.notificationTime = habit.notificationTime
            newHabit.colorHex = habit.color?.toHex()
            newHabit.goalPeriod = habit.goal.period.rawValue
            newHabit.goalTarget = Int16(habit.goal.target)
            
            // Create completion entities
            for date in habit.completedDates {
                let completion = CompletionEntity(context: context)
                completion.id = UUID()
                completion.date = date
                completion.habit = newHabit
            }
        }
        
        save()
    }
}

// Color helper extension
extension Color {
    func toHex() -> String {
        // Convert color to hex string
        // Implementation details omitted for brevity
        return "#FFFFFF" // Placeholder
    }
    
    static func fromHex(_ hex: String) -> Color {
        // Convert hex string to color
        // Implementation details omitted for brevity
        return Color.blue // Placeholder
    }
} 