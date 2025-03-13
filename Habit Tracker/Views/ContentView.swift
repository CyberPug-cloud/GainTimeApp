//
//  ContentView.swift
//  Habit Tracker
//
//  Created by Adam Szydłowski on 19/02/2025.
//

import SwiftUI
import UIKit
import StoreKit

/// Main view of the application that displays the list of habits
struct ContentView: View {
    // MARK: - Environment & State Properties
    
    /// Access to system color scheme (dark/light mode)
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) private var requestReview
    
    /// Store that manages all habits
    @StateObject private var habitStore = HabitStore.shared
    
    /// Rating manager for handling review requests
    @StateObject private var ratingManager = RatingManager.shared
    
    /// Controls visibility of add habit sheet
    @State private var showingAddHabit = false
    
    /// Controls visibility of settings sheet 
    @State private var showingSettings = false
    
    /// Currently selected habit for calendar view
    @State private var selectedHabit: Habit?
    
    /// Habit being edited
    @State private var habitToEdit: Habit?
    
    /// Currently selected date for filtering habits
    @State private var selectedDate = Date()
    
    /// App-wide display mode setting (system/dark/light)
    @AppStorage("displayMode") private var displayMode = DisplayMode.system.rawValue
    
    /// Last date the app was active (for date change detection)
    @AppStorage("lastActiveDate") private var lastActiveDate = Date()
    
    /// Controls visibility of statistics view
    @State private var showingStatistics = false
    
    /// Habit to be deleted
    @State private var habitToDelete: Habit?
    
    /// Controls visibility of delete confirmation dialog
    @State private var showingDeleteAlert = false
    
    /// Controls visibility of completed habit edit alert
    @State private var showingCompletedHabitAlert = false
    
    /// Tracks scene phase
    @Environment(\.scenePhase) private var scenePhase
    
    /// Consecutive days of habit completion
    @AppStorage("consecutiveCompletionDays") private var consecutiveCompletionDays = 0
    
    // MARK: - Private Properties
    
    /// Calendar instance for date calculations
    private let calendar = Calendar.current
    
    /// Custom teal color used throughout the app
    private let tealColor = Color(red: 0.2, green: 0.7, blue: 0.7)
    
    // MARK: - Initialization
    
    init() {
        _selectedDate = State(initialValue: Date())
    }
    
    // MARK: - Computed Properties
    
    /// Filters habits based on creation and end dates
    var filteredHabits: [Habit] {
        habitStore.habits.filter { habit in
            let startOfSelectedDate = calendar.startOfDay(for: selectedDate)
            let startOfCreationDate = calendar.startOfDay(for: habit.creationDate)
            
            // Check if the selected date is valid for this habit
            if startOfSelectedDate < startOfCreationDate {
                return false // Don't show habits before their creation date
            }
            
            if let endDate = habit.endDate {
                let startOfEndDate = calendar.startOfDay(for: endDate)
                return startOfCreationDate <= startOfSelectedDate && startOfSelectedDate <= startOfEndDate
            }
            
            return true // Show active habits without end date
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                BackgroundGradientView()
                
                VStack {
                    // Show empty state or habit list
                    if filteredHabits.isEmpty {
                        AddFirstHabitView(selectedDate: $selectedDate)
                    } else {
                        VStack(spacing: 0) {
                            // Custom navigation header
                            HStack {
                                Text("GainTime")
                                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                                    .foregroundStyle(colorScheme == .dark ? tealColor : .white)
                                
                                Spacer()
                                
                                // Navigation buttons
                                HStack(spacing: 16) {
                                    // Statistics button
                                    Button {
                                        showingStatistics = true
                                    } label: {
                                        Image(systemName: "chart.bar.fill")
                                            .font(.title2)
                                            .foregroundStyle(colorScheme == .dark ? tealColor : .white)
                                    }
                                    
                                    // Settings button
                                    Button {
                                        showingSettings = true
                                    } label: {
                                        Image(systemName: "gearshape.fill")
                                            .font(.title2)
                                            .foregroundStyle(colorScheme == .dark ? tealColor : .white)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            
                            // Date selector
                            DateSelectorView(selectedDate: $selectedDate)
                                .foregroundStyle(colorScheme == .dark ? tealColor : .white)
                                .padding(.vertical, 4)
                                .onChange(of: selectedDate) { oldValue, newValue in
                                    // Force UI refresh when date changes
                                    if let firstHabit = habitStore.habits.first {
                                        let tempHabit = firstHabit
                                        habitStore.habits[0] = tempHabit
                                    }
                                }
                            
                            // Main content area with list and floating button
                            ZStack(alignment: .bottomTrailing) {
                                // Habit list
                                List {
                                    // Add warning for future dates
                                    if Calendar.current.startOfDay(for: selectedDate) > Calendar.current.startOfDay(for: Date()) {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                            Text("Future date: Habits cannot be completed")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .listRowBackground(Color.clear)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    }
                                    
                                    ForEach($habitStore.habits) { $habit in
                                        // Handle completed habits
                                        if let endDate = habit.endDate {
                                            if calendar.startOfDay(for: habit.creationDate) <= calendar.startOfDay(for: selectedDate) &&
                                                calendar.startOfDay(for: selectedDate) <= calendar.startOfDay(for: endDate) {
                                                HabitRowView(
                                                    habit: $habit,
                                                    selectedDate: selectedDate,
                                                    onEdit: { habit in
                                                        // Prevent editing completed habits
                                                        if habit.endDate != nil {
                                                            showingCompletedHabitAlert = true
                                                        } else {
                                                            habitToEdit = habit
                                                        }
                                                    }
                                                )
                                                // Swipe actions for completed habits
                                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                    Button(role: .destructive) {
                                                        habitToDelete = habit
                                                        showingDeleteAlert = true
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                                    Button {
                                                        selectedHabit = habit
                                                    } label: {
                                                        Label("Calendar", systemImage: "calendar")
                                                    }
                                                    .tint(.blue)
                                                }
                                            }
                                        } else {
                                            // Handle active habits
                                            if calendar.startOfDay(for: habit.creationDate) <= calendar.startOfDay(for: selectedDate) {
                                                HabitRowView(
                                                    habit: $habit,
                                                    selectedDate: selectedDate,
                                                    onEdit: { habit in
                                                        if habit.endDate != nil {
                                                            showingCompletedHabitAlert = true
                                                        } else {
                                                            habitToEdit = habit
                                                        }
                                                    }
                                                )
                                                // Swipe actions for active habits
                                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                    Button(role: .destructive) {
                                                        habitToDelete = habit
                                                        showingDeleteAlert = true
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                                    Button {
                                                        selectedHabit = habit
                                                    } label: {
                                                        Label("Calendar", systemImage: "calendar")
                                                    }
                                                    .tint(.blue)
                                                }
                                            }
                                        }
                                    }
                                }
                                .listStyle(.insetGrouped)
                                .scrollContentBackground(.hidden)
                                
                                // Add habit button (floating)
                                Button {
                                    showingAddHabit = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.2, green: 0.7, blue: 0.7))
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(colorScheme == .dark ? tealColor : .white)
                                                .shadow(
                                                    color: Color.black.opacity(0.15),
                                                    radius: 8,
                                                    x: 0,
                                                    y: 4
                                                )
                                        )
                                }
                                .padding([.trailing, .bottom], 16)
                            }
                            .frame(maxHeight: .infinity)
                        }
                    }
                }
                .navigationBarHidden(true)
            }
            // MARK: - Sheet Presentations
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(item: $selectedHabit) { habit in
                CalendarView(habit: habit)
            }
            .sheet(item: $habitToEdit) { habit in
                if let index = habitStore.habits.firstIndex(where: { $0.id == habit.id }) {
                    HabitSettingsView(habit: $habitStore.habits[index])
                }
            }
            .sheet(isPresented: $showingStatistics) {
                StatisticsView()
            }
            .onChange(of: showingSettings) { oldValue, newValue in
                // Force refresh when returning from settings
                if oldValue == true && newValue == false {
                    // Trigger a refresh of the habit store
                    habitStore.objectWillChange.send()
                }
            }
            
            // MARK: - Alerts and Dialogs
            .confirmationDialog(
                "What would you like to do?",
                isPresented: $showingDeleteAlert,
                presenting: habitToDelete
            ) { habit in
                Button("Mark as Completed", role: .none) {
                    if let index = habitStore.habits.firstIndex(where: { $0.id == habit.id }) {
                        habitStore.habits[index].endDate = Date()
                    }
                }
                
                Button("Delete Permanently", role: .destructive) {
                    habitStore.deleteHabit(habit)
                    NotificationManager.shared.cancelHabitReminders(for: habit)
                }
                
                Button("Cancel", role: .cancel) {}
            } message: { habit in
                Text("Mark as completed will hide the habit but keep its statistics.\nDelete will remove all data permanently.")
            }
            .alert("Cannot Edit Completed Habit", isPresented: $showingCompletedHabitAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Editing of completed habits is not possible.")
            }
            .preferredColorScheme(DisplayMode(rawValue: displayMode) == .system ? nil :
                                    DisplayMode(rawValue: displayMode) == .dark ? .dark : .light)
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
        }
        .environmentObject(habitStore)
        .onChange(of: ratingManager.shouldRequestReview) { _, shouldRequest in
            if shouldRequest {
                requestReview()
                ratingManager.shouldRequestReview = false
            }
        }
    }
    
    // MARK: - Scene Phase Changes
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        if newPhase == .active {
            // Check if we've crossed to a new day since last active
            checkAndUpdateDate()
            
            // Check for completed habits when app becomes active
            checkCompletedHabits()
            
            // Check if we should show rating prompt based on installation date
            RatingManager.shared.trackCompletion(for: habitStore.habits.first ?? Habit(title: "", description: "", priority: .medium, frequency: .daily, goal: .empty))
        } else if newPhase == .background || newPhase == .inactive {
            // Update the last active date when going to background
            lastActiveDate = Date()
        }
    }
    
    /// Checks if the date has changed since the app was last active and updates the view
    private func checkAndUpdateDate() {
        let today = calendar.startOfDay(for: Date())
        let lastDate = calendar.startOfDay(for: lastActiveDate)
        
        // If the date has changed and the user was viewing the previous date, update to today
        if today != lastDate {
            let currentlyViewingDate = calendar.startOfDay(for: selectedDate)
            
            // Only update if user was viewing the last active date (yesterday) or a date in the past
            if currentlyViewingDate <= lastDate {
                selectedDate = today
            }
            
            // Update the last active date to today
            lastActiveDate = today
        }
    }
    
    // MARK: - Habit Completion Methods
    
    /// Checks for completed habits when app becomes active
    /// Updates the consecutive completion days counter
    private func checkCompletedHabits() {
        if habitStore.habits.isEmpty {
            return
        }
        
        // Check if all habits for today are completed
        let allHabitsForToday = filteredHabits
        let allCompleted = !allHabitsForToday.isEmpty && allHabitsForToday.allSatisfy { $0.isCompletedToday() }
        
        // Update consecutive completion days counter
        if allCompleted {
            consecutiveCompletionDays += 1
        } else {
            // Reset counter if not all habits are completed
            consecutiveCompletionDays = 0
        }
    }
}

