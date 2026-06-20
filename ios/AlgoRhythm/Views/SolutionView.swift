import SwiftUI

/// The back of a card: worked solution, optional code block, and complexity.
struct SolutionView: View {
    let card: Card

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Solution")
                    .font(Theme.display(.title3, weight: .semibold))
                    .foregroundStyle(Theme.accent)

                Text(card.solution)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                if card.hasCode {
                    codeBlock
                }

                complexityRow
            }
            .padding(22)
        }
    }

    private var codeBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !card.language.isEmpty {
                Text(card.language.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(card.code)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(14)
            }
            .background(Color.black.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var complexityRow: some View {
        HStack(spacing: 12) {
            complexityPill(label: "Time", value: card.timeComplexity)
            complexityPill(label: "Space", value: card.spaceComplexity)
        }
    }

    private func complexityPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
