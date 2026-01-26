import SwiftUI
import SwiftData

struct ProfileView: View {
    // MARK: - Properties
    @Query private var bakeries: [Bakery]
    @Query private var breads: [Bread]

    private var stats: StatisticsService.Stats {
        StatisticsService.calculate(bakeries: bakeries, breads: breads)
    }

    private var achievements: [Achievement] {
        let fiveStarCount = breads.filter { $0.rating == 5 }.count
        let current = AchievementService.checkAchievements(
            bakeryCount: stats.totalBakeries,
            breadCount: stats.totalBreads,
            categories: Set(stats.categoryCounts.keys),
            fiveStarCount: fiveStarCount,
            current: Achievement.allAchievements
        )
        return current
    }

    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    private let badgeColumns = Array(repeating: GridItem(.flexible()), count: 4)

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    profileHeader
                    statisticsSection
                    categoryBreakdownSection
                    achievementsSection
                }
                .padding(.vertical, Spacing.xl)
            }
            .background(Color.appBackground)
            .navigationTitle("프로필")
        }
    }

    // MARK: - Views
    private var profileHeader: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.brandPrimary)

            Text("빵 탐험가")
                .font(.appTitle)
                .foregroundStyle(Color.textPrimary)

            Text("총 \(stats.totalBakeries)개의 빵집 방문")
                .font(.appCallout)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.vertical, Spacing.md)
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("통계")
                .font(.appHeadline)
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, Spacing.lg)

            VStack(spacing: Spacing.md) {
                statCard(
                    icon: "building.2.fill",
                    title: "방문한 빵집",
                    value: "\(stats.totalBakeries)",
                    color: .brandPrimary
                )

                statCard(
                    icon: "birthday.cake.fill",
                    title: "먹은 빵",
                    value: "\(stats.totalBreads)",
                    color: .brandSecondary
                )

                statCard(
                    icon: "heart.fill",
                    title: "즐겨찾기",
                    value: "\(stats.favoriteBakeries)",
                    color: .brandAccent
                )

                statCard(
                    icon: "star.fill",
                    title: "평균 평점",
                    value: String(format: "%.1f", stats.averageRating),
                    color: .brandAccent
                )
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    private func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.appTitle)
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.appSubhead)
                    .foregroundStyle(Color.textSecondary)

                Text(value)
                    .font(.appTitle)
                    .foregroundStyle(Color.textPrimary)
                    .fontWeight(.bold)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.surface)
                .shadowSm()
        )
    }

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("카테고리별 빵")
                    .font(.appHeadline)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                if let topCategory = stats.topCategory {
                    Text("최애: \(topCategory.icon) \(topCategory.displayName)")
                        .font(.appCaption)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(Color.brandPrimary.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, Spacing.lg)

            if stats.categoryCounts.isEmpty {
                Text("아직 기록된 빵이 없어요")
                    .font(.appBody)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, Spacing.lg)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(BreadCategory.allCases, id: \.self) { category in
                        let count = stats.categoryCounts[category] ?? 0
                        if count > 0 {
                            categoryRow(category: category, count: count, total: stats.totalBreads)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
    }

    private func categoryRow(category: BreadCategory, count: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("\(category.icon) \(category.displayName)")
                    .font(.appBody)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Text("\(count)개")
                    .font(.appCallout)
                    .foregroundStyle(Color.textSecondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color.divider)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color.brandPrimary)
                        .frame(width: geometry.size.width * CGFloat(count) / CGFloat(total), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("업적")
                    .font(.appHeadline)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Text("\(unlockedCount)/\(achievements.count) 달성")
                    .font(.appCaption)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.success.opacity(0.1))
                    )
            }
            .padding(.horizontal, Spacing.lg)

            LazyVGrid(columns: badgeColumns, spacing: Spacing.md) {
                ForEach(achievements) { achievement in
                    BadgeView(achievement: achievement)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [Bakery.self, Bread.self], inMemory: true)
}

