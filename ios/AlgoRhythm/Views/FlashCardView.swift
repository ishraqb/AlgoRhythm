import SwiftUI

/// A single card that flips between prompt (front) and solution (back) on tap.
/// The 3D flip is a y-axis rotation; we swap faces at the 90-degree mark and
/// counter-rotate the back so its text isn't mirrored.
struct FlashCardView: View {
    let card: Card
    @State private var flipped = false

    private var angle: Double { flipped ? 180 : 0 }

    var body: some View {
        ZStack {
            front
                .opacity(flipped ? 0 : 1)
            back
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0))
        .shadow(color: .black.opacity(0.4), radius: 18, y: 10)
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                flipped.toggle()
            }
        }
        // A fresh card should always start on its prompt side.
        .onChange(of: card.id) { _ in flipped = false }
    }

    private var front: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Text(card.prompt)
                .font(Theme.display(.title2, weight: .semibold))
                .foregroundStyle(.white)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Label("Tap to reveal", systemImage: "hand.tap.fill")
                .font(.caption)
                .foregroundStyle(Theme.accent.opacity(0.7))
        }
        .padding(24)
    }

    private var back: some View {
        SolutionView(card: card)
    }

    private var header: some View {
        HStack {
            Text(card.topic.title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.chip(for: card.topic.category).opacity(0.25))
                .foregroundStyle(Color.chip(for: card.topic.category))
                .clipShape(Capsule())
            Spacer()
            Text(card.difficulty.title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(card.difficulty.tint.opacity(0.22))
                .foregroundStyle(card.difficulty.tint)
                .clipShape(Capsule())
        }
    }
}
