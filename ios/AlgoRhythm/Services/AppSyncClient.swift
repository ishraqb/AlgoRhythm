import Foundation

/// Sends user performance to AppSync. Reads (the deck) stay local/offline; this
/// only pushes progress. The Cognito ID token authorizes the call, and the
/// server derives the owner from that token's `sub` — the client never gets to
/// name which user it's writing for.
final class AppSyncClient: PerformanceSyncing {
    private let endpoint: URL
    private let idToken: String
    private let userId: String

    init(endpoint: URL, idToken: String, userId: String) {
        self.endpoint = endpoint
        self.idToken = idToken
        self.userId = userId
    }

    private static let mutation = """
    mutation UpdatePerformance($records: [PerformanceInput!]!) {
      updateUserPerformanceTrack(records: $records) {
        topicId
      }
    }
    """

    func syncPerformance(_ performance: UserPerformance) {
        let records: [[String: Any]] = performance.topics.compactMap { topic, perf in
            guard perf.totalSeen > 0 else { return nil }
            return [
                "topicId": topic.rawValue,
                "tier": perf.tier.rawValue,
                "mastered": perf.masteredCount,
                "reviewed": perf.reviewedCount,
                "streak": perf.streak
            ]
        }
        guard !records.isEmpty else { return }

        // GraphQL variables keep the user data as data, never interpolated into
        // the query string.
        let payload: [String: Any] = [
            "query": Self.mutation,
            "variables": ["records": records]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(idToken, forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        // Fire-and-forget; a failed sync just means we retry on the next swipe,
        // which keeps the UI responsive offline.
        Task.detached {
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}
