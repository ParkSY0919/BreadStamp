import Foundation

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let requirement: AchievementRequirement
    var unlockedAt: Date?

    var isUnlocked: Bool {
        unlockedAt != nil
    }

    var guide: String {
        switch requirement {
        case .bakeryCount(let count):
            return "빵집을 \(count)개 방문하면 달성할 수 있어요!\n스탬프북에서 새로운 빵집을 추가해보세요."
        case .breadCount(let count):
            return "빵을 \(count)개 기록하면 달성할 수 있어요!\n빵집 상세에서 먹은 빵을 추가해보세요."
        case .allCategories:
            return "모든 카테고리의 빵을 기록하면 달성할 수 있어요!\n다양한 종류의 빵을 맛보세요."
        case .fiveStarBreads(let count):
            return "5점 만점 빵을 \(count)개 기록하면 달성할 수 있어요!\n최고의 빵을 발견해보세요."
        }
    }

    static let allAchievements: [Achievement] = [
        Achievement(
            id: "first_stamp",
            title: "첫 발걸음",
            description: "첫 번째 빵집 방문",
            iconName: "flag.fill",
            requirement: .bakeryCount(1)
        ),
        Achievement(
            id: "stamp_5",
            title: "빵집 탐험가",
            description: "5개의 빵집 방문",
            iconName: "star.fill",
            requirement: .bakeryCount(5)
        ),
        Achievement(
            id: "stamp_10",
            title: "빵집 수집가",
            description: "10개의 빵집 방문",
            iconName: "trophy.fill",
            requirement: .bakeryCount(10)
        ),
        Achievement(
            id: "stamp_25",
            title: "빵집 마스터",
            description: "25개의 빵집 방문",
            iconName: "crown.fill",
            requirement: .bakeryCount(25)
        ),
        Achievement(
            id: "first_bread",
            title: "첫 맛",
            description: "첫 번째 빵 기록",
            iconName: "birthday.cake.fill",
            requirement: .breadCount(1)
        ),
        Achievement(
            id: "bread_10",
            title: "빵 애호가",
            description: "10개의 빵 기록",
            iconName: "heart.fill",
            requirement: .breadCount(10)
        ),
        Achievement(
            id: "bread_50",
            title: "빵 도감 완성 중",
            description: "50개의 빵 기록",
            iconName: "book.fill",
            requirement: .breadCount(50)
        ),
        Achievement(
            id: "all_categories",
            title: "다양한 입맛",
            description: "모든 카테고리 빵 기록",
            iconName: "sparkles",
            requirement: .allCategories
        ),
        Achievement(
            id: "five_star",
            title: "완벽한 맛",
            description: "5점 빵 5개 기록",
            iconName: "star.circle.fill",
            requirement: .fiveStarBreads(5)
        )
    ]
}

enum AchievementRequirement: Codable, Equatable {
    case bakeryCount(Int)
    case breadCount(Int)
    case allCategories
    case fiveStarBreads(Int)
}
