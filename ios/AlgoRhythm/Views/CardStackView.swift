import SwiftUI

/// The swipeable card area. Drag right to mark mastered, left to mark for
/// review. The card tracks the finger with a little rotation for a natural
/// "throw", and a colored stamp fades in to telegraph the outcome.
struct CardStackView: View {
    @EnvironmentObject private var viewModel: DeckViewModel
    @State private var drag: CGSize = .zero

    // How far the card must travel before a release counts as a swipe.
    private let threshold: CGFloat = 120

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let card = viewModel.currentCard {
                    backingCard
                    topCard(card, in: geo.size)
                } else {
                    completedState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func topCard(_ card: Card, in size: CGSize) -> some View {
        FlashCardView(card: card)
            .overlay(stampOverlay)
            .offset(drag)
            .rotationEffect(.degrees(Double(drag.width / 18)))
            .gesture(
                DragGesture()
                    .onChanged { value in drag = value.translation }
                    .onEnded { value in finishSwipe(value.translation.width, width: size.width) }
            )
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: drag)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
    }

    // A dimmed, slightly smaller card peeking behind to convey a deck of depth.
    private var backingCard: some View {
        RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
            .fill(Theme.cardGradient)
            .opacity(0.5)
            .scaleEffect(0.94)
            .offset(y: 14)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
    }

    private var stampOverlay: some View {
        ZStack {
            stamp(text: "MASTERED", color: Theme.mastered)
                .opacity(Double(max(0, drag.width) / threshold))
            stamp(text: "REVIEW", color: Theme.review)
                .opacity(Double(max(0, -drag.width) / threshold))
        }
    }

    private func stamp(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 32, weight: .heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: 4)
            )
            .rotationEffect(.degrees(-15))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(40)
    }

    private var completedState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 54))
                .foregroundStyle(Theme.accent)
            Text("Deck complete")
                .font(Theme.display(.title, weight: .bold))
                .foregroundStyle(.white)
            Text("You worked through every card in this filter.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Button("Start over") { viewModel.restart() }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .padding(.top, 6)
        }
        .padding(40)
    }

    private func finishSwipe(_ translationWidth: CGFloat, width: CGFloat) {
        guard abs(translationWidth) > threshold else {
            drag = .zero
            return
        }
        let outcome: SwipeOutcome = translationWidth > 0 ? .mastered : .review
        let flyOff = (translationWidth > 0 ? 1 : -1) * (width + 200)

        withAnimation(.easeOut(duration: 0.25)) {
            drag = CGSize(width: flyOff, height: drag.height)
        }
        // Advance once the card has cleared the screen, then snap back for the
        // incoming card.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            viewModel.handleSwipe(outcome)
            drag = .zero
        }
    }
}
