import SwiftUI

struct RewardsView: View {
    @Binding var rewards: Habit.Rewards
    
    var body: some View {
        Form {
            Section {
                TextField("Small reward (1 completion)", text: $rewards.small)
                    .textInputAutocapitalization(.sentences)
            } header: {
                Label("Daily Reward", systemImage: "star")
            } footer: {
                Text("Reward yourself for completing the habit once")
            }
            
            Section {
                TextField("Medium reward (7 day streak)", text: $rewards.medium)
                    .textInputAutocapitalization(.sentences)
            } header: {
                Label("Weekly Reward", systemImage: "star.fill")
            } footer: {
                Text("Reward yourself for maintaining a week-long streak")
            }
            
            Section {
                TextField("Large reward (30 day streak)", text: $rewards.large)
                    .textInputAutocapitalization(.sentences)
            } header: {
                Label("Monthly Reward", systemImage: "star.circle.fill")
            } footer: {
                Text("Reward yourself for maintaining a month-long streak")
            }
        }
    }
}

#Preview {
    RewardsView(rewards: .constant(.empty))
} 