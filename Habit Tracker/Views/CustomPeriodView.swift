import SwiftUI

struct CustomPeriodView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var period: Habit.Goal.Period
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Period", selection: $period) {
                        ForEach(Habit.Goal.Period.allCases, id: \.self) { period in
                            Text(period.rawValue)
                                .tag(period)
                        }
                    }
                }
            }
            .navigationTitle("Custom Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 