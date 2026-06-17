import SwiftUI

/// Attribution screen. The MBPP and system-design-primer datasets are CC-BY,
/// which requires visible credit, so we list every content source present in
/// the deck plus the libraries used.
struct CreditsView: View {
    private let repository = QuestionRepository.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Content Sources") {
                    ForEach(repository.attributions, id: \.self) { line in
                        Text(line)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .listRowBackground(Color.white.opacity(0.04))

                Section("Licenses") {
                    creditRow(
                        title: "MBPP",
                        detail: "Mostly Basic Python Problems — CC-BY-4.0"
                    )
                    creditRow(
                        title: "system-design-primer",
                        detail: "Donne Martin — CC BY 4.0"
                    )
                    creditRow(
                        title: "Original cards",
                        detail: "Authored for AlgoRhythm"
                    )
                }
                .listRowBackground(Color.white.opacity(0.04))

                Section {
                    Text("Original problems are written for AlgoRhythm. No proprietary or copyrighted problem text from third-party platforms is included.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Credits")
        }
    }

    private func creditRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.vertical, 2)
    }
}
