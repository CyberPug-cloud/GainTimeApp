import SwiftUI

struct CompletionButton: View {
    @Binding var habit: Habit
    @AppStorage("accumulatedRewards") private var accumulatedRewards: Double = 0.0
    let selectedDate: Date
    
    private func toggleCompletion() {
        let calendar = Calendar.current
        let startOfSelectedDate = calendar.startOfDay(for: selectedDate)
        
        if habit.isCompletedOn(selectedDate) {
            habit.completedDates.remove(selectedDate)
            accumulatedRewards -= habit.reward
        } else {
            habit.completedDates.insert(selectedDate)
            accumulatedRewards += habit.reward
        }
    }
    
    var body: some View {
        Button {
            withAnimation {
                toggleCompletion()
            }
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(Color.teal, lineWidth: 2)
                    .frame(width: 35, height: 35)
                
                if habit.isCompletedOn(selectedDate) {
                    Image(systemName: "hourglass.bottomhalf.filled")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.teal)
                }
            }
        }
    }
} 