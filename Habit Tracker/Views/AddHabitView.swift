import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var habitStore: HabitStore
    
    @AppStorage("defaultGoalTarget") private var defaultGoalTarget = 1
    @AppStorage("defaultGoalPeriod") private var defaultGoalPeriod = Habit.Goal.Period.day.rawValue
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority = Habit.Priority.medium
    @State private var frequency = Habit.Frequency.daily
    @State private var goal = Habit.Goal.empty
    @State private var showingCustomFrequency = false
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var notificationsEnabled = false
    @State private var notificationTime = Date()
    
    // Simplified frequency picker view
    private var frequencyPicker: some View {
        VStack(alignment: .leading) {
            Text("Frequency")
            
            Picker("Frequency", selection: $frequency) {
                Text("Daily").tag(Habit.Frequency.daily)
                Text("Weekly").tag(Habit.Frequency.weekly)
                Text("Monthly").tag(Habit.Frequency.monthly)
                Text("Custom").tag(frequency.customTag)
            }
            .pickerStyle(.segmented)
            
            if case .custom = frequency {
                Button {
                    showingCustomFrequency = true
                } label: {
                    HStack {
                        Text(frequency.description)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
                .padding(.top, 8)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundGradientView()
                
                Form {
                    Section("Habit Details") {
                        TextField("Title", text: $title)
                        TextField("Description", text: $description)
                    }
                    
                    Section("Settings") {
                        Menu {
                            ForEach(Habit.Priority.allCases, id: \.self) { priority in
                                Button {
                                    self.priority = priority
                                } label: {
                                    HStack {
                                        Image(systemName: "flag.fill")
                                            .foregroundStyle(priority.color)
                                        Text(priority.rawValue.capitalized)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("Priority")
                                Spacer()
                                Image(systemName: "flag.fill")
                                    .foregroundStyle(priority.color)
                                Text(priority.rawValue.capitalized)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        
                        frequencyPicker
                    }
                    
                    Section("Goal") {
                        if goal.period == .day {
                            Text("Target: 1 time daily")
                                .foregroundStyle(.secondary)
                        } else {
                            Stepper("Target: \(goal.target) times", value: $goal.target, in: 1...100)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Period")
                            
                            Picker("Period", selection: $goal.period) {
                                ForEach(Habit.Goal.Period.allCases, id: \.self) { period in
                                    Text(period.rawValue)
                                        .tag(period)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: goal.period) { _, newPeriod in
                                if newPeriod == .day {
                                    goal.target = 1
                                }
                            }
                        }
                    }
                    
                    Section("Duration") {
                        Toggle("Set End Date", isOn: $hasEndDate)
                        
                        if hasEndDate {
                            DatePicker(
                                "End Date",
                                selection: $endDate,
                                in: Calendar.current.date(byAdding: .day, value: 1, to: Date())!...,
                                displayedComponents: .date
                            )
                        }
                    }
                    
                    Section(header: Text("Reminders")) {
                        Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        
                        if notificationsEnabled {
                            DatePicker(
                                "Reminder Time",
                                selection: $notificationTime,
                                displayedComponents: .hourAndMinute
                            )
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let habit = Habit(
                            title: title,
                            description: description,
                            priority: priority,
                            frequency: frequency,
                            rewards: .empty,
                            goal: goal,
                            endDate: hasEndDate ? endDate : nil,
                            creationDate: Date(),
                            reward: 10.0,
                            notificationTime: notificationsEnabled ? notificationTime : nil,
                            notificationsEnabled: notificationsEnabled
                        )
                        habitStore.habits.append(habit)
                        
                        if notificationsEnabled {
                            NotificationManager.shared.scheduleHabitReminder(for: habit)
                        }
                        
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .onAppear {
            goal = Habit.Goal(
                target: defaultGoalTarget,
                period: Habit.Goal.Period(rawValue: defaultGoalPeriod) ?? .day
            )
            if !notificationManager.isPermissionGranted {
                notificationManager.requestPermissions()
            }
        }
        .sheet(isPresented: $showingCustomFrequency) {
            CustomFrequencyView(frequency: $frequency)
        }
    }
}

#Preview {
    AddHabitView()
        .environmentObject(HabitStore.shared)
} 