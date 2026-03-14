import UIKit

/// BreadStamp 전용 2중 세그먼트(segmented) 이미지 메모리 캐시
///
/// - `probationary`: 최초 적재/저재사용 엔트리
/// - `protected`: 반복 조회되는 hot 엔트리
///
/// 정책 요약:
/// - 총 예산: 50MB
/// - protected/probationary 비율: 70/30
/// - probationary hit 2회 시 protected 승격
final class ImageCacheService {
    static let shared = ImageCacheService()

    struct Metrics: Equatable {
        enum Segment: String {
            case probationary
            case protected
        }

        var requestCount: Int = 0
        var hitCount: Int = 0
        var missCount: Int = 0
        var lastAccessAt: Date?
        var cost: Int = 0
        var lastDecodeDuration: TimeInterval = 0
        var segment: Segment?
    }

    private final class Node {
        let key: String
        var image: UIImage
        var cost: Int
        var hitCount: Int
        var lastAccessAt: Date
        var segment: Metrics.Segment
        weak var prev: Node?
        var next: Node?

        init(
            key: String,
            image: UIImage,
            cost: Int,
            segment: Metrics.Segment,
            hitCount: Int = 0,
            lastAccessAt: Date = Date()
        ) {
            self.key = key
            self.image = image
            self.cost = cost
            self.segment = segment
            self.hitCount = hitCount
            self.lastAccessAt = lastAccessAt
        }
    }

    private struct SegmentStore {
        private(set) var nodes: [String: Node] = [:]
        private(set) var head: Node?
        private(set) var tail: Node?
        private(set) var totalCost: Int = 0

        func node(forKey key: String) -> Node? {
            nodes[key]
        }

        mutating func insertAtHead(_ node: Node) {
            nodes[node.key] = node
            totalCost += node.cost

            node.prev = nil
            node.next = head
            head?.prev = node
            head = node

            if tail == nil {
                tail = node
            }
        }

        mutating func moveToHead(_ node: Node) {
            guard head !== node, nodes[node.key] != nil else { return }
            unlink(node)
            node.prev = nil
            node.next = head
            head?.prev = node
            head = node
            if tail == nil {
                tail = node
            }
        }

        mutating func removeNode(forKey key: String) -> Node? {
            guard let node = nodes[key] else { return nil }
            return remove(node)
        }

        mutating func removeTail() -> Node? {
            guard let tail else { return nil }
            return remove(tail)
        }

        mutating func remove(_ node: Node) -> Node? {
            guard nodes[node.key] != nil else { return nil }
            unlink(node)
            nodes.removeValue(forKey: node.key)
            totalCost -= node.cost
            if totalCost < 0 {
                totalCost = 0
            }
            return node
        }

        mutating func removeAll() {
            nodes.removeAll()
            head = nil
            tail = nil
            totalCost = 0
        }

        private mutating func unlink(_ node: Node) {
            if let prev = node.prev {
                prev.next = node.next
            } else {
                head = node.next
            }

            if let next = node.next {
                next.prev = node.prev
            } else {
                tail = node.prev
            }

            node.prev = nil
            node.next = nil
        }
    }

    private let lock = NSLock()
    private var metricsByKey: [String: Metrics] = [:]
    private var probationaryStore = SegmentStore()
    private var protectedStore = SegmentStore()

    private let totalCostLimit: Int
    private let protectedCostLimit: Int
    private let probationaryCostLimit: Int
    private let promotionHitThreshold: Int

    init(
        totalCostLimit: Int = 50 * 1024 * 1024,
        protectedFraction: Double = 0.7,
        promotionHitThreshold: Int = 2
    ) {
        self.totalCostLimit = max(totalCostLimit, 1)
        let clampedProtectedFraction = min(max(protectedFraction, 0), 1)
        self.protectedCostLimit = max(Int(Double(self.totalCostLimit) * clampedProtectedFraction), 1)
        self.probationaryCostLimit = max(self.totalCostLimit - self.protectedCostLimit, 1)
        self.promotionHitThreshold = max(promotionHitThreshold, 1)
    }

    func image(for bakery: Bakery) -> UIImage? {
        image(forKey: bakery.imageCacheKey, data: bakery.imageData)
    }

    func image(for bread: Bread) -> UIImage? {
        image(forKey: bread.imageCacheKey, data: bread.imageData)
    }

    /// 캐시에서 이미지를 조회하거나, 캐시 미스 시 디코딩 후 캐싱
    /// - Parameters:
    ///   - key: 버전이 포함된 캐시 키
    ///   - data: 원본 이미지 Data (캐시 미스 시에만 디코딩)
    /// - Returns: 디코딩된 UIImage (데이터가 nil이거나 손상된 경우 nil)
    func image(forKey key: String, data: Data?) -> UIImage? {
        lock.lock()
        recordAccessLocked(forKey: key)
        if let cachedNode = cachedNodeOnHitLocked(forKey: key) {
            recordHitLocked(forKey: key, node: cachedNode)
            let image = cachedNode.image
            lock.unlock()
            return image
        }
        lock.unlock()

        let startedAt = CFAbsoluteTimeGetCurrent()
        guard let data, let decoded = UIImage(data: data) else {
            lock.lock()
            recordMissLocked(forKey: key)
            lock.unlock()
            return nil
        }

        let cost = estimatedCost(for: decoded, fallbackDataSize: data.count)
        let decodeDuration = CFAbsoluteTimeGetCurrent() - startedAt

        lock.lock()

        // 디코딩 중 경쟁 상태(race)로 이미 삽입되었다면 기존 캐시를 우선 반환한다.
        if let cachedNode = cachedNodeOnHitLocked(forKey: key) {
            recordHitLocked(forKey: key, node: cachedNode)
            let image = cachedNode.image
            lock.unlock()
            return image
        }

        insertDecodedImageLocked(image: decoded, key: key, cost: cost)
        recordMissLocked(
            forKey: key,
            cost: cost,
            decodeDuration: decodeDuration,
            segment: .probationary
        )

        if let node = node(forKey: key) {
            syncMetricsWithNodeLocked(node)
        }

        lock.unlock()
        return decoded
    }

