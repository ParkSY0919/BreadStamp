import SwiftUI
import SwiftData

struct BreadCard: View {
    // MARK: - Properties
    let bread: Bread

    // MARK: - Body
    var body: some View {
        HStack(spacing: Spacing.md) {
            breadImage

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(bread.name)
                        .font(.appBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    if let bakery = bread.bakery {
                        Text(bakery.name)
                            .font(.appCaption)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                    }
                }

                ratingRow

                HStack(spacing: Spacing.sm) {
                    categoryBadge

                    if let memo = bread.memo, !memo.isEmpty {
                        Text(memo)
                            .font(.appCaption)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadowSm()
    }

    // MARK: - Views
    @ViewBuilder
    private var breadImage: some View {
        if let imageData = bread.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.brandSecondary.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: "birthday.cake.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.brandSecondary)
            }
        }
    }

    private var ratingRow: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= bread.rating ? "star.fill" : "star")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.brandAccent)
            }
        }
    }

    private var categoryBadge: some View {
        Text("\(bread.category.icon) \(bread.category.displayName)")
            .font(.appCaption)
            .foregroundStyle(Color.brandPrimary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 2)
            .background(Color.brandPrimary.opacity(0.1))
            .cornerRadius(CornerRadius.xs)
    }
}

// MARK: - Preview
#Preview {
    BreadCard(bread: Bread(name: "크루아상", category: .croissant, rating: 5))
        .padding()
        .background(Color.appBackground)
        .modelContainer(for: [Bakery.self, Bread.self], inMemory: true)
}
