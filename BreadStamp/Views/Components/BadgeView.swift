import SwiftUI

struct BadgeView: View {
    // MARK: - Properties
    let achievement: Achievement
    @State private var showGuide = false

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
        .onTapGesture {
            showGuide = true
        }
        .sheet(isPresented: $showGuide) {
            AchievementGuideSheet(achievement: achievement)
                .presentationDetents([.medium])
        }
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

// MARK: - Achievement Guide Sheet
struct AchievementGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    let achievement: Achievement

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    ZStack {
                        Circle()
                            .fill(achievement.isUnlocked ? Color.brandPrimary : Color.gray.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: achievement.iconName)
                            .font(.system(size: 44))
                            .foregroundStyle(achievement.isUnlocked ? .white : Color.textSecondary)
                    }

                    VStack(spacing: Spacing.sm) {
                        Text(achievement.title)
                            .font(.appLargeTitle)
                            .foregroundStyle(Color.textPrimary)

                        Text(achievement.description)
                            .font(.appBody)
                            .foregroundStyle(Color.textSecondary)
                    }

                    if achievement.isUnlocked {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.success)
                            Text("달성 완료!")
                                .font(.appHeadline)
                                .foregroundStyle(Color.success)
                        }
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(Color.success.opacity(0.1))
                        )
                    } else {
                        VStack(spacing: Spacing.sm) {
                            Text("달성 가이드")
                                .font(.appHeadline)
                                .foregroundStyle(Color.textPrimary)

                            Text(achievement.guide)
                                .font(.appBody)
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(Spacing.lg)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(Color.surface)
                        )
                    }

                    Spacer()
                }
                .padding(Spacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(Color.brandPrimary)
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
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
