import SwiftUI

struct BadgeView: View {
    // MARK: - Properties
    let achievement: Achievement

    private var isLocked: Bool {
        !achievement.isUnlocked
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: Spacing.sm) {
            badgeIcon

            Text(achievement.title)
                .font(.appCaption)
                .foregroundStyle(isLocked ? Color.textSecondary : Color.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
        .opacity(isLocked ? 0.5 : 1.0)
    }

    // MARK: - Views
    private var badgeIcon: some View {
        ZStack {
            Circle()
                .fill(isLocked ? Color.gray.opacity(0.2) : Color.brandPrimary)
                .frame(width: 64, height: 64)

            Image(systemName: achievement.iconName)
                .font(.system(size: 28))
                .foregroundStyle(isLocked ? Color.textSecondary : .white)
        }
    }
}

// MARK: - Preview
#Preview("Unlocked") {
    let achievement = Achievement(
        id: "first_stamp",
        title: "첫 발걸음",
        description: "첫 번째 빵집 방문",
        iconName: "flag.fill",
        requirement: .bakeryCount(1),
        unlockedAt: Date()
    )

    HStack(spacing: Spacing.lg) {
        BadgeView(achievement: achievement)
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Locked") {
    let achievement = Achievement(
        id: "stamp_10",
        title: "빵집 수집가",
        description: "10개의 빵집 방문",
        iconName: "trophy.fill",
        requirement: .bakeryCount(10)
    )

    HStack(spacing: Spacing.lg) {
        BadgeView(achievement: achievement)
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Grid") {
    ScrollView {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: Spacing.lg
        ) {
            ForEach(Achievement.allAchievements) { achievement in
                BadgeView(achievement: achievement)
            }
        }
        .padding()
    }
    .background(Color.appBackground)
}
