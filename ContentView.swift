import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var habitStore: HabitStore
    
    @State private var selectedDate = Date()
    @State private var showingAddHabit = false
    
    // Store last active date in AppStorage for persistence
    @AppStorage("lastActiveDate") private var lastActiveDate = Date()
    
    // FetchRequest using predicate for current date
    private var habits: [HabitEntity] {
        habitStore.fetchHabitsForDate(selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            // Display habits using the fetched results
            List {
                ForEach(habits, id: \.id) { habit in
                    HabitRowView(habit: habit, selectedDate: selectedDate)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        habitStore.deleteHabit(habits[index])
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Check and update date when app becomes active
                checkAndUpdateDate()
            } else if newPhase == .background {
                // Save current date when app goes to background
                lastActiveDate = Date()
            }
        }
        .onAppear {
            // Check date on initial app launch
            checkAndUpdateDate()
        }
    }
    
    /// Checks if the date has changed since the app was last active
    /// and updates the selected date if needed
    private func checkAndUpdateDate() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDate = calendar.startOfDay(for: lastActiveDate)
        let selectedDay = calendar.startOfDay(for: selectedDate)
        
        // If the date has changed since last active
        if today != lastDate {
            // Only update if user was viewing the last date or an earlier date
            if selectedDay <= lastDate {
                selectedDate = today
            }
            
            // Update the stored last active date
            lastActiveDate = today
        }
    }
}

struct HabitRowView: View {
    let habit: HabitEntity
    let selectedDate: Date
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(habit.title ?? "Untitled")
                    .font(.headline)
                
                if let desc = habit.desc, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            // Completion button
            Button {
                HabitStore.shared.toggleCompletion(for: habit, on: selectedDate)
            } label: {
                Image(systemName: habit.isCompletedOn(selectedDate) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(habit.isCompletedOn(selectedDate) ? .green : .gray)
            }
        }
        .padding(.vertical, 4)
    }
} 