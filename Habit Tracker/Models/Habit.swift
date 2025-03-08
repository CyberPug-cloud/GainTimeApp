import SwiftUI

struct Habit: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var completedDates: Set<Date>
    var priority: Priority
    var frequency: Frequency
    var goal: Goal
    var endDate: Date?
    var creationDate: Date
    var notificationTime: Date?
    var notificationsEnabled: Bool
    var isActive: Bool {
        guard let endDate = endDate else { return true }
        return Date() <= endDate
    }
    
    enum Priority: String, Codable, CaseIterable {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: .blue
            case .medium: .orange
            case .high: .red
            }
        }
        
        // Add a computed property to get localized value
        var localizedValue: String {
            switch self {
            case .low:
                return NSLocalizedString("low", comment: "Low priority")
            case .medium:
                return NSLocalizedString("medium", comment: "Medium priority")
            case .high:
                return NSLocalizedString("high", comment: "High priority")
            }
        }
    }
    
    enum Frequency: Codable, Equatable, Hashable {
        case daily
        case weekly
        case monthly
        case custom(interval: Int, unit: TimeUnit)
        
        enum TimeUnit: String, Codable, CaseIterable {
            case days = "Days"
            case weeks = "Weeks"
            
            // Add a computed property to get localized raw value
            var localizedValue: String {
                switch self {
                case .days:
                    return NSLocalizedString("Days", comment: "Days time unit")
                case .weeks:
                    return NSLocalizedString("Weeks", comment: "Weeks time unit")
                }
            }
        }
        
        var description: String {
            switch self {
            case .daily: return NSLocalizedString("Daily", comment: "Daily frequency")
            case .weekly: return NSLocalizedString("Weekly", comment: "Weekly frequency")
            case .monthly: return NSLocalizedString("Monthly", comment: "Monthly frequency")
            case .custom(let interval, let unit):
                // Handle pluralization correctly
                let unitString: String
                if interval == 1 {
                    // Use singular form
                    switch unit {
                    case .days:
                        unitString = NSLocalizedString("day", comment: "Singular day")
                    case .weeks:
                        unitString = NSLocalizedString("week", comment: "Singular week")
                    }
                } else {
                    // Use plural form (from the localized value)
                    unitString = unit.localizedValue.lowercased()
                }
                
                let format = NSLocalizedString("Every", comment: "Custom frequency prefix") + " \(interval) " + unitString
                return format
            }
        }
        
        static var allCases: [Frequency] {
            [.daily, .weekly, .monthly, .custom(interval: 1, unit: .days)]
        }
        
        // Add coding keys for custom case
        private enum CodingKeys: String, CodingKey {
            case type, interval, unit
        }
        
        // Custom encoding
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .daily:
                try container.encode("daily", forKey: .type)
            case .weekly:
                try container.encode("weekly", forKey: .type)
            case .monthly:
                try container.encode("monthly", forKey: .type)
            case .custom(let interval, let unit):
                try container.encode("custom", forKey: .type)
                try container.encode(interval, forKey: .interval)
                try container.encode(unit, forKey: .unit)
            }
        }
        
        // Custom decoding
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "daily":
                self = .daily
            case "weekly":
                self = .weekly
            case "monthly":
                self = .monthly
            case "custom":
                let interval = try container.decode(Int.self, forKey: .interval)
                let unit = try container.decode(TimeUnit.self, forKey: .unit)
                self = .custom(interval: interval, unit: unit)
            default:
                self = .daily
            }
        }
        
        // Add hash function for Hashable conformance
        func hash(into hasher: inout Hasher) {
            switch self {
            case .daily:
                hasher.combine(0)
            case .weekly:
                hasher.combine(1)
            case .monthly:
                hasher.combine(2)
            case .custom(let interval, let unit):
                hasher.combine(3)
                hasher.combine(interval)
                hasher.combine(unit)
            }
        }
        
        var customTag: Self {
            if case .custom = self {
                return self
            }
            return .custom(interval: 1, unit: .days)
        }
    }
    
    struct Goal: Codable {
        var target: Int
        var period: Period
        
        static let empty = Goal(target: 1, period: .day)
        
        enum Period: String, Codable, CaseIterable {
            case day = "Daily"
            case week = "Weekly"
            case month = "Monthly"
            
            var days: Int {
                switch self {
                case .day: 1
                case .week: 7
                case .month: 30
                }
            }
        }
    }
    
    init(
        title: String,
        description: String,
        priority: Priority,
        frequency: Frequency = .daily,
        goal: Goal = Goal(target: 1, period: .day),
        endDate: Date? = nil,
        creationDate: Date = Date(),
        notificationTime: Date? = nil,
        notificationsEnabled: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.completedDates = []
        self.priority = priority
        self.frequency = frequency
        self.goal = goal
        self.endDate = endDate
        self.creationDate = creationDate
        self.notificationTime = notificationTime
        self.notificationsEnabled = notificationsEnabled
    }
    
    func isCompletedOn(_ date: Date) -> Bool {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return completedDates.contains { completedDate in
            Calendar.current.isDate(completedDate, inSameDayAs: startOfDay)
        }
    }
    
    func isCompletedToday() -> Bool {
        isCompletedOn(Date())
    }
    
    /// Finds the completion date object for a given day
    /// - Parameter date: The date to check
    /// - Returns: The actual completion date object if found, nil otherwise
    func findCompletionDate(for date: Date) -> Date? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return completedDates.first { completedDate in
            Calendar.current.isDate(completedDate, inSameDayAs: startOfDay)
        }
    }
    
    func streak() -> Int {
        var count = 0
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var checkDate = today
        while completedDates.contains(where: { calendar.isDate($0, inSameDayAs: checkDate) }) {
            count += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? today
        }
        
        return count
    }
} 