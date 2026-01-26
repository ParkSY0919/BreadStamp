import SwiftUI
import SwiftData

struct BakeryDetailView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BakeryViewModel()
    @State private var breadViewModel = BreadViewModel()

    let bakery: Bakery

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    statistics
                    breadSection
                }
                .padding(Spacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $breadViewModel.showAddSheet) {
            AddBreadSheet(bakery: bakery)
        }
        .alert("빵집 삭제", isPresented: $viewModel.showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                if let bakeryToDelete = viewModel.bakeryToDelete {
                    viewModel.deleteBakery(bakeryToDelete, context: modelContext)
                    dismiss()
                }
            }
        } message: {
            Text("이 빵집을 삭제하시겠습니까? 관련된 빵 기록도 모두 삭제됩니다.")
        }
    }

    // MARK: - Views
    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let imageData = bakery.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }

            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(bakery.name)
                        .font(.appLargeTitle)
                        .foregroundStyle(Color.textPrimary)

                    Text(bakery.address)
                        .font(.appSubhead)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)

                    Text(bakery.visitedAt, style: .date)
                        .font(.appFootnote)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Button {
                    viewModel.toggleFavorite(bakery, context: modelContext)
                } label: {
                    Image(systemName: bakery.isFavorite ? "heart.fill" : "heart")
                        .font(.appTitle)
                        .foregroundStyle(bakery.isFavorite ? Color.brandAccent : Color.textSecondary)
                }
            }

            if let memo = bakery.memo, !memo.isEmpty {
                Text(memo)
                    .font(.appBody)
                    .foregroundStyle(Color.textPrimary)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.md)
            }
        }
    }

    private var statistics: some View {
        HStack(spacing: Spacing.lg) {
            statisticsItem(
                icon: "basket.fill",
                title: "기록한 빵",
                value: "\(bakery.breadCount)개"
            )

            Divider()
                .frame(height: 40)

            statisticsItem(
                icon: "star.fill",
                title: "평균 평점",
                value: bakery.breadCount > 0 ? String(format: "%.1f", bakery.averageRating) : "-"
            )
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadowMd()
    }

    private func statisticsItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.appTitle)
                .foregroundStyle(Color.brandPrimary)

            Text(title)
                .font(.appCaption)
                .foregroundStyle(Color.textSecondary)

            Text(value)
                .font(.appHeadline)
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    private var breadSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("기록한 빵")
                    .font(.appHeadline)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Button {
                    breadViewModel.showAddSheet = true
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                        Text("추가")
                    }
                    .font(.appCallout)
                    .foregroundStyle(Color.brandPrimary)
                }
            }

            if bakery.breads.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.textSecondary.opacity(0.5))

                    Text("아직 기록한 빵이 없어요")
                        .font(.appCallout)
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xxl)
                .background(Color.surface)
                .cornerRadius(CornerRadius.md)
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(bakery.breads.sorted(by: { $0.eatenAt > $1.eatenAt })) { bread in
                        BreadCard(bread: bread)
                            .contextMenu {
                                Button(role: .destructive) {
                                    breadViewModel.deleteBread(bread, context: modelContext)
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    // TODO: 편집 기능 구현
                } label: {
                    Label("편집", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    viewModel.bakeryToDelete = bakery
                    viewModel.showDeleteAlert = true
                } label: {
                    Label("삭제", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(Color.textPrimary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        BakeryDetailView(bakery: Bakery(
            name: "행복한 빵집",
            address: "서울시 강남구 테헤란로 123",
            memo: "크루아상이 정말 맛있어요!"
        ))
    }
    .modelContainer(for: [Bakery.self, Bread.self], inMemory: true)
}
