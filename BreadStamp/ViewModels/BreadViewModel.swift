import SwiftUI
import SwiftData

@Observable
final class BreadViewModel {
    // MARK: - State
    var isLoading = false
    var errorMessage: String?
    var showAddSheet = false

    // MARK: - Methods

    /// 빵 추가
    func addBread(
        name: String,
        category: BreadCategory,
        imageData: Data?,
        rating: Int,
        memo: String?,
        bakery: Bakery?,
        context: ModelContext
    ) {
        isLoading = true
        errorMessage = nil

        do {
            let bread = Bread(
                name: name,
                category: category,
                imageData: imageData,
                rating: rating,
                memo: memo,
                bakery: bakery
            )
            context.insert(bread)
            try context.save()
            showAddSheet = false
        } catch {
            errorMessage = "빵 추가에 실패했습니다."
        }

        isLoading = false
    }

    /// 빵 정보 수정
    func updateBread(
        _ bread: Bread,
        name: String,
        category: BreadCategory,
        imageData: Data?,
        rating: Int,
        memo: String?,
        context: ModelContext
    ) {
        isLoading = true
        errorMessage = nil

        do {
            bread.name = name
            bread.category = category
            bread.imageData = imageData
            bread.rating = rating
            bread.memo = memo
            bread.updatedAt = Date()
            try context.save()
        } catch {
            errorMessage = "빵 정보 수정에 실패했습니다."
        }

        isLoading = false
    }

    /// 빵 삭제
    func deleteBread(_ bread: Bread, context: ModelContext) {
        isLoading = true
        errorMessage = nil

        do {
            context.delete(bread)
            try context.save()
        } catch {
            errorMessage = "빵 삭제에 실패했습니다."
        }

        isLoading = false
    }
}
