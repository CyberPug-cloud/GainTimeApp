import SwiftUI
import StoreKit

/// A custom view that presents a rating interface with star selection
/// and optional App Store review prompt for high ratings
struct RatingView: View {
    // MARK: - Properties
    
    /// Binding to control the presentation state of the view
    @Binding var isPresented: Bool
    
    /// Callback executed when user submits a rating
    let onSubmitReview: () -> Void
    
    /// Callback executed when the view is dismissed
    let onDismiss: () -> Void
    
    /// Tracks the current rating selected by user (1-5 stars)
    @State private var rating: Int = 0
    
    /// Access to the current color scheme for dark/light mode adaptation
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay that dims the background
            // Tapping this area dismisses the rating view
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismiss()
                }
            
            // Main rating card interface
            VStack(spacing: 20) {
                // Title asking for user's opinion
                Text(LocalizedStringKey("Do you enjoy GainTime?"))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                // Subtitle explaining the action
                Text(LocalizedStringKey("Tap a star to rate it on the App Store"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Interactive star rating selector
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(star <= rating ? .yellow : .gray)
                            .font(.title)
                            .onTapGesture {
                                rating = star
                                submitRating()
                            }
                    }
                }
                .padding(.vertical, 10)
                
                // Dismissal button for users who don't want to rate
                Button {
                    dismiss()
                } label: {
                    Text(LocalizedStringKey("Not now"))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 5)
            }
            // Card styling
            .padding(24)
            .background(
                // Adaptive background color for dark/light mode
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : .white)
                    .shadow(radius: 20)
            )
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles the submission of a rating
    /// For ratings of 4 or 5 stars, shows the native StoreKit review prompt
    /// Executes the onSubmitReview callback and dismisses the view
    private func submitRating() {
        if rating >= 4 {
            // Only show StoreKit review prompt for high ratings (4-5 stars)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
        
        onSubmitReview()
        dismiss()
    }
    
    /// Handles the dismissal of the rating view
    /// Executes the onDismiss callback and updates the presentation state
    private func dismiss() {
        onDismiss()
        isPresented = false
    }
}

// MARK: - Preview Provider

#Preview {
    RatingView(
        isPresented: .constant(true),
        onSubmitReview: {},
        onDismiss: {}
    )
} 