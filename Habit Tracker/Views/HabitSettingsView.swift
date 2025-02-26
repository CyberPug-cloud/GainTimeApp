import SwiftUI

struct HabitSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var habit: Habit
    @State private var showingCustomFrequency = false
    @State private var showingCustomPeriod = false
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var notificationsEnabled: Bool
    @State private var notificationTime: Date
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    private let frequencies: [Habit.Frequency] = [
        .daily, .weekly, .monthly, .custom(interval: 1, unit: .days)
    ]
    
    init(habit: Binding<Habit>) {
        self._habit = habit
        self._hasEndDate = State(initialValue: habit.wrappedValue.endDate != nil)
        self._endDate = State(initialValue: habit.wrappedValue.endDate ?? Date())
        self._notificationsEnabled = State(initialValue: habit.wrappedValue.notificationsEnabled)
        self._notificationTime = State(initialValue: habit.wrappedValue.notificationTime ?? Date())
    }
    
    // Simplified frequency picker view
    private var frequencyPicker: some View {
        VStack(alignment: .leading) {
            Text("Frequency")
            
            Picker("Frequency", selection: $habit.frequency) {
                Text("Daily").tag(Habit.Frequency.daily)
                Text("Weekly").tag(Habit.Frequency.weekly)
                Text("Monthly").tag(Habit.Frequency.monthly)
                Text("Custom").tag(habit.frequency.customTag)
            }
            .pickerStyle(.segmented)
            
            if case .custom = habit.frequency {
                Button {
                    showingCustomFrequency = true
                } label: {
                    HStack {
                        Text(habit.frequency.description)
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
                        TextField("Title", text: $habit.title)
                        TextField("Description", text: $habit.description)
                        
                        // Add creation date display
                        HStack {
                            Text("Created")
                            Spacer()
                            Text(dateFormatter.string(from: habit.creationDate))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Section("Settings") {
                        Menu {
                            ForEach(Habit.Priority.allCases, id: \.self) { priority in
                                Button {
                                    habit.priority = priority
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
                                    .foregroundStyle(habit.priority.color)
                                Text(habit.priority.rawValue.capitalized)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        
                        frequencyPicker
                    }
                    
                    Section("Goal") {
                        if habit.goal.period == .day {
                            Text("Target: 1 time daily")
                                .foregroundStyle(.secondary)
                        } else {
                            Stepper("Target: \(habit.goal.target) times", value: $habit.goal.target, in: 1...100)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Period")
                            
                            Picker("Period", selection: $habit.goal.period) {
                                ForEach(Habit.Goal.Period.allCases, id: \.self) { period in
                                    Text(period.rawValue)
                                        .tag(period)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: habit.goal.period) { _, newPeriod in
                                if newPeriod == .day {
                                    habit.goal.target = 1
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
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        habit.endDate = hasEndDate ? endDate : nil
                        habit.notificationsEnabled = notificationsEnabled
                        habit.notificationTime = notificationsEnabled ? notificationTime : nil
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCustomFrequency) {
                CustomFrequencyView(frequency: $habit.frequency)
            }
            .sheet(isPresented: $showingCustomPeriod) {
                CustomPeriodView(period: $habit.goal.period)
            }
        }
        .onChange(of: notificationsEnabled) { newValue in
            habit.notificationsEnabled = newValue
            habit.notificationTime = newValue ? notificationTime : nil
            
            if newValue {
                NotificationManager.shared.scheduleHabitReminder(for: habit)
            } else {
                NotificationManager.shared.cancelHabitReminders(for: habit)
            }
        }
        .onChange(of: notificationTime) { newValue in
            if notificationsEnabled {
                habit.notificationTime = newValue
                NotificationManager.shared.scheduleHabitReminder(for: habit)
            }
        }
    }
} 