    /// 특정 키의 캐시 무효화 (이미지 변경 시 호출)
    func invalidate(forKey key: String) {
        lock.lock()
        _ = protectedStore.removeNode(forKey: key)
        _ = probationaryStore.removeNode(forKey: key)
        metricsByKey.removeValue(forKey: key)
        lock.unlock()
    }

    /// 전체 캐시 초기화
    func clearAll() {
        lock.lock()
        protectedStore.removeAll()
        probationaryStore.removeAll()
        metricsByKey.removeAll()
        lock.unlock()
    }

    func metrics(forKey key: String) -> Metrics? {
        lock.lock()
        defer { lock.unlock() }
        return metricsByKey[key]
    }

    func snapshot() -> [String: Metrics] {
        lock.lock()
        defer { lock.unlock() }
        return metricsByKey
    }

    private func recordAccessLocked(forKey key: String) {
        updateMetricsLocked(forKey: key) { metrics in
            metrics.requestCount += 1
        }
    }

    private func recordHitLocked(forKey key: String, node: Node) {
        updateMetricsLocked(forKey: key) { metrics in
            metrics.hitCount += 1
            metrics.cost = node.cost
            metrics.segment = node.segment
        }
    }

    private func recordMissLocked(
        forKey key: String,
        cost: Int? = nil,
        decodeDuration: TimeInterval = 0,
        segment: Metrics.Segment? = nil
    ) {
        updateMetricsLocked(forKey: key) { metrics in
            metrics.missCount += 1
            if let cost {
                metrics.cost = cost
            }
            metrics.lastDecodeDuration = decodeDuration
            if let segment {
                metrics.segment = segment
            }
        }
    }

    private func updateMetricsLocked(
        forKey key: String,
        _ mutation: (inout Metrics) -> Void
    ) {
        var metrics = metricsByKey[key, default: Metrics()]
        mutation(&metrics)
        metrics.lastAccessAt = Date()
        metricsByKey[key] = metrics
    }

    private func node(forKey key: String) -> Node? {
        if let node = protectedStore.node(forKey: key) {
            return node
        }
        return probationaryStore.node(forKey: key)
    }

    private func cachedNodeOnHitLocked(forKey key: String) -> Node? {
        let now = Date()

        if let node = protectedStore.node(forKey: key) {
            protectedStore.moveToHead(node)
            node.hitCount += 1
            node.lastAccessAt = now
            return node
        }

        if let node = probationaryStore.node(forKey: key) {
            probationaryStore.moveToHead(node)
            node.hitCount += 1
            node.lastAccessAt = now

            if node.hitCount >= promotionHitThreshold {
                promoteToProtectedLocked(node)
            }
            return node
        }

        return nil
    }

    private func insertDecodedImageLocked(image: UIImage, key: String, cost: Int) {
        let node = Node(
            key: key,
            image: image,
            cost: max(cost, 1),
            segment: .probationary,
            hitCount: 0
        )
        probationaryStore.insertAtHead(node)
        enforceLimitsLocked()
    }

    private func promoteToProtectedLocked(_ node: Node) {
        guard probationaryStore.remove(node) != nil else { return }
        node.segment = .protected
        protectedStore.insertAtHead(node)
        enforceLimitsLocked()
    }

    private func demoteProtectedTailLocked() -> Bool {
        guard let demoted = protectedStore.removeTail() else { return false }
        demoted.segment = .probationary
        probationaryStore.insertAtHead(demoted)
        syncMetricsWithNodeLocked(demoted)
        return true
    }

    private func enforceLimitsLocked() {
        while protectedStore.totalCost > protectedCostLimit {
            guard demoteProtectedTailLocked() else { break }
        }

        while probationaryStore.totalCost > probationaryCostLimit {
            guard let evicted = probationaryStore.removeTail() else { break }
            metricsByKey.removeValue(forKey: evicted.key)
        }

        while totalCostLocked > totalCostLimit {
            if let evicted = probationaryStore.removeTail() {
                metricsByKey.removeValue(forKey: evicted.key)
                continue
            }

            if let evicted = protectedStore.removeTail() {
                metricsByKey.removeValue(forKey: evicted.key)
                continue
            }
            break
        }
    }

    private var totalCostLocked: Int {
        protectedStore.totalCost + probationaryStore.totalCost
    }

    private func syncMetricsWithNodeLocked(_ node: Node) {
        updateMetricsLocked(forKey: node.key) { metrics in
            metrics.cost = node.cost
            metrics.segment = node.segment
        }
    }

    private func estimatedCost(for image: UIImage, fallbackDataSize: Int) -> Int {
        if let cgImage = image.cgImage {
            let cgCost = cgImage.bytesPerRow * cgImage.height
            if cgCost > 0 {
                return cgCost
            }
        }

        let pixelWidth = Int(image.size.width * image.scale)
        let pixelHeight = Int(image.size.height * image.scale)
        let rgbaCost = pixelWidth * pixelHeight * 4
        if rgbaCost > 0 {
            return rgbaCost
        }

        return max(fallbackDataSize, 1)
    }
}
