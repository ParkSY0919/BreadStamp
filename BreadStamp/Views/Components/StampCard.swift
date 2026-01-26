import SwiftUI
import SwiftData

struct StampCard: View {
    // MARK: - Properties
    let bakery: Bakery

    // MARK: - Body
    var body: some View {
        VStack(spacing: Spacing.sm) {
            stampImage

            VStack(spacing: Spacing.xs) {
                Text(bakery.name)
                    .font(.appFootnote)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)

                if bakery.breadCount > 0 {
                    ratingView
                }
            }
        }
        .frame(width: 140, height: 160)
        .padding(Spacing.sm)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
        .shadowSm()
        .overlay(alignment: .topTrailing) {
            if bakery.isFavorite {
                favoriteIcon
            }
        }
    }

    // MARK: - Views
    @ViewBuilder
    private var stampImage: some View {
        if let firstBread = bakery.breads.first,
           let imageData = firstBread.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "building.2.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.brandPrimary)
            }
        }
    }

    private var ratingView: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.brandAccent)

            Text(String(format: "%.1f", bakery.averageRating))
                .font(.appCaption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var favoriteIcon: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 16))
            .foregroundStyle(Color.error)
            .padding(Spacing.xs)
            .background(Color.surface)
            .clipShape(Circle())
            .shadowSm()
            .padding(Spacing.xs)
    }
}

// MARK: - Preview
#Preview {
    StampCard(bakery: Bakery(name: "행복한 베이커리", address: "서울시 강남구"))
        .padding()
        .background(Color.appBackground)
        .modelContainer(for: [Bakery.self, Bread.self], inMemory: true)
}
