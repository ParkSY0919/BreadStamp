import Foundation

/// TTL(Time-To-Live) 기반 통계 캐시 서비스
///
/// ## 도입 배경
/// `StatisticsService.calculate()`는 전체 Bakery/Bread 배열을 순회(O(N))하며
/// 평균 평점, 카테고리별 집계, 월별 방문 등을 계산한다.
/// ProfileView의 `stats` computed property가 SwiftUI body 렌더링마다 호출되므로,
/// 스크롤/탭 전환 시 불필요한 재계산이 반복된다.
///
/// ## 설계 결정
/// - **TTL = 60초**: 통계 데이터는 실시간 정확도가 불필요하고, 사용자가 빵/빵집을
///   추가한 후 프로필 탭 재진입까지 통상 수초~수십초가 소요되므로 60초면 충분
/// - **데이터 변경 감지**: 빵집/빵 개수(count)를 fingerprint로 사용.
///   개수가 변하면 캐시를 즉시 무효화하여 데이터 추가/삭제를 반영
/// - **개수 동일 + TTL 이내 = 캐시 히트**: 평점 변경 같은 드문 케이스는
///   최대 60초 후 자동 갱신되므로 UX 영향 최소화
/// - **Singleton**: 탭 전환 시에도 캐시를 유지하여 재계산 방지
///
final class StatisticsCacheService {
    static let shared = StatisticsCacheService()

    private var cachedStats: StatisticsService.Stats?
    private var cachedAt: Date?
    private var cachedBakeryCount: Int = -1
    private var cachedBreadCount: Int = -1

    /// 캐시 유효 시간 (60초)
    private let ttl: TimeInterval = 60

    private init() {}

    /// 캐시된 통계를 반환하거나, 캐시 미스/만료 시 재계산
    /// - Parameters:
    ///   - bakeries: 전체 빵집 배열
    ///   - breads: 전체 빵 배열
    /// - Returns: 계산된 통계 데이터
    func stats(bakeries: [Bakery], breads: [Bread]) -> StatisticsService.Stats {
        let now = Date()

        // 캐시 히트 조건: TTL 이내 + 데이터 개수 동일
        if let cached = cachedStats,
           let at = cachedAt,
           now.timeIntervalSince(at) < ttl,
           cachedBakeryCount == bakeries.count,
           cachedBreadCount == breads.count {
            return cached
        }

        // 캐시 미스 → 재계산
        let newStats = StatisticsService.calculate(bakeries: bakeries, breads: breads)
        cachedStats = newStats
        cachedAt = now
        cachedBakeryCount = bakeries.count
        cachedBreadCount = breads.count
        return newStats
    }

    /// 캐시 강제 무효화 (데이터 변경 시 호출)
    func invalidate() {
        cachedStats = nil
        cachedAt = nil
        cachedBakeryCount = -1
        cachedBreadCount = -1
    }
}
