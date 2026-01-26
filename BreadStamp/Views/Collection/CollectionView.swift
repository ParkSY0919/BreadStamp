import SwiftUI
import SwiftData

struct CollectionView: View {
    // MARK: - Properties
    @Query(sort: \Bread.eatenAt, order: .reverse)
    private var allBreads: [Bread]

    @State private var selectedCategory: BreadCategory?

    private var filteredBreads: [Bread] {
        guard let category = selectedCategory else { return allBreads }
        return allBreads.filter { $0.category == category }
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                content
            }
            .navigationTitle("빵 도감")
        }
    }

    // MARK: - Views
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            categoryPicker
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)

            if filteredBreads.isEmpty {
                EmptyStateView(
                    icon: "birthday.cake.fill",
                    title: "아직 기록된 빵이 없어요",
                    message: "빵집에서 먹은 빵을 기록해보세요!"
                )
            } else {
                breadList
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                categoryChip(title: "전체", category: nil, count: allBreads.count)

                ForEach(BreadCategory.allCases, id: \.self) { category in
                    let count = allBreads.filter { $0.category == category }.count
                    categoryChip(
                        title: "\(category.icon) \(category.displayName)",
                        category: category,
                        count: count
                    )
                }
            }
        }
    }

    private func categoryChip(title: String, category: BreadCategory?, count: Int) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.appCallout)
                Text("(\(count))")
                    .font(.appCaption)
            }
            .foregroundStyle(selectedCategory == category ? Color.white : Color.textPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.full)
                    .fill(selectedCategory == category ? Color.brandPrimary : Color.surface)
            )
        }
    }

    private var breadList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("총 \(filteredBreads.count)개의 빵")
                    .font(.appSubhead)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)

                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    ForEach(filteredBreads) { bread in
                        BreadCard(bread: bread)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
    }
}

#Preview {
    CollectionView()
        .modelContainer(for: [Bread.self, Bakery.self], inMemory: true)
}
