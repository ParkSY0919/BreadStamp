import SwiftUI

struct EmptyStateView: View {
    // MARK: - Properties
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    // MARK: - Initializer
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.lg) {
                iconView

                VStack(spacing: Spacing.sm) {
                    Text(title)
                        .font(.appTitle)
                        .foregroundStyle(Color.textPrimary)

                    Text(message)
                        .font(.appBody)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }

            if let actionTitle = actionTitle, let action = action {
                actionButton(title: actionTitle, action: action)
            }
        }
        .padding(.horizontal, Spacing.xxl)
    }

    // MARK: - Views
    private var iconView: some View {
        Image(systemName: icon)
            .font(.system(size: 64))
            .foregroundStyle(Color.textSecondary.opacity(0.5))
    }

    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.appHeadline)
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(Color.brandPrimary)
                .cornerRadius(CornerRadius.md)
        }
    }
}

// MARK: - Preview
#Preview("With Action") {
    EmptyStateView(
        icon: "building.2.fill",
        title: "아직 방문한 빵집이 없어요",
        message: "첫 번째 빵집을 추가하고\n스탬프 수집을 시작해보세요!",
        actionTitle: "빵집 추가하기",
        action: { print("Add bakery tapped") }
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}

#Preview("Without Action") {
    EmptyStateView(
        icon: "birthday.cake.fill",
        title: "빵 도감이 비어있어요",
        message: "빵집을 방문하고\n맛있는 빵을 기록해보세요!"
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}

#Preview("Map Empty") {
    EmptyStateView(
        icon: "map.fill",
        title: "근처에 빵집이 없어요",
        message: "새로운 빵집을 발견하면\n지도에 표시됩니다",
        actionTitle: "빵집 찾아보기",
        action: { print("Search bakery tapped") }
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}

#Preview("Achievement Empty") {
    EmptyStateView(
        icon: "trophy.fill",
        title: "업적을 달성해보세요",
        message: "빵집을 탐방하고 빵을 수집하면\n다양한 업적을 획득할 수 있어요!"
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}

#Preview("All Empty States") {
    TabView {
        EmptyStateView(
            icon: "building.2.fill",
            title: "빵집 없음",
            message: "첫 빵집을 추가해보세요",
            actionTitle: "추가하기",
            action: {}
        )
        .tabItem { Label("스탬프북", systemImage: "book.fill") }

        EmptyStateView(
            icon: "birthday.cake.fill",
            title: "빵 도감 비어있음",
            message: "빵을 수집해보세요"
        )
        .tabItem { Label("도감", systemImage: "square.grid.2x2.fill") }

        EmptyStateView(
            icon: "map.fill",
            title: "지도 비어있음",
            message: "빵집이 표시됩니다"
        )
        .tabItem { Label("지도", systemImage: "map.fill") }
    }
    .background(Color.appBackground)
}
