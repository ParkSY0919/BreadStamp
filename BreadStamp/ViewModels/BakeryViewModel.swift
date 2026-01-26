import SwiftUI
import SwiftData

@Observable
final class BakeryViewModel {
    // MARK: - State
    var isLoading = false
    var errorMessage: String?
    var showAddSheet = false
    var showDeleteAlert = false
    var bakeryToDelete: Bakery?

    // MARK: - Methods

    /// 빵집 추가
    func addBakery(
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        memo: String?,
        imageData: Data?,
        context: ModelContext
    ) {
        isLoading = true
        errorMessage = nil

        do {
            let bakery = Bakery(
                name: name,
                address: address,
                latitude: latitude,
                longitude: longitude,
                memo: memo,
                imageData: imageData
            )
            context.insert(bakery)
            try context.save()
            showAddSheet = false
        } catch {
            errorMessage = "빵집 추가에 실패했습니다."
        }

        isLoading = false
    }

    /// 빵집 정보 수정
    func updateBakery(
        _ bakery: Bakery,
        name: String,
        address: String,
        memo: String?,
        context: ModelContext
    ) {
        isLoading = true
        errorMessage = nil

        do {
            bakery.name = name
            bakery.address = address
            bakery.memo = memo
            bakery.updatedAt = Date()
            try context.save()
        } catch {
            errorMessage = "빵집 정보 수정에 실패했습니다."
        }

        isLoading = false
    }

    /// 빵집 삭제
    func deleteBakery(_ bakery: Bakery, context: ModelContext) {
        isLoading = true
        errorMessage = nil

        do {
            context.delete(bakery)
            try context.save()
            showDeleteAlert = false
            bakeryToDelete = nil
        } catch {
            errorMessage = "빵집 삭제에 실패했습니다."
        }

        isLoading = false
    }

    /// 즐겨찾기 토글
    func toggleFavorite(_ bakery: Bakery, context: ModelContext) {
        do {
            bakery.isFavorite.toggle()
            bakery.updatedAt = Date()
            try context.save()
        } catch {
            errorMessage = "즐겨찾기 설정에 실패했습니다."
        }
    }
}
