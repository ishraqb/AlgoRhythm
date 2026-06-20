import SwiftUI

/// Difficulty tiers, ordered low to high. The raw `Int` doubles as the
/// rank the matchmaking engine moves up and down.
enum Difficulty: Int, Codable, CaseIterable, Comparable, Identifiable {
    case intro = 0
    case easy = 1
    case medium = 2
    case hard = 3
    case expert = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .intro: return "Intro"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }

    var tint: Color {
        switch self {
        case .intro: return Color(red: 0.451, green: 0.643, blue: 0.580)
        case .easy: return Color(red: 0.514, green: 0.694, blue: 0.404)
        case .medium: return Color(red: 0.882, green: 0.659, blue: 0.286)
        case .hard: return Color(red: 0.886, green: 0.553, blue: 0.286)
        case .expert: return Color(red: 0.851, green: 0.435, blue: 0.318)
        }
    }

    /// Next tier up, capped at `expert`.
    func harder() -> Difficulty {
        Difficulty(rawValue: min(rawValue + 1, Difficulty.expert.rawValue)) ?? self
    }

    /// Next tier down, floored at `intro`.
    func easier() -> Difficulty {
        Difficulty(rawValue: max(rawValue - 1, Difficulty.intro.rawValue)) ?? self
    }

    // Decode from either the string name ("medium") or the raw int, so the
    // bundled JSON stays readable while ingested data can use numbers.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let raw = try? container.decode(Int.self), let value = Difficulty(rawValue: raw) {
            self = value
        } else {
            let name = try container.decode(String.self).lowercased()
            switch name {
            case "intro": self = .intro
            case "easy": self = .easy
            case "medium": self = .medium
            case "hard": self = .hard
            case "expert": self = .expert
            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unknown difficulty: \(name)"
                )
            }
        }
    }

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
