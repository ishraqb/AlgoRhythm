import SwiftUI

/// The main study screen: category filter, the swipe stack, session counters,
/// and explicit master/review buttons that mirror the gestures.
struct StudyView: View {
    @EnvironmentObject private var viewModel: DeckViewModel

    var body: some View {
        VStack(spacing: 16) {
            header
            filterPicker
            CardStackView()
            actionBar
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Theme.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("AlgoRhythm")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(viewModel.sessionMastered) mastered · \(viewModel.sessionReviewed) to review")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Button {
                viewModel.toggleRapidFire()
            } label: {
                Image(systemName: viewModel.rapidFire ? "bolt.fill" : "bolt")
                    .font(.title3)
                    .foregroundStyle(viewModel.rapidFire ? Theme.accent : .white.opacity(0.6))
            }
            .accessibilityLabel("Rapid-fire mode")
        }
        .padding(.horizontal, 20)
    }

    private var filterPicker: some View {
        Picker("Category", selection: $viewModel.categoryFilter) {
            Text("All").tag(Topic.Category?.none)
            ForEach(Topic.Category.allCases) { category in
                Text(category.title).tag(Topic.Category?.some(category))
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
    }

    private var actionBar: some View {
        HStack(spacing: 40) {
            circleButton(system: "arrow.uturn.left", tint: Theme.review) {
                viewModel.handleSwipe(.review)
            }
            circleButton(system: "checkmark", tint: Theme.mastered) {
                viewModel.handleSwipe(.mastered)
            }
        }
        .opacity(viewModel.currentCard == nil ? 0 : 1)
    }

    private func circleButton(system: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 62, height: 62)
                .background(Color.white.opacity(0.06))
                .clipShape(Circle())
                .overlay(Circle().stroke(tint.opacity(0.5), lineWidth: 1.5))
        }
    }
}
