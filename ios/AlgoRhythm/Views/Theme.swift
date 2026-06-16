import SwiftUI

/// Shared visual constants so the dark, indigo-accented look stays consistent
/// across screens.
enum Theme {
    static let accent = Color(red: 0.42, green: 0.34, blue: 0.95)
    static let background = Color(red: 0.05, green: 0.05, blue: 0.08)
    static let cardCornerRadius: CGFloat = 24

    static let cardGradient = LinearGradient(
        colors: [
            Color(red: 0.16, green: 0.16, blue: 0.24),
            Color(red: 0.10, green: 0.10, blue: 0.16)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let mastered = Color.green
    static let review = Color(red: 0.95, green: 0.36, blue: 0.42)
}

extension Color {
    /// Tint used for a topic chip, derived from its category.
    static func chip(for category: Topic.Category) -> Color {
        switch category {
        case .algorithms: return Theme.accent
        case .systemDesign: return .teal
        }
    }
}
