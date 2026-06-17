import SwiftUI

/// Per-topic progress: current tier, mastery rate, and counts. Reads the
/// session performance straight off a DeckViewModel-owned model passed in.
struct StatsView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var viewModel: DeckViewModel

    private var performance: UserPerformance { viewModel.performance }

    private var seenTopics: [Topic] {
        Topic.allCases.filter { performance.performance(for: $0).totalSeen > 0 }
    }

    var body: some View {
        NavigationStack {
            Group {
                if seenTopics.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(seenTopics) { topic in
                            row(for: topic)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign out") { auth.signOut() }
                        .tint(Theme.accent)
                }
            }
        }
    }

    private func row(for topic: Topic) -> some View {
        let perf = performance.performance(for: topic)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(topic.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(perf.tier.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(perf.tier.tint)
            }
            ProgressView(value: perf.masteryRate)
                .tint(Theme.accent)
            Text("\(perf.masteredCount) mastered · \(perf.reviewedCount) to review")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.vertical, 6)
        .listRowBackground(Color.white.opacity(0.04))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text("No progress yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Swipe through some cards and your per-topic mastery shows up here.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
