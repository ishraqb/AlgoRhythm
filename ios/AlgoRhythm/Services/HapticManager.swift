import UIKit

/// Thin wrapper over UIKit's feedback generators. Right swipes get a firmer
/// "success" thud, left swipes a lighter tap, so the two outcomes feel distinct
/// without looking at the screen.
final class HapticManager {
    static let shared = HapticManager()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notifier = UINotificationFeedbackGenerator()

    private init() {}

    /// Call when a swipe is about to start so the engine is warm and the first
    /// tap doesn't lag.
    func prepare() {
        lightImpact.prepare()
        rigidImpact.prepare()
    }

    func swiped(_ outcome: SwipeOutcome) {
        switch outcome {
        case .mastered:
            notifier.notificationOccurred(.success)
        case .review:
            lightImpact.impactOccurred()
        }
    }

    /// Quick tick used by rapid-fire mode as cards fly by.
    func tick() {
        rigidImpact.impactOccurred(intensity: 0.6)
    }
}
