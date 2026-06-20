import SwiftUI

/// Visual language for AlgoRhythm. The look is a warm, editorial "study desk":
/// an espresso backdrop, paper-toned cards, and a honey highlight, paired with
/// serif display type so it reads as crafted rather than a flat utility UI.
enum Theme {
    /// Warm near-black with a hint of brown so it doesn't read as cold OLED black.
    static let background = Color(red: 0.086, green: 0.078, blue: 0.067)

    /// Honey/amber highlight, used sparingly for primary actions and emphasis.
    static let accent = Color(red: 0.882, green: 0.659, blue: 0.286)

    /// Muted sage, the secondary tone for system-design content and chips.
    static let secondary = Color(red: 0.451, green: 0.643, blue: 0.580)

    static let cardCornerRadius: CGFloat = 22

    /// Paper-toned card: warm dark sand fading into espresso.
    static let cardGradient = LinearGradient(
        colors: [
            Color(red: 0.176, green: 0.157, blue: 0.129),
            Color(red: 0.110, green: 0.098, blue: 0.082)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let mastered = Color(red: 0.514, green: 0.694, blue: 0.404)
    static let review = Color(red: 0.851, green: 0.435, blue: 0.318)

    /// Display type. The system serif (New York) gives an editorial voice
    /// without having to bundle a custom font file.
    static func display(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .serif).weight(weight)
    }
}

extension Color {
    /// Tint used for a topic chip, derived from its category.
    static func chip(for category: Topic.Category) -> Color {
        switch category {
        case .algorithms: return Theme.accent
        case .systemDesign: return Theme.secondary
        }
    }
}
