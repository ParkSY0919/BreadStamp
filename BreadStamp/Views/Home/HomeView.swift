import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bakery.visitedAt, order: .reverse)
    private var bakeries: [Bakery]
    @State private var viewModel = BakeryViewModel()

    // MARK: - Grid Configuration
    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: 3)

    // MARK: - Body
    var body: some View {
        NavigationStack {
            content
                .background(Color.appBackground)
                .navigationTitle("스탬프북")
                .toolbar { toolbarContent }
                .sheet(isPresented: $viewModel.showAddSheet) {
                    AddBakerySheet()
                }
        }
    }

    // MARK: - Views
    @ViewBuilder
    private var content: some View {
        if bakeries.isEmpty {
            emptyState
        } else {
            bakeryList
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "building.2.fill",
            title: "아직 방문한 빵집이 없어요",
            message: "첫 번째 빵집을 추가해보세요!",
            actionTitle: "빵집 추가하기"
        ) {
            viewModel.showAddSheet = true
        }
    }

    private var bakeryList: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(bakeries) { bakery in
                    NavigationLink {
                        BakeryDetailView(bakery: bakery)
                    } label: {
                        StampCard(bakery: bakery)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.lg)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(Color.brandPrimary)
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Bakery.self, Bread.self], inMemory: true)
}
