import SwiftUI
import Foundation

struct StatisticsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var habitStore: HabitStore
    
    private func habitStats(for habit: Habit) -> (completions: Int, streak: Int, successRate: (completed: Int, total: Int)) {
        let calendar = Calendar.current
        let completions = habit.completedDates.count
        let streak = habit.streak()
        
        let startOfStartDate = calendar.startOfDay(for: habit.creationDate)
        let startOfToday = calendar.startOfDay(for: Date())
        let totalDays = (calendar.dateComponents([.day], from: startOfStartDate, to: startOfToday).day ?? 0) + 1
        
        return (completions, streak, (completions, totalDays))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundGradientView()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(habitStore.habits) { habit in
                            let stats = habitStats(for: habit)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(habit.title)
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                                
                                VStack(spacing: 16) {
                                    HStack {
                                        Text("Total Completions:")
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text("\(stats.completions)")
                                            .foregroundStyle(.white)
                                    }
                                    
                                    HStack {
                                        Text("Longest Streak:")
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text("\(stats.streak) days")
                                            .foregroundStyle(.white)
                                    }
                                    
                                    HStack {
                                        Text("Successful Days:")
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text("\(stats.successRate.completed)/\(stats.successRate.total)")
                                            .foregroundStyle(.white)
                                    }
                                }
                                .font(.headline)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.white.opacity(0.1))
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .scrollIndicators(.visible)
                .scrollIndicatorsFlash(trigger: habitStore.habits.count > 4)
                .tint(.white)
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    StatisticsView()
        .environmentObject(HabitStore.shared)
} 