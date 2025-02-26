import SwiftUI

struct CalendarView: View {
    let habit: Habit
    let calendar = Calendar.current
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private let daysInWeek = 7
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    @State private var selectedDate = Date()
    
    private var progressInfo: (completed: Int, total: Int) {
        let calendar = Calendar.current
        let startOfPeriod: Date
        let endOfPeriod: Date
        
        switch habit.goal.period {
        case .day:
            startOfPeriod = calendar.startOfDay(for: selectedDate)
            endOfPeriod = calendar.date(byAdding: .day, value: 1, to: startOfPeriod)!
        case .week:
            let weekInterval = calendar.dateInterval(of: .weekOfMonth, for: selectedDate)!
            startOfPeriod = weekInterval.start
            endOfPeriod = weekInterval.end
        case .month:
            let monthInterval = calendar.dateInterval(of: .month, for: selectedDate)!
            startOfPeriod = monthInterval.start
            endOfPeriod = monthInterval.end
        }
        
        let completionsInPeriod = habit.completedDates.filter { date in
            date >= startOfPeriod && date < endOfPeriod
        }.count
        
        return (completed: completionsInPeriod, total: habit.goal.target)
    }
    
    // Cache calculated values
    private var daysInCurrentMonth: [Date?] {
        getDaysInMonth()
    }
    
    private var currentMonthProgress: (completed: Int, total: Int) {
        progressInfo
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundGradientView()
                
                VStack {
                    Text(monthFormatter.string(from: selectedDate))
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(.top)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: daysInWeek)) {
                        ForEach(daysInCurrentMonth.indices, id: \.self) { index in
                            if let date = daysInCurrentMonth[index] {
                                DayCell(date: date, habit: habit, calendar: calendar)
                            } else {
                                Color.clear
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                    )
                    .padding(.horizontal, colorScheme == .dark ? 16 : 20)
                    
                    ProgressView(progress: currentMonthProgress, habit: habit)
                        .padding()
                }
            }
            .navigationTitle("\(habit.title) Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color(red: 0.0, green: 0.5, blue: 1.0))
                }
            }
        }
    }
    
    private func getDaysInMonth() -> [Date?] {
        let interval = calendar.dateInterval(of: .month, for: selectedDate)!
        let firstDay = interval.start
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + daysInWeek) % daysInWeek
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)!.count
        let totalDays = leadingEmptyDays + daysInMonth
        
        return (0..<totalDays).map { index in
            if index < leadingEmptyDays {
                return nil
            } else {
                return calendar.date(byAdding: .day, value: index - leadingEmptyDays, to: firstDay)
            }
        }
    }
}

// Extract day cell to separate component
struct DayCell: View {
    let date: Date
    let habit: Habit
    let calendar: Calendar
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Text("\(calendar.component(.day, from: date))")
                .foregroundStyle(getForegroundColor())
                .frame(width: 35, height: 35)
                .background(
                    Circle()
                        .fill(getBackgroundColor())
                )
        }
        .padding(.vertical, 4)
    }
    
    private func getForegroundColor() -> Color {
        if colorScheme == .dark {
            return habit.isCompletedOn(date) ? .black : .white
        } else {
            return habit.isCompletedOn(date) ? .white : .teal
        }
    }
    
    private func getBackgroundColor() -> Color {
        if colorScheme == .dark {
            return habit.isCompletedOn(date) ? .white : .clear
        } else {
            return habit.isCompletedOn(date) ? .teal : .clear
        }
    }
}

// Extract progress view to separate component
struct ProgressView: View {
    let progress: (completed: Int, total: Int)
    let habit: Habit
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Progress")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text("\(progress.completed)/\(progress.total)")
                .font(.title2)
                .foregroundStyle(.white)
            
            ProgressBar(value: Double(progress.completed) / Double(progress.total))
                .frame(height: 8)
        }
    }
}

struct ProgressBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.white)
                
                Rectangle()
                    .fill(.teal)
                    .frame(width: geometry.size.width * value)
            }
        }
        .clipShape(Capsule())
    }
}

#Preview {
    CalendarView(habit: Habit(
        title: "Exercise",
        description: "Daily workout",
        priority: .high,
        creationDate: Date()
    ))
} 