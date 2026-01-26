import Foundation

/// 업적 달성 조건을 체크하는 Stateless Service
struct AchievementService {

    // MARK: - Public Methods

    /// 현재 통계 기반으로 업적 달성 여부를 체크하고 업데이트된 업적 배열 반환
    /// - Parameters:
    ///   - bakeryCount: 방문한 빵집 수
    ///   - breadCount: 수집한 빵 수
    ///   - categories: 수집한 빵의 카테고리 Set
    ///   - fiveStarCount: 5점 평가를 받은 빵 수
    ///   - current: 현재 업적 배열
    /// - Returns: 새로 달성된 업적의 unlockedAt이 설정된 업적 배열
    static func checkAchievements(
        bakeryCount: Int,
        breadCount: Int,
        categories: Set<BreadCategory>,
        fiveStarCount: Int,
        current: [Achievement]
    ) -> [Achievement] {
        let now = Date()

        return current.map { achievement in
            // 이미 달성한 업적은 그대로 반환
            if achievement.isUnlocked {
                return achievement
            }

            // 달성 조건 체크
            let isMet = isRequirementMet(
                achievement.requirement,
                bakeryCount: bakeryCount,
                breadCount: breadCount,
                categories: categories,
                fiveStarCount: fiveStarCount
            )

            // 조건을 충족하면 달성 시간 설정
            if isMet {
                var unlocked = achievement
                unlocked.unlockedAt = now
                return unlocked
            }

            return achievement
        }
    }

    /// 특정 업적 요구사항이 충족되었는지 확인
    /// - Parameters:
    ///   - requirement: 확인할 업적 요구사항
    ///   - bakeryCount: 방문한 빵집 수
    ///   - breadCount: 수집한 빵 수
    ///   - categories: 수집한 빵의 카테고리 Set
    ///   - fiveStarCount: 5점 평가를 받은 빵 수
    /// - Returns: 요구사항 충족 여부
    static func isRequirementMet(
        _ requirement: AchievementRequirement,
        bakeryCount: Int,
        breadCount: Int,
        categories: Set<BreadCategory>,
        fiveStarCount: Int
    ) -> Bool {
        switch requirement {
        case .bakeryCount(let required):
            return bakeryCount >= required

        case .breadCount(let required):
            return breadCount >= required

        case .allCategories:
            // 모든 카테고리를 수집했는지 확인
            return categories.count == BreadCategory.allCases.count

        case .fiveStarBreads(let required):
            return fiveStarCount >= required
        }
    }

    // MARK: - Helper Methods

    /// 달성 가능한 업적 목록 필터링 (아직 달성하지 않은 업적)
    /// - Parameter achievements: 전체 업적 배열
    /// - Returns: 미달성 업적 배열
    static func availableAchievements(from achievements: [Achievement]) -> [Achievement] {
        achievements.filter { !$0.isUnlocked }
    }

    /// 달성한 업적 목록 필터링
    /// - Parameter achievements: 전체 업적 배열
    /// - Returns: 달성한 업적 배열
    static func unlockedAchievements(from achievements: [Achievement]) -> [Achievement] {
        achievements.filter { $0.isUnlocked }
    }

    /// 전체 업적 달성률 계산
    /// - Parameter achievements: 전체 업적 배열
    /// - Returns: 달성률 (0.0 ~ 1.0)
    static func completionRate(for achievements: [Achievement]) -> Double {
        guard !achievements.isEmpty else { return 0.0 }
        let unlockedCount = achievements.filter { $0.isUnlocked }.count
        return Double(unlockedCount) / Double(achievements.count)
    }

    /// 다음 달성 가능한 업적 추천 (진행도 기준 정렬)
    /// - Parameters:
    ///   - achievements: 전체 업적 배열
    ///   - bakeryCount: 현재 빵집 수
    ///   - breadCount: 현재 빵 수
    ///   - categories: 현재 카테고리 Set
    ///   - fiveStarCount: 현재 5점 빵 수
    /// - Returns: 가장 달성하기 가까운 업적 (옵셔널)
    static func nextAchievement(
        from achievements: [Achievement],
        bakeryCount: Int,
        breadCount: Int,
        categories: Set<BreadCategory>,
        fiveStarCount: Int
    ) -> Achievement? {
        let available = availableAchievements(from: achievements)

        // 진행도를 계산하여 가장 높은 것 반환
        return available.max { a, b in
            progress(for: a.requirement, bakeryCount: bakeryCount, breadCount: breadCount, categories: categories, fiveStarCount: fiveStarCount) <
            progress(for: b.requirement, bakeryCount: bakeryCount, breadCount: breadCount, categories: categories, fiveStarCount: fiveStarCount)
        }
    }

    // MARK: - Private Methods

    /// 특정 요구사항의 진행도 계산 (0.0 ~ 1.0)
    private static func progress(
        for requirement: AchievementRequirement,
        bakeryCount: Int,
        breadCount: Int,
        categories: Set<BreadCategory>,
        fiveStarCount: Int
    ) -> Double {
        switch requirement {
        case .bakeryCount(let required):
            return min(Double(bakeryCount) / Double(required), 1.0)

        case .breadCount(let required):
            return min(Double(breadCount) / Double(required), 1.0)

        case .allCategories:
            return Double(categories.count) / Double(BreadCategory.allCases.count)

        case .fiveStarBreads(let required):
            return min(Double(fiveStarCount) / Double(required), 1.0)
        }
    }
}