// Extract row view to separate component
struct HabitRowView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var habit: Habit
    let selectedDate: Date
    var onEdit: (Habit) -> Void
    
    private let tealColor = Color(red: 0.2, green: 0.7, blue: 0.7)
    
    private var showGiftIcon: Bool {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: selectedDate)!
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        
        return !habit.completedDates.contains { completedDate in
            calendar.isDate(completedDate, equalTo: startOfYesterday, toGranularity: .day)
        }
    }
    
    private var isFutureDate: Bool {
        Calendar.current.startOfDay(for: selectedDate) > Calendar.current.startOfDay(for: Date())
    }
    
    private func calculateProgress(for habit: Habit, on date: Date) -> Double {
        let calendar = Calendar.current
        let startOfPeriod: Date
        let endOfPeriod: Date
        
        switch habit.goal.period {
        case .day:
            startOfPeriod = calendar.startOfDay(for: date)
            endOfPeriod = calendar.date(byAdding: .day, value: 1, to: startOfPeriod)!
        case .week:
            let weekInterval = calendar.dateInterval(of: .weekOfMonth, for: date)!
            startOfPeriod = weekInterval.start
            endOfPeriod = weekInterval.end
        case .month:
            let monthInterval = calendar.dateInterval(of: .month, for: date)!
            startOfPeriod = monthInterval.start
            endOfPeriod = monthInterval.end
        }
        
        let completionsInPeriod = habit.completedDates.filter { completedDate in
            completedDate >= startOfPeriod && completedDate < endOfPeriod
        }.count
        
        return Double(completionsInPeriod) / Double(habit.goal.target)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Text(habit.title)
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? tealColor : Color.teal)
                    Image(systemName: "hourglass")
                        .foregroundStyle(habit.priority.color)
                        .font(.caption)
                    
                    if isFutureDate {
                        Image(systemName: "clock")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                
                if !habit.description.isEmpty {
                    Text(habit.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Text("Streak: \(habit.streak()) days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(calculateProgress(for: habit, on: selectedDate) * 100))%")
                        .font(.caption)
                        .foregroundStyle(Color.teal)
                }
            }
            .onTapGesture {
                onEdit(habit)
            }
            
            CompletionButton(habit: $habit, selectedDate: selectedDate)
        }
        .listRowBackground(colorScheme == .dark ? Color(.secondarySystemBackground) : .white)
        .opacity(isFutureDate ? 0.7 : 1.0)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
}

#Preview {
    ContentView()
}
