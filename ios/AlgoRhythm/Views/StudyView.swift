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
        HStack(spacing: 10) {
            BrandMark(size: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text("AlgoRhythm")
                    .font(Theme.display(.title, weight: .bold))
                    .foregroundStyle(.white)
                Text("\(viewModel.sessionMastered) mastered · \(viewModel.sessionReviewed) to review")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            rapidFireToggle
        }
        .padding(.horizontal, 20)
    }

    private var rapidFireToggle: some View {
        Button {
            viewModel.toggleRapidFire()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: viewModel.rapidFire ? "bolt.fill" : "bolt")
                Text("Rapid")
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(viewModel.rapidFire ? Theme.background : Theme.accent)
            .background(viewModel.rapidFire ? Theme.accent : Color.white.opacity(0.06))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Theme.accent.opacity(viewModel.rapidFire ? 0 : 0.35), lineWidth: 1)
            )
        }
        .accessibilityLabel("Rapid-fire mode")
        .accessibilityHint("Adds a tick and stronger haptic on each swipe for fast review")
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
