import XCTest
import SwiftData
import UIKit
@testable import BreadStamp

@MainActor
final class CacheServicesTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ImageCacheService.shared.clearAll()
        StatisticsCacheService.shared.invalidate()
    }

    override func tearDown() {
        ImageCacheService.shared.clearAll()
        StatisticsCacheService.shared.invalidate()
        super.tearDown()
    }

    func test_ImageCache_recordsHitAndMissMetrics() {
        let bread = Bread(
            name: "크루아상",
            category: .croissant,
            imageData: makeImageData(color: .systemRed),
            rating: 5
        )

        XCTAssertNotNil(ImageCacheService.shared.image(for: bread))
        XCTAssertNotNil(ImageCacheService.shared.image(for: bread))

        let metrics = ImageCacheService.shared.metrics(forKey: bread.imageCacheKey)

        XCTAssertEqual(metrics?.requestCount, 2)
        XCTAssertEqual(metrics?.hitCount, 1)
        XCTAssertEqual(metrics?.missCount, 1)
        XCTAssertNotNil(metrics?.lastAccessAt)
        XCTAssertGreaterThan(metrics?.cost ?? 0, 0)
    }

    func test_ImageCache_usesVersionedKeyWhenImageDataChanges() {
        let bread = Bread(
            name: "식빵",
            category: .toast,
            imageData: makeImageData(color: .systemBlue),
            rating: 3
        )
        let originalKey = bread.imageCacheKey

        XCTAssertNotNil(ImageCacheService.shared.image(for: bread))

        bread.imageData = makeImageData(color: .systemGreen)
        bread.updatedAt = Date().addingTimeInterval(1)
        let updatedKey = bread.imageCacheKey

        XCTAssertNotEqual(originalKey, updatedKey)
        XCTAssertNotNil(ImageCacheService.shared.image(for: bread))

        let snapshot = ImageCacheService.shared.snapshot()
        XCTAssertEqual(snapshot[originalKey]?.missCount, 1)
        XCTAssertEqual(snapshot[updatedKey]?.missCount, 1)
    }

    func test_BakeryViewModel_toggleFavoriteInvalidatesStatisticsCache() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let bakery = Bakery(name: "테스트 빵집", address: "서울시")

        context.insert(bakery)
        try context.save()

        let initialStats = StatisticsCacheService.shared.stats(
            bakeries: [bakery],
            breads: []
        )
        XCTAssertEqual(initialStats.favoriteBakeries, 0)

        let viewModel = BakeryViewModel()
        viewModel.toggleFavorite(bakery, context: context)

        let updatedStats = StatisticsCacheService.shared.stats(
            bakeries: [bakery],
            breads: []
        )
        XCTAssertEqual(updatedStats.favoriteBakeries, 1)
    }

    func test_BreadViewModel_updateBreadInvalidatesStatisticsCache() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let bakery = Bakery(name: "테스트 빵집", address: "서울시")
        let bread = Bread(
            name: "소금빵",
            category: .toast,
            imageData: makeImageData(color: .systemOrange),
            rating: 1,
            bakery: bakery
        )

        context.insert(bakery)
        context.insert(bread)
        try context.save()

        let initialStats = StatisticsCacheService.shared.stats(
            bakeries: [bakery],
            breads: [bread]
        )
        XCTAssertEqual(initialStats.averageRating, 1.0)
        XCTAssertEqual(initialStats.categoryCounts[.toast], 1)

        let viewModel = BreadViewModel()
        viewModel.updateBread(
            bread,
            name: "소금빵",
            category: .croissant,
            imageData: bread.imageData,
            rating: 5,
            memo: nil,
            context: context
        )

        let updatedStats = StatisticsCacheService.shared.stats(
            bakeries: [bakery],
            breads: [bread]
        )
        XCTAssertEqual(updatedStats.averageRating, 5.0)
        XCTAssertEqual(updatedStats.categoryCounts[.croissant], 1)
        XCTAssertNil(updatedStats.categoryCounts[.toast])
    }

    func test_ImageCache_promotesToProtectedAfterTwoHits() {
        let service = ImageCacheService(
            totalCostLimit: 200_000,
            protectedFraction: 0.7,
            promotionHitThreshold: 2
        )
        let bread = Bread(
            name: "소금빵",
            category: .toast,
            imageData: makeImageData(color: .systemTeal, size: CGSize(width: 24, height: 24)),
            rating: 4
        )
        let key = bread.imageCacheKey

        XCTAssertNotNil(service.image(for: bread))
        XCTAssertEqual(service.metrics(forKey: key)?.segment, .probationary)

        XCTAssertNotNil(service.image(for: bread))
        XCTAssertEqual(service.metrics(forKey: key)?.segment, .probationary)

        XCTAssertNotNil(service.image(for: bread))
        let metrics = service.metrics(forKey: key)
        XCTAssertEqual(metrics?.hitCount, 2)
        XCTAssertEqual(metrics?.missCount, 1)
        XCTAssertEqual(metrics?.segment, .protected)
    }

    func test_ImageCache_demotesProtectedTailAndTrimsProbationaryWhenProtectedOverLimit() {
        let dataSize = CGSize(width: 48, height: 48)
        let unitCost = decodedCost(for: makeImageData(color: .systemRed, size: dataSize))
        let service = ImageCacheService(
            totalCostLimit: unitCost * 4,
            protectedFraction: 0.7,
            promotionHitThreshold: 2
        )

        let breadA = Bread(name: "A", category: .toast, imageData: makeImageData(color: .systemRed, size: dataSize), rating: 5)
        let breadB = Bread(name: "B", category: .toast, imageData: makeImageData(color: .systemBlue, size: dataSize), rating: 5)
        let breadC = Bread(name: "C", category: .toast, imageData: makeImageData(color: .systemGreen, size: dataSize), rating: 5)
        let breadD = Bread(name: "D", category: .toast, imageData: makeImageData(color: .systemOrange, size: dataSize), rating: 5)

        [breadA, breadB].forEach { bread in
            XCTAssertNotNil(service.image(for: bread))
            XCTAssertNotNil(service.image(for: bread))
            XCTAssertNotNil(service.image(for: bread))
        }

        // probationary를 채운 후 C 승격에서 protected overflow -> demotion + probationary trim 유도
        XCTAssertNotNil(service.image(for: breadD))
        XCTAssertNotNil(service.image(for: breadC))
        XCTAssertNotNil(service.image(for: breadC))
        XCTAssertNotNil(service.image(for: breadC))

        XCTAssertNil(service.metrics(forKey: breadD.imageCacheKey))
        XCTAssertEqual(service.metrics(forKey: breadA.imageCacheKey)?.segment, .probationary)
        XCTAssertEqual(service.metrics(forKey: breadB.imageCacheKey)?.segment, .protected)
        XCTAssertEqual(service.metrics(forKey: breadC.imageCacheKey)?.segment, .protected)
    }

    func test_ImageCache_probationaryLRUEvictionOrderWhenOverLimit() {
        let dataSize = CGSize(width: 40, height: 40)
        let unitCost = decodedCost(for: makeImageData(color: .systemPurple, size: dataSize))
        let service = ImageCacheService(
            totalCostLimit: unitCost * 7,
            protectedFraction: 0.7,
            promotionHitThreshold: 99
        )

        let breadA = Bread(name: "A", category: .toast, imageData: makeImageData(color: .systemPurple, size: dataSize), rating: 3)
        let breadB = Bread(name: "B", category: .toast, imageData: makeImageData(color: .systemOrange, size: dataSize), rating: 3)
        let breadC = Bread(name: "C", category: .toast, imageData: makeImageData(color: .systemPink, size: dataSize), rating: 3)

        XCTAssertNotNil(service.image(for: breadA))
        XCTAssertNotNil(service.image(for: breadB))
        XCTAssertNotNil(service.image(forKey: breadA.imageCacheKey, data: nil))
        XCTAssertNotNil(service.image(for: breadC))

        XCTAssertNil(service.metrics(forKey: breadB.imageCacheKey))
        XCTAssertNotNil(service.image(forKey: breadA.imageCacheKey, data: nil))
        XCTAssertNotNil(service.image(forKey: breadC.imageCacheKey, data: nil))
        XCTAssertNil(service.image(forKey: breadB.imageCacheKey, data: nil))
    }

    func test_ImageCacheKey_sha256VersionIsStableAndChangesOnByteMutation() {
        let sourceData = makeImageData(color: .systemBrown, size: CGSize(width: 16, height: 16))
        let bread = Bread(name: "해시 테스트", category: .toast, imageData: sourceData, rating: 2)

        let firstKey = bread.imageCacheKey
        let secondKey = bread.imageCacheKey
        XCTAssertEqual(firstKey, secondKey)

        let firstComponents = firstKey.split(separator: ":")
        XCTAssertEqual(firstComponents.count, 3)
        XCTAssertEqual(firstComponents[2].count, 64)

        bread.imageData = mutateFirstByte(in: sourceData)
        bread.updatedAt = Date().addingTimeInterval(1)
        let changedKey = bread.imageCacheKey

        XCTAssertNotEqual(firstKey, changedKey)
    }

    func test_ImageCache_invalidateRemovesEntryAndMetrics() {
        let service = ImageCacheService()
        let key = "invalidate-key"
        let data = makeImageData(color: .systemMint, size: CGSize(width: 12, height: 12))

        XCTAssertNotNil(service.image(forKey: key, data: data))
        XCTAssertNotNil(service.metrics(forKey: key))

        service.invalidate(forKey: key)

        XCTAssertNil(service.metrics(forKey: key))
        XCTAssertNil(service.image(forKey: key, data: nil))
    }

    func test_ImageCache_clearAllRemovesAllEntriesAndMetrics() {
        let service = ImageCacheService()
        let keyA = "clear-a"
        let keyB = "clear-b"

        XCTAssertNotNil(service.image(forKey: keyA, data: makeImageData(color: .systemCyan, size: CGSize(width: 12, height: 12))))
        XCTAssertNotNil(service.image(forKey: keyB, data: makeImageData(color: .systemYellow, size: CGSize(width: 12, height: 12))))
        XCTAssertFalse(service.snapshot().isEmpty)

        service.clearAll()

        XCTAssertTrue(service.snapshot().isEmpty)
        XCTAssertNil(service.image(forKey: keyA, data: nil))
        XCTAssertNil(service.image(forKey: keyB, data: nil))
    }

    func test_ImageCache_memoryWarningDropsProbationaryAndShrinksProtected() {
        let dataSize = CGSize(width: 48, height: 48)
        let unitCost = decodedCost(for: makeImageData(color: .systemRed, size: dataSize))
        let service = ImageCacheService(
            totalCostLimit: unitCost * 4,
            protectedFraction: 0.7,
            promotionHitThreshold: 2,
            registerMemoryWarningObserver: false
        )

        let breadA = Bread(name: "A", category: .toast, imageData: makeImageData(color: .systemRed, size: dataSize), rating: 5)
        let breadB = Bread(name: "B", category: .toast, imageData: makeImageData(color: .systemBlue, size: dataSize), rating: 5)
        let breadC = Bread(name: "C", category: .toast, imageData: makeImageData(color: .systemGreen, size: dataSize), rating: 5)

        [breadA, breadB].forEach { bread in
            XCTAssertNotNil(service.image(for: bread))
            XCTAssertNotNil(service.image(for: bread))
            XCTAssertNotNil(service.image(for: bread))
        }
        XCTAssertNotNil(service.image(for: breadC)) // probationary 잔류

        XCTAssertEqual(service.metrics(forKey: breadA.imageCacheKey)?.segment, .protected)
        XCTAssertEqual(service.metrics(forKey: breadB.imageCacheKey)?.segment, .protected)
        XCTAssertEqual(service.metrics(forKey: breadC.imageCacheKey)?.segment, .probationary)

        service.handleMemoryWarning()

        XCTAssertNil(service.metrics(forKey: breadC.imageCacheKey))
        XCTAssertNil(service.image(forKey: breadC.imageCacheKey, data: nil))
        XCTAssertNil(service.metrics(forKey: breadA.imageCacheKey))
        XCTAssertNil(service.image(forKey: breadA.imageCacheKey, data: nil))
        XCTAssertNotNil(service.metrics(forKey: breadB.imageCacheKey))
        XCTAssertNotNil(service.image(forKey: breadB.imageCacheKey, data: nil))
        XCTAssertEqual(service.metrics(forKey: breadB.imageCacheKey)?.segment, .protected)
    }

    func test_ImageCache_stress_repeatedChurnMaintainsMetricInvariants() {
        let service = ImageCacheService(
            totalCostLimit: 1_500_000,
            protectedFraction: 0.7,
            promotionHitThreshold: 2,
            registerMemoryWarningObserver: false
        )

        let entries: [(key: String, data: Data)] = (0..<24).map { index in
            let color = UIColor(
                hue: CGFloat(index) / 24.0,
                saturation: 0.8,
                brightness: 0.9,
                alpha: 1
            )
            return (
                key: "stress-\(index)",
                data: makeImageData(color: color, size: CGSize(width: 28, height: 28))
            )
        }

        for step in 0..<5_000 {
            let entry = entries[step % entries.count]

            if step % 53 == 0 {
                service.invalidate(forKey: entry.key)
            }

            if step % 997 == 0 {
                service.clearAll()
            }

            if step % 4 == 0 {
                _ = service.image(forKey: entry.key, data: nil)
            } else {
                _ = service.image(forKey: entry.key, data: entry.data)
            }
        }

        let snapshot = service.snapshot()
        XCTAssertFalse(snapshot.isEmpty)
        for metrics in snapshot.values {
            XCTAssertEqual(metrics.requestCount, metrics.hitCount + metrics.missCount)
            XCTAssertGreaterThan(metrics.requestCount, 0)
        }
    }

    func test_ImageCache_stress_manyUniqueKeysRemainBoundedByBudget() {
        let unitData = makeImageData(color: .systemPurple, size: CGSize(width: 32, height: 32))
        let unitCost = decodedCost(for: unitData)
        let service = ImageCacheService(
            totalCostLimit: unitCost * 6,
            protectedFraction: 0.7,
            promotionHitThreshold: 99,
            registerMemoryWarningObserver: false
        )

        for index in 0..<50 {
            let color = UIColor(
                hue: CGFloat(index % 50) / 50.0,
                saturation: 0.7,
                brightness: 0.85,
                alpha: 1
            )
            let data = makeImageData(color: color, size: CGSize(width: 32, height: 32))
            _ = service.image(forKey: "bulk-\(index)", data: data)
        }

        let snapshot = service.snapshot()
        XCTAssertLessThanOrEqual(snapshot.count, 2)
        XCTAssertNotNil(service.metrics(forKey: "bulk-49"))
        XCTAssertNil(service.metrics(forKey: "bulk-0"))
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Bakery.self,
            Bread.self,
            configurations: configuration
        )
    }

    private func makeImageData(color: UIColor, size: CGSize = CGSize(width: 8, height: 8)) -> Data {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        guard let data = image.pngData() else {
            XCTFail("테스트용 PNG 데이터 생성 실패")
            return Data()
        }

        return data
    }

    private func decodedCost(for data: Data) -> Int {
        guard let image = UIImage(data: data) else {
            XCTFail("디코딩 비용 계산용 이미지 생성 실패")
            return 1
        }

        if let cgImage = image.cgImage {
            let cgCost = cgImage.bytesPerRow * cgImage.height
            if cgCost > 0 {
                return cgCost
            }
        }

        let pixelWidth = Int(image.size.width * image.scale)
        let pixelHeight = Int(image.size.height * image.scale)
        let rgbaCost = pixelWidth * pixelHeight * 4
        return max(rgbaCost, data.count, 1)
    }

    private func mutateFirstByte(in data: Data) -> Data {
        guard !data.isEmpty else {
            return Data([0xFF])
        }

        var copied = data
        copied[copied.startIndex] = copied[copied.startIndex] ^ 0xFF
        return copied
    }
}
