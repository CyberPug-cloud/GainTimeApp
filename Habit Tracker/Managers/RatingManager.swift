import SwiftUI
import StoreKit

/// Manages app rating prompts and tracks conditions for showing them
class RatingManager: ObservableObject {
    static let shared = RatingManager()
    
    // MARK: - Properties
    
    @AppStorage("installationDate") private var installationDate: Date?
    @AppStorage("lastReviewRequest") private var lastReviewRequest: Date?
    @AppStorage("hasShownReview") private var hasShownReview = false
    
    /// Published property to trigger review request
    @Published var shouldRequestReview = false
    
    // MARK: - Initialization
    
    private init() {
        // Set installation date if not set
        if installationDate == nil {
            installationDate = Date()
        }
    }
    
    // MARK: - Public Methods
    
    /// Called when a habit is completed
    /// - Parameter habit: The completed habit
    func trackCompletion(for habit: Habit) {
        // Don't show review if already shown or recently requested
        guard !hasShownReview, canShowReview() else { return }
        
        // Check streak for the habit
        if habit.streak() >= 7 { // One week streak
            requestReview()
            return
        }
        
        // Check installation time
        if let installDate = installationDate,
           Date().timeIntervalSince(installDate) >= 30 * 24 * 60 * 60 { // 30 days
            requestReview()
            return
        }
    }
    
    /// Request a review using RequestReviewAction
    func requestReview() {
        guard canShowReview() else { return }
        
        shouldRequestReview = true
        
        // Update tracking
        lastReviewRequest = Date()
        hasShownReview = true
    }
    
    // MARK: - Private Methods
    
    /// Checks if enough time has passed since the last review request
    private func canShowReview() -> Bool {
        guard let lastRequest = lastReviewRequest else { return true }
        
        // Ensure at least 60 days between requests
        return Date().timeIntervalSince(lastRequest) >= 60 * 24 * 60 * 60
    }
} 