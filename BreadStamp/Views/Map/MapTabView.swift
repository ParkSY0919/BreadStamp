import SwiftUI
import SwiftData
import MapKit

struct MapTabView: View {
    // MARK: - Properties
    @Query private var bakeries: [Bakery]
    @State private var locationManager = LocationManager()

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    private var validBakeries: [Bakery] {
        bakeries.filter { $0.latitude != 0 && $0.longitude != 0 }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                mapView
            }
            .navigationTitle("지도")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            locationManager.requestPermission()
        }
    }

    // MARK: - Views
    private var mapView: some View {
        ZStack {
            if validBakeries.isEmpty {
                EmptyStateView(
                    icon: "map.fill",
                    title: "지도에 표시할 빵집이 없어요",
                    message: "빵집을 추가하고 위치를 설정해보세요!"
                )
            } else {
                Map(position: $cameraPosition) {
                    ForEach(validBakeries) { bakery in
                        Marker(
                            bakery.name,
                            systemImage: "building.2.fill",
                            coordinate: CLLocationCoordinate2D(
                                latitude: bakery.latitude,
                                longitude: bakery.longitude
                            )
                        )
                        .tint(bakery.isFavorite ? Color.brandAccent : Color.brandPrimary)
                    }

                    UserAnnotation()
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .overlay(alignment: .topLeading) {
                    if !validBakeries.isEmpty {
                        Text("빵집 \(validBakeries.count)곳")
                            .font(.appCaption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textPrimary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(.ultraThinMaterial)
                            .cornerRadius(CornerRadius.sm)
                            .padding(Spacing.md)
                    }
                }
                .onAppear {
                    updateCameraPosition()
                }
                .onChange(of: validBakeries.count) { _, _ in
                    updateCameraPosition()
                }
            }
        }
    }

    // MARK: - Methods
    private func updateCameraPosition() {
        guard !validBakeries.isEmpty else { return }

        if validBakeries.count == 1 {
            let bakery = validBakeries[0]
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: bakery.latitude, longitude: bakery.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        } else {
            var minLat = validBakeries[0].latitude
            var maxLat = validBakeries[0].latitude
            var minLon = validBakeries[0].longitude
            var maxLon = validBakeries[0].longitude

            for bakery in validBakeries {
                minLat = min(minLat, bakery.latitude)
                maxLat = max(maxLat, bakery.latitude)
                minLon = min(minLon, bakery.longitude)
                maxLon = max(maxLon, bakery.longitude)
            }

            let centerLat = (minLat + maxLat) / 2
            let centerLon = (minLon + maxLon) / 2
            let spanLat = (maxLat - minLat) * 1.5
            let spanLon = (maxLon - minLon) * 1.5

            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                    span: MKCoordinateSpan(latitudeDelta: max(spanLat, 0.02), longitudeDelta: max(spanLon, 0.02))
                )
            )
        }
    }
}

#Preview {
    MapTabView()
        .modelContainer(for: [Bakery.self], inMemory: true)
}
