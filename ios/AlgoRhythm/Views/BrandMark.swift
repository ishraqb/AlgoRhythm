import SwiftUI

/// AlgoRhythm's mark: a small linked list of nodes whose pointer chain resolves
/// into a music note — the "algorithm" (nodes + pointers) meeting the "rhythm"
/// (the note at the tail).
struct BrandMark: View {
    var size: CGFloat = 48
    var color: Color = Theme.accent

    private var node: CGFloat { size * 0.44 }
    private var arrow: CGFloat { size * 0.24 }
    private var stroke: CGFloat { max(1.5, size * 0.05) }

    var body: some View {
        HStack(spacing: size * 0.1) {
            listNode
            pointer
            listNode
            pointer
            noteNode
        }
        .frame(height: size)
    }

    /// A data-structure cell drawn as a hollow node.
    private var listNode: some View {
        Circle()
            .stroke(color, lineWidth: stroke)
            .frame(width: node, height: node)
    }

    /// The "next" pointer between cells.
    private var pointer: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: arrow, weight: .bold))
            .foregroundStyle(color.opacity(0.65))
    }

    /// The tail node, carrying the rhythm.
    private var noteNode: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: node * 1.16, height: node * 1.16)
            Image(systemName: "music.note")
                .font(.system(size: node * 0.66, weight: .bold))
                .foregroundStyle(Theme.background)
        }
    }
}
