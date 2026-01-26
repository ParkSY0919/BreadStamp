import SwiftUI
import SwiftData
import PhotosUI
import MapKit

struct AddBakerySheet: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = BakeryViewModel()

    @State private var name = ""
    @State private var memo = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?

    // 주소 검색 관련
    @State private var addressQuery = ""
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var selectedAddress = ""
    @State private var selectedLatitude: Double = 0
    @State private var selectedLongitude: Double = 0
    @State private var searchCompleter = AddressSearchCompleter()

    // MARK: - Computed Properties
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    photoSection
                    nameSection
                    addressSection
                    memoSection

                    // 키보드가 올라올 때 하단 여백 확보
                    Color.clear
                        .frame(height: 120)
                }
                .padding(Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appBackground)
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
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
        }
        .onAppear {
            searchCompleter.onUpdate = { completions in
                searchResults = completions
            }
        }
    }

    // MARK: - Views
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("사진", required: false)

            VStack(spacing: Spacing.md) {
                if let imageData,
                   let uiImage = UIImage(data: imageData) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
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
                            await MainActor.run { imageData = data }
                        }
                    }
                }
            }
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("빵집 이름", required: true)

            TextField("빵집 이름을 입력해주세요", text: $name)
                .font(.appBody)
                .padding(Spacing.md)
                .background(Color.surface)
                .cornerRadius(CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color.divider, lineWidth: 1)
                )
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("주소", required: false)

            // 선택된 주소 표시
            if !selectedAddress.isEmpty {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color.brandAccent)
                    Text(selectedAddress)
                        .font(.appSubhead)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)

                    Spacer()

                    Button {
                        selectedAddress = ""
                        selectedLatitude = 0
                        selectedLongitude = 0
                        addressQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .padding(Spacing.md)
                .background(Color.success.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }

            // 주소 검색 필드
            if selectedAddress.isEmpty {
                TextField("주소를 검색해주세요", text: $addressQuery)
                    .font(.appBody)
                    .padding(Spacing.md)
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .stroke(Color.divider, lineWidth: 1)
                    )
                    .onChange(of: addressQuery) { _, newValue in
                        if newValue.count >= 2 {
                            searchCompleter.search(query: newValue)
                        } else {
                            searchResults = []
                        }
                    }

                // 검색 결과 리스트
                if !searchResults.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(searchResults.prefix(5), id: \.self) { result in
                            Button {
                                selectSearchResult(result)
                            } label: {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundStyle(Color.brandPrimary)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.title)
                                            .font(.appSubhead)
                                            .foregroundStyle(Color.textPrimary)
                                            .lineLimit(1)

                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle)
                                                .font(.appCaption)
                                                .foregroundStyle(Color.textSecondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, Spacing.sm)
                                .padding(.horizontal, Spacing.md)
                            }

                            if result != searchResults.prefix(5).last {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                    .background(Color.surface)
                    .cornerRadius(CornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .stroke(Color.divider, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("메모", required: false)

            TextEditor(text: $memo)
                .font(.appBody)
                .frame(minHeight: 100)
                .padding(Spacing.sm)
                .background(Color.surface)
                .cornerRadius(CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color.divider, lineWidth: 1)
                )
                .scrollContentBackground(.hidden)
        }
    }

    private func sectionHeader(_ title: String, required: Bool) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(title)
                .font(.appFootnote)
                .fontWeight(.medium)
                .foregroundStyle(Color.textSecondary)
            if required {
                Text("*")
                    .font(.appFootnote)
                    .foregroundStyle(Color.brandAccent)
            }
        }
    }

    // MARK: - Methods
    private func selectSearchResult(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)

        Task {
            do {
                let response = try await search.start()
                if let mapItem = response.mapItems.first {
                    await MainActor.run {
                        selectedAddress = [result.title, result.subtitle]
                            .filter { !$0.isEmpty }
                            .joined(separator: " ")
                        selectedLatitude = mapItem.placemark.coordinate.latitude
                        selectedLongitude = mapItem.placemark.coordinate.longitude
                        addressQuery = ""
                        searchResults = []
                    }
                }
            } catch {
                await MainActor.run {
                    selectedAddress = result.title
                    addressQuery = ""
                    searchResults = []
                }
            }
        }
    }

    private func addBakery() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedMemo = memo.trimmingCharacters(in: .whitespaces)

        viewModel.addBakery(
            name: trimmedName,
            address: selectedAddress,
            latitude: selectedLatitude,
            longitude: selectedLongitude,
            memo: trimmedMemo.isEmpty ? nil : trimmedMemo,
            imageData: imageData,
            context: modelContext
        )

        dismiss()
    }
}

// MARK: - Address Search Completer
/// MKLocalSearchCompleter 래퍼 + 300ms Debounce
///
/// Debounce 적용 이유:
/// - MKLocalSearchCompleter는 queryFragment 변경마다 Apple 서버에 네트워크 요청 발생
/// - 사용자가 "서울시 강남구"를 입력할 때 매 글자마다 요청하면 7회 호출
/// - 300ms debounce 적용 시 타이핑 완료 후 1회만 호출 → 네트워크 비용 ~85% 절감
/// - Apple Geocoding API는 rate limit(분당 50회)이 있어 과도한 호출 시 실패 가능
@Observable
final class AddressSearchCompleter: NSObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()
    var onUpdate: (([MKLocalSearchCompletion]) -> Void)?
    private var debounceTask: Task<Void, Never>?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        )
    }

    func search(query: String) {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            completer.queryFragment = query
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate?(completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // 검색 실패 시 무시 (네트워크 불안정 등)
    }
}

#Preview {
    AddBakerySheet()
        .modelContainer(for: [Bakery.self, Bread.self], inMemory: true)
}
