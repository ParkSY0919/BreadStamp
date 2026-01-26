import Foundation

enum BreadCategory: String, Codable, CaseIterable, Identifiable {
    case toast = "식빵류"
    case croissant = "크로아상류"
    case sweetBun = "단팥빵류"
    case cake = "케이크류"
    case donut = "도넛류"
    case bagel = "베이글류"
    case other = "기타"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .toast: return "🍞"
        case .croissant: return "🥐"
        case .sweetBun: return "🥮"
        case .cake: return "🍰"
        case .donut: return "🍩"
        case .bagel: return "🥯"
        case .other: return "🥖"
        }
    }

    var displayName: String {
        rawValue
    }
}
