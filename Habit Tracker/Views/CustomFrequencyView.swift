import SwiftUI

struct CustomFrequencyView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var frequency: Habit.Frequency
    
    @State private var interval = 1
    @State private var unit = Habit.Frequency.TimeUnit.days
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Every \(interval) \(unit.rawValue.lowercased())", value: $interval, in: 1...365)
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(Habit.Frequency.TimeUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue)
                                .tag(unit)
                        }
                    }
                }
            }
            .navigationTitle("Custom Frequency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        frequency = .custom(interval: interval, unit: unit)
                        dismiss()
                    }
                }
            }
        }
    }
} 