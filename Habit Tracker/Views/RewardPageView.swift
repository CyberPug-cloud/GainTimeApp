import SwiftUI

struct RewardPageView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedCurrency") private var selectedCurrency = Currency.pln.rawValue
    @AppStorage("mainPrizeName") private var mainPrizeName = ""
    @AppStorage("mainPrizeCost") private var mainPrizeCost: Double = 0.0
    @AppStorage("mainPrizeLink") private var mainPrizeLink = ""
    @AppStorage("mainPrizeImageData") private var mainPrizeImageData: Data?
    @AppStorage("accumulatedRewards") private var accumulatedRewards: Double = 0.0
    
    @State private var showingImagePicker = false
    @State private var showingLinkAlert = false
    @State private var tempLink = ""
    @State private var costString = ""
    
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Prize Settings Section
                        VStack {
                            Section {
                                TextField("Prize Name", text: $mainPrizeName)
                                    .foregroundStyle(.white)
                                HStack {
                                    Text("Cost:")
                                        .foregroundStyle(.white)
                                        .fontWeight(.bold)
                                    TextField("0.00", text: $costString)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(.white)
                                        .onChange(of: costString) { newValue in
                                            if let cost = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                                                mainPrizeCost = cost
                                            }
                                        }
                                }
                            } header: {
                                Label("Main Prize", systemImage: "trophy.fill")
                                    .foregroundStyle(.white)
                                    .fontWeight(.bold)
                            }
                            
                            // Visualization Section
                            VStack(spacing: 12) {
                                HStack {
                                    Button {
                                        showingLinkAlert = true
                                    } label: {
                                        Label("Add Link", systemImage: "link")
                                            .foregroundStyle(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        showingImagePicker = true
                                    } label: {
                                        Label("Add Image", systemImage: "photo")
                                            .foregroundStyle(.white)
                                    }
                                }
                                
                                if !mainPrizeLink.isEmpty {
                                    HStack {
                                        Link(destination: URL(string: mainPrizeLink)!) {
                                            HStack {
                                                Text(mainPrizeLink)
                                                    .lineLimit(1)
                                                Spacer()
                                                Image(systemName: "arrow.up.right.square")
                                            }
                                            .foregroundStyle(.white)
                                        }
                                        
                                        Button {
                                            mainPrizeLink = ""
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                    }
                                }
                                
                                if let imageData = mainPrizeImageData,
                                   let uiImage = UIImage(data: imageData) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .frame(maxWidth: .infinity)
                                        
                                        Button {
                                            mainPrizeImageData = nil
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.white)
                                                .background(Circle().fill(.black.opacity(0.5)))
                                        }
                                        .padding(8)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.white.opacity(0.1))
                        )
                        .padding()
                        
                        // Progress Section
                        VStack(spacing: 16) {
                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.white.opacity(0.2))
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.white)
                                        .frame(width: mainPrizeCost > 0 ? geometry.size.width * CGFloat(accumulatedRewards / mainPrizeCost) : 0)
                                }
                            }
                            .frame(height: 16)
                            .padding(.horizontal)
                            
                            // Balance Details
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Accumulated:")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text(accumulatedRewards, format: .currency(code: currency.rawValue))
                                        .foregroundStyle(.white)
                                }
                                
                                HStack {
                                    Text("Remaining:")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text(remainingAmount, format: .currency(code: currency.rawValue))
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
                        
                        // Estimated Completion
                        if !mainPrizeName.isEmpty && mainPrizeCost > 0 {
                            if let completionDate = estimatedCompletionDate {
                                VStack(spacing: 8) {
                                    Text("Estimated Completion")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text(dateFormatter.string(from: completionDate))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        
                        // Reset Accumulated Amount Button
                        Button(role: .destructive) {
                            resetMainPrizeData()
                        } label: {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                                .foregroundStyle(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.red)
                                )
                        }
                        .padding(.top)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Main Prize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(imageData: $mainPrizeImageData)
            }
            .alert("Add Link", isPresented: $showingLinkAlert) {
                TextField("URL", text: $tempLink)
                Button("Cancel", role: .cancel) {}
                Button("Add") {
                    if let url = URL(string: tempLink), UIApplication.shared.canOpenURL(url) {
                        mainPrizeLink = tempLink
                    }
                    tempLink = ""
                }
            } message: {
                Text("Enter the URL for your prize")
            }
            .onAppear {
                costString = String(format: "%.2f", mainPrizeCost)
            }
        }
    }
    
    private func calculateAverageDailyReward() -> Double? {
        // This is a placeholder - you'll need to implement actual calculation
        // based on your reward history data
        return 10.0 // Example: 10 currency units per day
    }
    
    private func resetMainPrizeData() {
        accumulatedRewards = 0.0
        mainPrizeName = ""
        mainPrizeCost = 0.0
        mainPrizeLink = ""
        mainPrizeImageData = nil
    }
}

struct CurrencyPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCurrency: String
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Button {
                        selectedCurrency = currency.rawValue
                        dismiss()
                    } label: {
                        HStack {
                            Text("\(currency.name)")
                            Spacer()
                            Text("\(currency.symbol)")
                                .foregroundStyle(.secondary)
                            if selectedCurrency == currency.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Image Picker struct to handle image selection
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var imageData: Data?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageData = image.jpegData(compressionQuality: 0.7)
            }
            parent.dismiss()
        }
    }
} 