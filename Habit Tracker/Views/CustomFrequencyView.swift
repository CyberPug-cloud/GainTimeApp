import SwiftUI

struct CustomFrequencyView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var frequency: Habit.Frequency
    
    @State private var interval = 1
    @State private var unit = Habit.Frequency.TimeUnit.days
    
    // Helper function to get the correct unit string based on the interval
    private func getUnitString() -> String {
        if interval == 1 {
            // Use singular form
            switch unit {
            case .days:
                return NSLocalizedString("day", comment: "Singular day")
            case .weeks:
                return NSLocalizedString("week", comment: "Singular week")
            }
        } else {
            // Use plural form
            return unit.localizedValue.lowercased()
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundGradientView()
                
                Form {
                    Section {
                        // Use the helper function to get the correct unit string
                        Stepper(NSLocalizedString("Every", comment: "Custom frequency prefix") + " \(interval) " + getUnitString(), value: $interval, in: 1...365)
                        
                        // Use localized string for "Unit"
                        Picker(LocalizedStringKey("Unit"), selection: $unit) {
                            ForEach(Habit.Frequency.TimeUnit.allCases, id: \.self) { unit in
                                // Use localized string for unit names
                                Text(unit.localizedValue)
                                    .tag(unit)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(LocalizedStringKey("Custom Frequency"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("Done")) {
                        frequency = .custom(interval: interval, unit: unit)
                        dismiss()
                    }
                }
            }
        }
    }
} 