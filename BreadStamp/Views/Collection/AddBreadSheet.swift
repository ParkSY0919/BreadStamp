import SwiftUI
import SwiftData
import PhotosUI

struct AddBreadSheet: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var selectedCategory: BreadCategory = .toast
    @State private var rating: Int = 5
    @State private var memo = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?

    var bakery: Bakery?

    // MARK: - Body
    var body: some View {
        NavigationStack {
            form
                .navigationTitle("새 빵 기록")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("추가") {
                            addBread()
                        }
                        .disabled(name.isEmpty)
                    }
                }
                .background(Color.appBackground)
        }
    }

    // MARK: - Views
    private var form: some View {
        Form {
            Section {
                TextField("빵 이름", text: $name)
                    .font(.appBody)

                Picker("카테고리", selection: $selectedCategory) {
                    ForEach(BreadCategory.allCases, id: \.self) { category in
                        Text("\(category.icon) \(category.displayName)")
                            .tag(category)
                    }
                }
                .font(.appBody)
            }

            Section {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("평점")
                        .font(.appSubhead)
                        .foregroundStyle(Color.textSecondary)

                    HStack(spacing: Spacing.sm) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                withAnimation(.spring(duration: 0.2)) {
                                    rating = star
                                }
                            } label: {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.appTitle)
                                    .foregroundStyle(star <= rating ? Color.brandAccent : Color.divider)
                            }
                        }
                    }
                }
                .padding(.vertical, Spacing.xs)
            }

            Section {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo")
                            .foregroundStyle(Color.brandPrimary)
                        Text("사진 선택")
                            .font(.appBody)
                        Spacer()
                        if imageData != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.success)
                        }
                    }
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            await MainActor.run { imageData = data }
                        }
                    }
                }

                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                        .padding(.vertical, Spacing.sm)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("메모 (선택)")
                        .font(.appSubhead)
                        .foregroundStyle(Color.textSecondary)

                    TextEditor(text: $memo)
                        .font(.appBody)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .background(Color.surface)
                }
                .padding(.vertical, Spacing.xs)
            }

            if let bakery {
                Section {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundStyle(Color.brandPrimary)
                        Text(bakery.name)
                            .font(.appBody)
                    }
                } header: {
                    Text("방문한 빵집")
                }
            }
        }
    }

    // MARK: - Methods
    private func addBread() {
        let bread = Bread(
            name: name,
            category: selectedCategory,
            imageData: imageData,
            rating: rating,
            memo: memo.isEmpty ? nil : memo,
            bakery: bakery
        )

        modelContext.insert(bread)

        dismiss()
    }
}

#Preview {
    AddBreadSheet()
        .modelContainer(for: [Bread.self, Bakery.self], inMemory: true)
}

