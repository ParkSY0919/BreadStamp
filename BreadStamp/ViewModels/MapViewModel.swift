import SwiftUI
import MapKit
import CoreLocation

@Observable
final class MapViewModel {
    // MARK: - State

    /// 지도 영역 (기본값: 서울)
    var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 37.5665, // 서울 위도
            longitude: 126.9780 // 서울 경도
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.05,
            longitudeDelta: 0.05
        )
    )

    /// 선택된 빵집
    var selectedBakery: Bakery?

    // MARK: - Methods

    /// 지도 영역 업데이트
    func updateRegion(center: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: 0.05,
                longitudeDelta: 0.05
            )
        )
    }

    /// 빵집 선택
    func selectBakery(_ bakery: Bakery?) {
        selectedBakery = bakery

        if let bakery = bakery {
            // 선택된 빵집 위치로 지도 이동
            updateRegion(
                center: CLLocationCoordinate2D(
                    latitude: bakery.latitude,
                    longitude: bakery.longitude
                )
            )
        }
    }
}
