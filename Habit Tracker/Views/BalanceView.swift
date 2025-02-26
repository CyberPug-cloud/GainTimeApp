import SwiftUI

struct BalanceView: View {
    @AppStorage("selectedCurrency") private var selectedCurrency = Currency.pln.rawValue
    @AppStorage("mainPrizeName") private var mainPrizeName = ""
    @AppStorage("mainPrizeCost") private var mainPrizeCost: Double = 0.0
    @AppStorage("accumulatedRewards") private var accumulatedRewards: Double = 0.0
    
    private let calendar = Calendar.current
    private var currency: Currency {
        Currency(rawValue: selectedCurrency) ?? .pln
    }
    
    private var remainingAmount: Double {
        max(0, mainPrizeCost - accumulatedRewards)
    }
    
    private var estimatedCompletionDate: Date? {
        guard let averageDailyReward = calculateAverageDailyReward(),
              averageDailyReward > 0 else { return nil }
        
        let remainingDays = Int(ceil(remainingAmount / averageDailyReward))
        return calendar.date(byAdding: .day, value: remainingDays, to: Date())
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundGradientView()
                
                VStack(spacing: 24) {
                    // Main Prize Section
                    VStack(spacing: 8) {
                        Text(mainPrizeName.isEmpty ? "No Prize Set" : mainPrizeName)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        
                        Text("Target: \(mainPrizeCost, format: .currency(code: currency.rawValue))")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top)
                    
                    // Progress Section
                    VStack(spacing: 16) {
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.white.opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.white)
                                    .frame(width: geometry.size.width * CGFloat(accumulatedRewards / mainPrizeCost))
                            }
                        }
                        .frame(height: 16)
                        .padding(.horizontal)
                        
                        // Balance Details
                        VStack(spacing: 8) {
                            HStack {
                                Text("Accumulated:")
                                Spacer()
                                Text(accumulatedRewards, format: .currency(code: currency.rawValue))
                            }
                            
                            HStack {
                                Text("Remaining:")
                                Spacer()
                                Text(remainingAmount, format: .currency(code: currency.rawValue))
                            }
                        }
                        .foregroundStyle(.white)
                        .font(.headline)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.white.opacity(0.1))
                    )
                    .padding()
                    
                    // Estimated Completion
                    if let completionDate = estimatedCompletionDate {
                        VStack(spacing: 8) {
                            Text("Estimated Completion")
                                .font(.headline)
                            Text(dateFormatter.string(from: completionDate))
                        }
                        .foregroundStyle(.white)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Balance")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func calculateAverageDailyReward() -> Double? {
        // This is a placeholder - you'll need to implement actual calculation
        // based on your reward history data
        return 10.0 // Example: 10 currency units per day
    }
}

#Preview {
    BalanceView()
} 