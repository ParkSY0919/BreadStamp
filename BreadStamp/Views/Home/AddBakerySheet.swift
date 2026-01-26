import SwiftUI
import SwiftData

struct AddBakerySheet: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = BakeryViewModel()

    @State private var name = ""
    @State private var address = ""
    @State private var memo = ""

    // MARK: - Computed Properties
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
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
            context: modelContext
        )

        dismiss()
    }
}

#Preview {
    AddBakerySheet()
        .modelContainer(for: [Bakery.self, Bread.self], inMemory: true)
}
