import Foundation

/// Loads the study deck. Offline-first: the bundled JSON is always the source
/// of truth for content, so the app works with no network. Remote sync only
/// touches user performance, never the questions themselves.
final class QuestionRepository {
    static let shared = QuestionRepository()

    private(set) var cards: [Card] = []

    init(bundle: Bundle = .main) {
        cards = Self.loadBundledCards(from: bundle)
    }

    func cards(for topic: Topic) -> [Card] {
        cards.filter { $0.topic == topic }
    }

    func cards(in category: Topic.Category) -> [Card] {
        cards.filter { $0.topic.category == category }
    }

    /// Distinct sources present in the deck, for the attribution screen.
    var attributions: [String] {
        Array(Set(cards.map { "\($0.source) — \($0.license)" })).sorted()
    }

    private static func loadBundledCards(from bundle: Bundle) -> [Card] {
        guard let url = bundle.url(forResource: "questions", withExtension: "json") else {
            assertionFailure("questions.json missing from app bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Card].self, from: data)
        } catch {
            // A decode failure here means the bundled data is malformed, which
            // is a build-time mistake rather than something to surface to users.
            assertionFailure("Failed to decode questions.json: \(error)")
            return []
        }
    }
}
