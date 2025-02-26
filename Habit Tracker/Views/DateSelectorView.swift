import SwiftUI

struct DateSelectorView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.locale) var locale
    @Binding var selectedDate: Date
    @State private var showingCalendar = false
    
    private let calendar = Calendar.current
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        Button {
            showingCalendar = true
        } label: {
            Text(dateFormatter.string(from: selectedDate))
                .font(.title3.weight(.semibold))
                .foregroundStyle(colorScheme == .dark ? Color(red: 0.2, green: 0.7, blue: 0.7) : .white)
        }
        .sheet(isPresented: $showingCalendar) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(.blue)
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingCalendar = false
                        }
                        .foregroundStyle(.blue)
                    }
                }
                .environment(\.colorScheme, .light)
                .preferredColorScheme(.light)
            }
            .presentationDetents([.medium])
            .presentationBackground(Color.white)
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .white
                appearance.titleTextAttributes = [
                    .foregroundColor: UIColor.black,
                    .font: UIFont.boldSystemFont(ofSize: 17)
                ]
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().tintColor = .black
            }
            .onDisappear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.titleTextAttributes = [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.boldSystemFont(ofSize: 17)
                ]
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().tintColor = .white
            }
        }
    }
} 