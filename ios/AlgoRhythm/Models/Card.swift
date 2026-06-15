import Foundation

/// A single study card. The front shows `prompt`; the back shows the
/// worked solution, code, and complexity.
struct Card: Identifiable, Codable, Equatable {
    let id: String
    let topic: Topic
    let difficulty: Difficulty
    let prompt: String
    let solution: String
    let code: String
    let language: String
    let timeComplexity: String
    let spaceComplexity: String

    /// Where this card came from (e.g. "Original", "MBPP", "system-design-primer").
    /// Drives the in-app attribution screen.
    let source: String
    let license: String

    enum CodingKeys: String, CodingKey {
        case id, topic, difficulty, prompt, solution, code, language
        case timeComplexity, spaceComplexity, source, license
    }
}

extension Card {
    /// Cards without code (most system-design cards) shouldn't render an
    /// empty code block.
    var hasCode: Bool {
        !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
