import Foundation
import SwiftData

/// 더미 데이터를 생성하는 서비스 (첫 실행 시 샘플 데이터 삽입)
struct SampleDataService {

    static func insertSampleDataIfNeeded(context: ModelContext) {
        // 이미 데이터가 있으면 스킵
        let descriptor = FetchDescriptor<Bakery>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        let bakeries = createSampleBakeries()
        for bakery in bakeries {
            context.insert(bakery)
        }

        let breads = createSampleBreads(bakeries: bakeries)
        for bread in breads {
            context.insert(bread)
        }

        // 즐겨찾기 설정
        bakeries[0].isFavorite = true
        bakeries[2].isFavorite = true

        try? context.save()
    }

    // MARK: - Sample Bakeries (서울 실제 좌표)

    private static func createSampleBakeries() -> [Bakery] {
        let b1 = Bakery(
            name: "밀도",
            address: "서울 마포구 월드컵로1길 28",
            latitude: 37.5563,
            longitude: 126.9068,
            memo: "식빵이 정말 유명한 곳!"
        )

        let b2 = Bakery(
            name: "르뱅",
            address: "서울 성동구 서울숲2길 45",
            latitude: 37.5445,
            longitude: 127.0437,
            memo: "크루아상과 바게트가 맛있어요"
        )

        let b3 = Bakery(
            name: "오월의종",
            address: "서울 용산구 이태원로54길 5",
            latitude: 37.5349,
            longitude: 126.9948,
            memo: "앙버터가 유명한 빵집"
        )

        let b4 = Bakery(
            name: "나폴레옹 베이커리",
            address: "서울 서초구 서초대로78길 22",
            latitude: 37.4962,
            longitude: 127.0263,
            memo: nil
        )

        let b5 = Bakery(
            name: "태극당",
            address: "서울 중구 동호로24길 7",
            latitude: 37.5585,
            longitude: 127.0098,
            memo: "1946년부터 이어온 전통 빵집"
        )

        // 방문일 다르게 설정
        b1.visitedAt = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        b2.visitedAt = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        b3.visitedAt = Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        b4.visitedAt = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        b5.visitedAt = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()

        return [b1, b2, b3, b4, b5]
    }

    // MARK: - Sample Breads

    private static func createSampleBreads(bakeries: [Bakery]) -> [Bread] {
        var breads: [Bread] = []

        // 밀도 빵
        breads.append(Bread(name: "밀도 식빵", category: .toast, rating: 5, memo: "부드럽고 촉촉한 식빵", bakery: bakeries[0]))
        breads.append(Bread(name: "옥수수 식빵", category: .toast, rating: 4, bakery: bakeries[0]))

        // 르뱅 빵
        breads.append(Bread(name: "크루아상", category: .croissant, rating: 5, memo: "겉바속촉 완벽한 크루아상", bakery: bakeries[1]))
        breads.append(Bread(name: "올리브 치아바타", category: .other, rating: 4, bakery: bakeries[1]))
        breads.append(Bread(name: "에그타르트", category: .cake, rating: 4, bakery: bakeries[1]))

        // 오월의종 빵
        breads.append(Bread(name: "앙버터", category: .sweetBun, rating: 5, memo: "팥앙금과 버터의 조화!", bakery: bakeries[2]))
        breads.append(Bread(name: "소보로", category: .sweetBun, rating: 3, bakery: bakeries[2]))

        // 나폴레옹 베이커리 빵
        breads.append(Bread(name: "나폴레옹 파이", category: .cake, rating: 5, bakery: bakeries[3]))
        breads.append(Bread(name: "도넛", category: .donut, rating: 4, bakery: bakeries[3]))

        // 태극당 빵
        breads.append(Bread(name: "모카빵", category: .sweetBun, rating: 4, memo: "전통 모카빵의 정석", bakery: bakeries[4]))
        breads.append(Bread(name: "야채 샐러드빵", category: .other, rating: 3, bakery: bakeries[4]))
        breads.append(Bread(name: "단팥 도넛", category: .donut, rating: 5, bakery: bakeries[4]))

        // 먹은 날짜 분산
        for (index, bread) in breads.enumerated() {
            bread.eatenAt = Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date()
        }

        return breads
    }
}
