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

            // 업적 조건 체크 (requirement enum 기반)
            switch achievements[index].requirement {
            case .bakeryCount(let required):
                shouldUnlock = bakeryCount >= required
            case .breadCount(let required):
                shouldUnlock = breadCount >= required
            case .allCategories:
                shouldUnlock = categories.count >= BreadCategory.allCases.count
            case .fiveStarBreads(let required):
                shouldUnlock = fiveStarCount >= required
            }

            // 업적 달성 처리
            if shouldUnlock {
                achievements[index].unlockedAt = Date()
            }
        }
    }
}
