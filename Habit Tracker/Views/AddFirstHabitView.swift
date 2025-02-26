import SwiftUI

struct AddFirstHabitView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var habitStore: HabitStore
    @Binding var selectedDate: Date
    @State private var showingAddHabit = false
    @State private var showingSettings = false
    @State private var showingRewards = false
    @State private var showingStatistics = false
    private let tealColor = Color(red: 0.2, green: 0.7, blue: 0.7)
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom navigation title
            HStack {
                Text("GainTime")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? tealColor : .white)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button {
                        showingStatistics = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .font(.title2)
                            .foregroundStyle(colorScheme == .dark ? tealColor : .white)
                    }
                    
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
            .padding(.top, 16)
            
            // Date picker
            DateSelectorView(selectedDate: $selectedDate)
                .foregroundStyle(colorScheme == .dark ? tealColor : .white)
                .padding(.vertical)
            
            Spacer()
            
            // Center content
            VStack(spacing: 20) {
                Text("Add Your First Habit")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(colorScheme == .dark ? tealColor : .white)
                
                Text("Build Habits, Gain Time")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Button {
                    showingAddHabit = true
                } label: {
                    Text("ACHIEVE MORE !")
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? .black : tealColor)
                        .frame(width: 200, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white)
                                .shadow(
                                    color: Color.black.opacity(0.15),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                        )
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView()
        }
    }
}

#Preview {
    AddFirstHabitView(selectedDate: .constant(Date()))
        .environmentObject(HabitStore.shared)
} 