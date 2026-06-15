import Foundation

/// A study category. Each card belongs to exactly one topic, and the
/// matchmaking engine tracks performance per topic.
enum Topic: String, Codable, CaseIterable, Identifiable {
    // Data structures & algorithms
    case arrays
    case hashMaps
    case twoPointers
    case slidingWindow
    case trees
    case graphs
    case recursion
    case dynamicProgramming
    case bitManipulation

    // System design
    case scalability
    case loadBalancing
    case caching
    case sharding
    case capTheorem
    case microservices
    case rateLimiting
    case messageQueues

    var id: String { rawValue }

    var category: Category {
        switch self {
        case .arrays, .hashMaps, .twoPointers, .slidingWindow, .trees,
             .graphs, .recursion, .dynamicProgramming, .bitManipulation:
            return .algorithms
        default:
            return .systemDesign
        }
    }

    var title: String {
        switch self {
        case .arrays: return "Arrays"
        case .hashMaps: return "Hash Maps"
        case .twoPointers: return "Two Pointers"
        case .slidingWindow: return "Sliding Window"
        case .trees: return "Trees"
        case .graphs: return "Graphs"
        case .recursion: return "Recursion"
        case .dynamicProgramming: return "Dynamic Programming"
        case .bitManipulation: return "Bit Manipulation"
        case .scalability: return "Scalability"
        case .loadBalancing: return "Load Balancing"
        case .caching: return "Caching"
        case .sharding: return "Sharding"
        case .capTheorem: return "CAP Theorem"
        case .microservices: return "Microservices"
        case .rateLimiting: return "Rate Limiting"
        case .messageQueues: return "Message Queues"
        }
    }

    enum Category: String, Codable, CaseIterable, Identifiable {
        case algorithms
        case systemDesign

        var id: String { rawValue }

        var title: String {
            switch self {
            case .algorithms: return "Algorithms"
            case .systemDesign: return "System Design"
            }
        }
    }
}
