import SwiftUI
import SwiftData
import PhotosUI

struct AddBakerySheet: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = BakeryViewModel()

    @State private var name = ""
    @State private var address = ""
    @State private var memo = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?

    // MARK: - Computed Properties
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    photoSection
                } header: {
                    Text("사진 (선택)")
                        .font(.appCaption)
                        .foregroundStyle(Color.textSecondary)
                }

                Section {
                    TextField("빵집 이름", text: $name)
                        .font(.appBody)
                } header: {
                    Text("이름")
                        .font(.appCaption)
                        .foregroundStyle(Color.textSecondary)
                }

                Section {
                    TextField("주소", text: $address)
                        .font(.appBody)
                } header: {
                    Text("주소")
                        .font(.appCaption)
                        .foregroundStyle(Color.textSecondary)
                }

                Section {
                    TextEditor(text: $memo)
                        .font(.appBody)
                        .frame(minHeight: 100)
                } header: {
                    Text("메모 (선택)")
                        .font(.appCaption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .navigationTitle("새 빵집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(Color.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        addBakery()
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Views
    private var photoSection: some View {
        VStack(spacing: Spacing.md) {
            if let imageData,
               let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                    Button {
                        self.imageData = nil
                        self.selectedItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(Spacing.sm)
                }
            }

            PhotosPicker(
                selection: $selectedItem,
                matching: .images
            ) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: imageData == nil ? "photo.badge.plus" : "photo.fill")
                        .font(.appBody)
                    Text(imageData == nil ? "사진 선택" : "사진 변경")
                        .font(.appBody)
                }
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.brandPrimary.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            imageData = data
                        }
                    }
                }
            }
        }
    }

    // MARK: - Methods
    private func addBakery() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedAddress = address.trimmingCharacters(in: .whitespaces)
        let trimmedMemo = memo.trimmingCharacters(in: .whitespaces)

        viewModel.addBakery(
            name: trimmedName,
            address: trimmedAddress,
            latitude: 0,
            longitude: 0,
            memo: trimmedMemo.isEmpty ? nil : trimmedMemo,
            imageData: imageData,
            context: modelContext
        )

        dismiss()
    }
}

#Preview {
    AddBakerySheet()
        .modelContainer(for: [Bakery.self, Bread.self], inMemory: true)
}
