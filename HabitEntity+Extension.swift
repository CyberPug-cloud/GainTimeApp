import CoreData
import SwiftUI

extension HabitEntity {
    var habitPriority: Priority {
        get { Priority(rawValue: priority ?? "medium") ?? .medium }
        set { priority = newValue.rawValue }
    }
    
    var habitFrequency: Frequency {
        get { Frequency(rawValue: frequency ?? "daily") ?? .daily }
        set { frequency = newValue.rawValue }
    }
    
    var habitColor: Color? {
        get { colorHex != nil ? Color.fromHex(colorHex!) : nil }
        set { colorHex = newValue?.toHex() }
    }
    
    var habitGoal: Goal {
        get {
            let period = Goal.Period(rawValue: goalPeriod ?? "day") ?? .day
            let target = Int(goalTarget)
            return Goal(period: period, target: target)
        }
        set {
            goalPeriod = newValue.period.rawValue
            goalTarget = Int16(newValue.target)
        }
    }
    
    var completionDates: [Date] {
        let completionArray = completions?.allObjects as? [CompletionEntity] ?? []
        return completionArray.compactMap { $0.date }
    }
    
    func isCompletedOn(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let completionArray = completions?.allObjects as? [CompletionEntity] ?? []
        return completionArray.contains { completion in
            guard let completionDate = completion.date else { return false }
            return calendar.isDate(completionDate, inSameDayAs: startOfDay)
        }
    }
    
    func isCompletedToday() -> Bool {
        isCompletedOn(Date())
    }
    
    func streak() -> Int {
        // Streak calculation logic
        // Implementation details omitted for brevity
        return 0 // Placeholder
    }
    
    // Static helper to create a new habit
    static func create(in context: NSManagedObjectContext,
                      title: String,
                      description: String,
                      priority: Priority,
                      frequency: Frequency,
                      goal: Goal) -> HabitEntity {
        let habit = HabitEntity(context: context)
        habit.id = UUID()
        habit.title = title
        habit.desc = description
        habit.creationDate = Date()
        habit.priority = priority.rawValue
        habit.frequency = frequency.rawValue
        habit.goalPeriod = goal.period.rawValue
        habit.goalTarget = Int16(goal.target)
        
        return habit
    }
} 