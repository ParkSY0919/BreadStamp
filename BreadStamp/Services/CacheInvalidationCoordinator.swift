import Foundation

enum CacheInvalidationCoordinator {
    static func invalidateStatistics() {
        StatisticsCacheService.shared.invalidate()
    }

    static func invalidateImage(forKey key: String?) {
        guard let key else { return }
        ImageCacheService.shared.invalidate(forKey: key)
    }
}
