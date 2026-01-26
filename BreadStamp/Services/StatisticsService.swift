import Foundation

/// 통계 데이터를 계산하는 Stateless Service
struct StatisticsService {

    // MARK: - Statistics Data Structure

    /// 전체 통계 데이터
    struct Stats {
        /// 방문한 빵집 총 개수
        let totalBakeries: Int

        /// 수집한 빵 총 개수
        let totalBreads: Int

        /// 즐겨찾기한 빵집 개수
        let favoriteBakeries: Int

        /// 평균 평점 (1.0 ~ 5.0)
        let averageRating: Double

        /// 가장 많이 수집한 빵 카테고리
        let topCategory: BreadCategory?

        /// 카테고리별 빵 개수
        let categoryCounts: [BreadCategory: Int]

        /// 월별 방문 횟수 (key: "2024-01", value: count)
        let monthlyVisits: [String: Int]

        /// 이번 달 방문 횟수
        var currentMonthVisits: Int {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            let currentMonth = formatter.string(from: Date())
            return monthlyVisits[currentMonth] ?? 0
        }

        /// 5점 평가를 받은 빵 개수
        let fiveStarBreadCount: Int
    }

    // MARK: - Public Methods

    /// 빵집 및 빵 데이터로부터 통계 계산
    /// - Parameters:
    ///   - bakeries: 빵집 배열
    ///   - breads: 빵 배열
    /// - Returns: 계산된 통계 데이터
    static func calculate(bakeries: [Bakery], breads: [Bread]) -> Stats {
        let totalBakeries = bakeries.count
        let totalBreads = breads.count
        let favoriteBakeries = bakeries.filter { $0.isFavorite }.count

        // 평균 평점 계산
        let averageRating = calculateAverageRating(from: breads)

        // 카테고리별 빵 개수 계산
        let categoryCounts = calculateCategoryCounts(from: breads)

        // 가장 많은 카테고리 찾기
        let topCategory = findTopCategory(from: categoryCounts)

        // 월별 방문 횟수 계산
        let monthlyVisits = calculateMonthlyVisits(from: bakeries)

        // 5점 빵 개수 계산
        let fiveStarBreadCount = fiveStarBreadCount(from: breads)

        return Stats(
            totalBakeries: totalBakeries,
            totalBreads: totalBreads,
            favoriteBakeries: favoriteBakeries,
            averageRating: averageRating,
            topCategory: topCategory,
            categoryCounts: categoryCounts,
            monthlyVisits: monthlyVisits,
            fiveStarBreadCount: fiveStarBreadCount
        )
    }

    // MARK: - Helper Methods

    /// 5점 평가를 받은 빵 개수 계산
    /// - Parameter breads: 빵 배열
    /// - Returns: 5점 빵 개수
    static func fiveStarBreadCount(from breads: [Bread]) -> Int {
        breads.filter { $0.rating == 5 }.count
    }

    /// 수집한 카테고리 Set 반환
    /// - Parameter breads: 빵 배열
    /// - Returns: 카테고리 Set
    static func collectedCategories(from breads: [Bread]) -> Set<BreadCategory> {
        Set(breads.map { $0.category })
    }

    /// 특정 기간 내 방문한 빵집 개수
    /// - Parameters:
    ///   - bakeries: 빵집 배열
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 방문 횟수
    static func visitCount(
        in bakeries: [Bakery],
        from startDate: Date,
        to endDate: Date
    ) -> Int {
        bakeries.filter { bakery in
            bakery.visitedAt >= startDate && bakery.visitedAt <= endDate
        }.count
    }

    /// 최근 N일간 방문한 빵집 개수
    /// - Parameters:
    ///   - bakeries: 빵집 배열
    ///   - days: 일 수
    /// - Returns: 방문 횟수
    static func recentVisitCount(in bakeries: [Bakery], lastDays days: Int) -> Int {
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            return 0
        }
        return visitCount(in: bakeries, from: startDate, to: Date())
    }

    /// 빵집별 빵 개수 계산
    /// - Parameter bakeries: 빵집 배열
    /// - Returns: 빵집 ID별 빵 개수 딕셔너리
    static func breadCountPerBakery(from bakeries: [Bakery]) -> [UUID: Int] {
        bakeries.reduce(into: [:]) { result, bakery in
            result[bakery.id] = bakery.breadCount
        }
    }

    /// 가장 많은 빵을 수집한 빵집 찾기
    /// - Parameter bakeries: 빵집 배열
    /// - Returns: 가장 많은 빵을 가진 빵집 (옵셔널)
    static func topBakery(from bakeries: [Bakery]) -> Bakery? {
        bakeries.max { $0.breadCount < $1.breadCount }
    }

    // MARK: - Private Methods

    /// 평균 평점 계산
    private static func calculateAverageRating(from breads: [Bread]) -> Double {
        guard !breads.isEmpty else { return 0.0 }
        let totalRating = breads.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(breads.count)
    }

    /// 카테고리별 빵 개수 계산
    private static func calculateCategoryCounts(from breads: [Bread]) -> [BreadCategory: Int] {
        breads.reduce(into: [:]) { counts, bread in
            counts[bread.category, default: 0] += 1
        }
    }

    /// 가장 많은 카테고리 찾기
    private static func findTopCategory(from categoryCounts: [BreadCategory: Int]) -> BreadCategory? {
        categoryCounts.max { $0.value < $1.value }?.key
    }

    /// 월별 방문 횟수 계산
    private static func calculateMonthlyVisits(from bakeries: [Bakery]) -> [String: Int] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        return bakeries.reduce(into: [:]) { result, bakery in
            let monthKey = formatter.string(from: bakery.visitedAt)
            result[monthKey, default: 0] += 1
        }
    }

    /// 주별 방문 횟수 계산 (최근 N주)
    /// - Parameters:
    ///   - bakeries: 빵집 배열
    ///   - weeks: 주 수
    /// - Returns: 주별 방문 횟수 딕셔너리 (key: "2024-W01")
    static func weeklyVisits(from bakeries: [Bakery], lastWeeks weeks: Int) -> [String: Int] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-'W'ww"

        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -weeks, to: Date()) else {
            return [:]
        }

        let recentBakeries = bakeries.filter { $0.visitedAt >= startDate }

        return recentBakeries.reduce(into: [:]) { result, bakery in
            let weekKey = formatter.string(from: bakery.visitedAt)
            result[weekKey, default: 0] += 1
        }
    }

    /// 카테고리별 평균 평점 계산
    /// - Parameter breads: 빵 배열
    /// - Returns: 카테고리별 평균 평점 딕셔너리
    static func averageRatingByCategory(from breads: [Bread]) -> [BreadCategory: Double] {
        let grouped = Dictionary(grouping: breads, by: { $0.category })

        return grouped.mapValues { breadsInCategory in
            guard !breadsInCategory.isEmpty else { return 0.0 }
            let total = breadsInCategory.reduce(0) { $0 + $1.rating }
            return Double(total) / Double(breadsInCategory.count)
        }
    }
}
