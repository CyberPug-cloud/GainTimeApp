import SwiftUI

struct AddFirstHabitView: View {
    // MARK: - Properties
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var habitStore: HabitStore
    @Binding var selectedDate: Date
    
    // Sheet presentation states
    @State private var activeSheet: ActiveSheet?
    
    // Brand color
    private let brandColor = Color(red: 0.2, green: 0.7, blue: 0.7)
    
    // MARK: - View
    var body: some View {
        VStack(spacing: 0) {
            // Header with navigation
            header
                .padding(.horizontal)
                .padding(.top, 16)
            
            // Date selector
            DateSelectorView(selectedDate: $selectedDate)
                .accentColor(adaptiveColor)
                .padding(.vertical)
            
            Spacer()
            
            // Main content
            mainContent
            
            Spacer()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addHabit: AddHabitView()
            case .settings: SettingsView()
            case .statistics: StatisticsView()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    // Adaptive color based on color scheme
    private var adaptiveColor: Color {
        colorScheme == .dark ? brandColor : .white
    }
    
    // Header view with app title and buttons
    private var header: some View {
        HStack {
            Text("GainTime")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(adaptiveColor)
            
            Spacer()
            
            HStack(spacing: 16) {
                iconButton("chart.bar.fill") { activeSheet = .statistics }
                iconButton("gearshape.fill") { activeSheet = .settings }
            }
        }
    }
    
    // Main content with call to action
    private var mainContent: some View {
        VStack(spacing: 20) {
            Text(LocalizedStringKey("Add Your First Habit"))
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Button {
                activeSheet = .addHabit
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(adaptiveColor)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            }
            
            Text(LocalizedStringKey("Build Habits, Gain Time"))
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            actionButton(LocalizedStringKey("ACHIEVE MORE !")) {
                activeSheet = .addHabit
            }
            .padding(.top, 10)
        }
    }
    
    // MARK: - Helper Methods
    
    // Creates a styled icon button
    private func iconButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundStyle(adaptiveColor)
        }
    }
    
    // Creates a styled action button
    private func actionButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? .black : brandColor)
                .frame(width: 200, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                )
        }
    }
}

// MARK: - Supporting Types

// Enum to manage sheet presentation
enum ActiveSheet: Identifiable {
    case addHabit, settings, statistics
    
    var id: Int {
        switch self {
        case .addHabit: return 0
        case .settings: return 1
        case .statistics: return 2
        }
    }
}

#Preview {
    AddFirstHabitView(selectedDate: .constant(Date()))
        .environmentObject(HabitStore.shared)
} 