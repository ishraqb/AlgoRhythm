import SwiftUI
import Combine

/// Anything that can persist performance remotely. Kept as a protocol so the
/// deck doesn't depend on the network layer directly and stays testable.
protocol PerformanceSyncing: AnyObject {
    func syncPerformance(_ performance: UserPerformance)
}

/// Drives the study session: holds the current card, records swipe outcomes,
/// asks the matchmaking engine what to show next, and fires feedback.
@MainActor
final class DeckViewModel: ObservableObject {
    @Published private(set) var currentCard: Card?
    @Published private(set) var performance = UserPerformance()
    @Published var rapidFire = false
    @Published private(set) var sessionMastered = 0
    @Published private(set) var sessionReviewed = 0

    /// Topic filter; nil means draw from the whole deck.
    @Published var categoryFilter: Topic.Category? {
        didSet { restart() }
    }

    private let repository: QuestionRepository
    private let engine: SkillMatchmakingEngine
    private let haptics: HapticManager
    private let audio: AudioManager
    private weak var syncer: PerformanceSyncing?

    private var seenIDs: Set<String> = []

    init(
        repository: QuestionRepository = .shared,
        engine: SkillMatchmakingEngine = SkillMatchmakingEngine(),
        haptics: HapticManager = .shared,
        audio: AudioManager = .shared
    ) {
        self.repository = repository
        self.engine = engine
        self.haptics = haptics
        self.audio = audio
        advance()
    }

    func attachSyncer(_ syncer: PerformanceSyncing) {
        self.syncer = syncer
    }

    private var pool: [Card] {
        guard let filter = categoryFilter else { return repository.cards }
        return repository.cards(in: filter)
    }

    func restart() {
        seenIDs.removeAll()
        sessionMastered = 0
        sessionReviewed = 0
        advance()
    }

    func handleSwipe(_ outcome: SwipeOutcome) {
        guard let card = currentCard else { return }

        let topic = card.topic
        performance.record(outcome, for: topic, tier: performance.performance(for: topic).tier)

        // Let the engine decide whether this topic graduates to a new tier.
        let streak = performance.performance(for: topic).streak
        let currentTier = performance.performance(for: topic).tier
        let newTier = engine.adjustedTier(current: currentTier, streak: streak)
        if newTier != currentTier {
            var perf = performance.performance(for: topic)
            perf.tier = newTier
            perf.streak = 0 // reset momentum after a tier change
            performance.topics[topic] = perf
        }

        switch outcome {
        case .mastered: sessionMastered += 1
        case .review: sessionReviewed += 1
        }

        haptics.swiped(outcome)
        if rapidFire { audio.tick() }

        seenIDs.insert(card.id)
        syncer?.syncPerformance(performance)
        advance()
    }

    func toggleRapidFire() {
        rapidFire.toggle()
        if rapidFire { audio.start() } else { audio.stop() }
    }

    private func advance() {
        currentCard = engine.nextCard(from: pool, performance: performance, seenIDs: seenIDs)
        haptics.prepare()
    }
}
