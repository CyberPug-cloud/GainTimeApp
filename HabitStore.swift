import SwiftUI
import CoreData

class HabitStore: ObservableObject {
    static let shared = HabitStore()
    
    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext
    
    @Published private(set) var needsRefresh = false
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.context = persistenceController.container.viewContext
        
        // Check if we need to perform initial migration
        if UserDefaults.standard.bool(forKey: "didMigrateToCoreDara") == false {
            migrateFromLegacyFormat()
        }
    }
    
    // MARK: - Fetch Methods
    
    func fetchHabits() -> [HabitEntity] {
        let request = HabitEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \HabitEntity.creationDate, ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching habits: \(error)")
            return []
        }
    }
    
    func fetchHabitsForDate(_ date: Date) -> [HabitEntity] {
        let request = HabitEntity.fetchRequest()
        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)
        
        // Predicate: creationDate <= selectedDate AND (endDate >= selectedDate OR endDate == nil)
        let creationPredicate = NSPredicate(format: "creationDate <= %@", startOfDate as NSDate)
        let endDatePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "endDate >= %@", startOfDate as NSDate),
            NSPredicate(format: "endDate == nil")
        ])
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            creationPredicate, endDatePredicate
        ])
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \HabitEntity.creationDate, ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching habits for date: \(error)")
            return []
        }
    }
    
    // MARK: - CRUD Operations
    
    func addHabit(title: String, description: String, priority: Priority, frequency: Frequency, goal: Goal) {
        _ = HabitEntity.create(in: context,
                              title: title,
                              description: description,
                              priority: priority,
                              frequency: frequency,
                              goal: goal)
        
        saveContext()
    }
    
    func updateHabit(_ habit: HabitEntity) {
        saveContext()
    }
    
    func deleteHabit(_ habit: HabitEntity) {
        context.delete(habit)
        saveContext()
    }
    
    func toggleCompletion(for habit: HabitEntity, on date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if habit.isCompletedOn(date) {
            // Remove completion
            let completionArray = habit.completions?.allObjects as? [CompletionEntity] ?? []
            for completion in completionArray {
                guard let completionDate = completion.date else { continue }
                if calendar.isDate(completionDate, inSameDayAs: startOfDay) {
                    context.delete(completion)
                }
            }
        } else {
            // Add completion
            let completion = CompletionEntity(context: context)
            completion.id = UUID()
            completion.date = startOfDay
            completion.habit = habit
        }
        
        saveContext()
    }
    
    func completeHabit(_ habit: HabitEntity) {
        habit.endDate = Date()
        saveContext()
    }
    
    private func saveContext() {
        persistenceController.save()
        needsRefresh.toggle()
    }
    
    // MARK: - Migration
    
    private func migrateFromLegacyFormat() {
        // Implementation of migration from UserDefaults
        // Would use the old HabitStore to get existing habits
        // Then call persistenceController.migrateFromUserDefaults(habitStore: oldStore)
        
        UserDefaults.standard.set(true, forKey: "didMigrateToCoreDara")
    }
} 