import SwiftUI

@Observable
final class ProfileViewModel {
    // MARK: - State

    /// 업적 목록
    var achievements: [Achievement] = Achievement.allAchievements

    // MARK: - Computed Properties

    /// 달성한 업적 수
    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    /// 전체 업적 수
    var totalCount: Int {
        achievements.count
    }

    // MARK: - Methods

    /// 업적 달성 여부 업데이트
    func updateAchievements(
        bakeryCount: Int,
        breadCount: Int,
        categories: Set<BreadCategory>,
        fiveStarCount: Int
    ) {
        for index in achievements.indices {
            // 이미 달성한 업적은 스킵
            if achievements[index].isUnlocked {
                continue
            }

            var shouldUnlock = false

            // 업적 조건 체크
            switch achievements[index].id {
            // 빵집 방문 업적
            case "first_bakery":
                shouldUnlock = bakeryCount >= 1
            case "bakery_explorer":
                shouldUnlock = bakeryCount >= 5
            case "bakery_master":
                shouldUnlock = bakeryCount >= 10
            case "bakery_legend":
                shouldUnlock = bakeryCount >= 30

            // 빵 수집 업적
            case "first_bread":
                shouldUnlock = breadCount >= 1
            case "bread_collector":
                shouldUnlock = breadCount >= 10
            case "bread_master":
                shouldUnlock = breadCount >= 30
            case "bread_legend":
                shouldUnlock = breadCount >= 100

            // 카테고리 업적
            case "category_explorer":
                shouldUnlock = categories.count >= 3
            case "category_master":
                shouldUnlock = categories.count >= BreadCategory.allCases.count

            // 평가 업적
            case "five_star_lover":
                shouldUnlock = fiveStarCount >= 5
            case "critic":
                shouldUnlock = fiveStarCount >= 20

            default:
                break
            }

            // 업적 달성 처리
            if shouldUnlock {
                achievements[index].unlockedAt = Date()
            }
        }
    }
}
