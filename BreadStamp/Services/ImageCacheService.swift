import UIKit

/// NSCache 기반 LRU 이미지 캐시 서비스
///
/// ## 도입 배경
/// SwiftData의 `@Attribute(.externalStorage)`로 저장된 이미지 Data를
/// `UIImage(data:)` 로 매번 디코딩하면 JPEG/PNG 압축 해제 비용이 발생한다.
/// 특히 ScrollView + LazyVStack/LazyVGrid에서 셀이 재사용될 때마다
/// 동일 이미지를 반복 디코딩하면 스크롤 프레임 드롭의 원인이 된다.
///
/// ## 설계 결정
/// - **NSCache 선택 이유**: 시스템 메모리 압박(Memory Warning) 시 자동으로
///   LRU(Least Recently Used) 순서로 엔트리를 제거한다.
///   Dictionary + 수동 제거 대비 메모리 안전성이 높다.
/// - **countLimit = 100**: 일반 사용자의 빵집 + 빵 이미지가 100장을 넘기 어려운 점 반영
/// - **totalCostLimit = 50MB**: iPhone 평균 가용 메모리(~1.5GB) 대비
///   안전한 수준으로 설정. UIImage의 비압축 크기 기준으로 관리.
/// - **Singleton 패턴**: 앱 전역에서 동일 캐시 풀을 공유하여 중복 캐싱 방지
///
final class ImageCacheService {
    static let shared = ImageCacheService()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    /// 캐시에서 이미지를 조회하거나, 캐시 미스 시 디코딩 후 캐싱
    /// - Parameters:
    ///   - key: 캐시 키 (UUID 문자열 권장)
    ///   - data: 원본 이미지 Data (캐시 미스 시에만 디코딩)
    /// - Returns: 디코딩된 UIImage (데이터가 nil이거나 손상된 경우 nil)
    func image(forKey key: String, data: Data?) -> UIImage? {
        // 1. 캐시 히트 → O(1) 즉시 반환
        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }

        // 2. 캐시 미스 → 디코딩 후 캐싱
        guard let data, let decoded = UIImage(data: data) else {
            return nil
        }

        let cost = data.count
        cache.setObject(decoded, forKey: key as NSString, cost: cost)
        return decoded
    }

    /// 특정 키의 캐시 무효화 (이미지 변경 시 호출)
    func invalidate(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    /// 전체 캐시 초기화
    func clearAll() {
        cache.removeAllObjects()
    }
}
