import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var habitStore: HabitStore
    @AppStorage("displayMode") private var displayMode = DisplayMode.system.rawValue
    @State private var selectedMode = DisplayMode.system.rawValue
    @State private var showingResetAlert = false
    @StateObject private var localizationHelper = LocalizationHelper()
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundGradientView()
                
                List {
                    Section {
                        Menu {
                            ForEach(DisplayMode.allCases, id: \.self) { mode in
                                Button {
                                    selectedMode = mode.rawValue
                                } label: {
                                    HStack {
                                        Text(mode.rawValue)
                                        Spacer()
                                        if selectedMode == mode.rawValue {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("Appearance")
                                Spacer()
                                Text(selectedMode.capitalized)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    } header: {
                        Text("Display")
                    }
                    
                    Section(header: Text("Language")) {
                        Menu {
                            ForEach(Language.allCases) { language in
                                Button(action: {
                                    localizationHelper.setLanguage(language)
                                }) {
                                    HStack {
                                        Text(language.localizedName)
                                        if localizationHelper.selectedLanguage == language {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("Select Language")
                                Spacer()
                                Text(localizationHelper.selectedLanguage.localizedName)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            showingResetAlert = true
                        } label: {
                            Label("Reset Application", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        displayMode = selectedMode
                        dismiss()
                    }
                }
            }
            .alert("Reset Application", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetApplication()
                }
            } message: {
                Text("Are you sure you want to reset the application? This action cannot be undone.")
            }
            .onAppear {
                selectedMode = displayMode
            }
        }
    }
    
    private func resetApplication() {
        habitStore.habits.removeAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        displayMode = DisplayMode.system.rawValue
        selectedMode = DisplayMode.system.rawValue
        
        // Remove goal-related defaults since they're not used
        UserDefaults.standard.removeObject(forKey: "defaultGoalTarget")
        UserDefaults.standard.removeObject(forKey: "defaultGoalPeriod")
    }
}

struct RewardSettingsView: View {
    @AppStorage("defaultSmallReward") private var defaultSmallReward = ""
    @AppStorage("defaultMediumReward") private var defaultMediumReward = ""
    @AppStorage("defaultLargeReward") private var defaultLargeReward = ""
    @AppStorage("defaultGoalReward") private var defaultGoalReward = ""
    @AppStorage("selectedCurrency") private var selectedCurrency = Currency.pln.rawValue
    @State private var showingCurrencyPicker = false
    
    private var currency: Currency {
        Currency(rawValue: selectedCurrency) ?? .pln
    }
    
    var body: some View {
        ZStack {
            BackgroundGradientView()
            
            Form {
                Section {
                    Button {
                        showingCurrencyPicker = true
                    } label: {
                        HStack {
                            Text("Currency")
                            Spacer()
                            Text("\(currency.name) (\(currency.symbol))")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Currency Settings", systemImage: "dollarsign.circle.fill")
                }
                
                Section {
                    TextField("Default small reward", text: $defaultSmallReward)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Label("Daily Reward", systemImage: "star")
                } footer: {
                    Text("Default reward for completing a habit once")
                }
                
                Section {
                    TextField("Default medium reward", text: $defaultMediumReward)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Label("Weekly Reward", systemImage: "star.fill")
                } footer: {
                    Text("Default reward for maintaining a 7-day streak")
                }
                
                Section {
                    TextField("Default large reward", text: $defaultLargeReward)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Label("Monthly Reward", systemImage: "star.circle.fill")
                } footer: {
                    Text("Default reward for maintaining a 30-day streak")
                }
                
                Section {
                    TextField("Default goal reward", text: $defaultGoalReward)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Label("Goal Reward", systemImage: "checkmark.circle.fill")
                } footer: {
                    Text("Special reward for achieving your habit goal")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Default Rewards")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCurrencyPicker) {
            CurrencyPickerView(selectedCurrency: $selectedCurrency)
        }
    }
}

struct GoalSettingsView: View {
    @AppStorage("defaultGoalTarget") private var defaultGoalTarget = 1
    @AppStorage("defaultGoalPeriod") private var defaultGoalPeriod = Habit.Goal.Period.day.rawValue
    
    var body: some View {
        ZStack {
            BackgroundGradientView()
            
            Form {
                Section {
                    Stepper("Target: \(defaultGoalTarget) times", value: $defaultGoalTarget, in: 1...100)
                    
                    Picker("Period", selection: $defaultGoalPeriod) {
                        ForEach(Habit.Goal.Period.allCases, id: \.self) { period in
                            Text(period.rawValue)
                                .tag(period.rawValue)
                        }
                    }
                } header: {
                    Label("Default Goal", systemImage: "target")
                } footer: {
                    Text("Set how many times you want to complete habits by default")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Default Goals")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(HabitStore.shared)
} 