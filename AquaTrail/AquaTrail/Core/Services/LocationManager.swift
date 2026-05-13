//
//  LocationManager.swift
//  AquaTrail
//

import CoreLocation
import Observation

@Observable
@MainActor
class LocationManager: NSObject {
    var cityName: String = "My Location"
    var userLocation: CLLocation?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in
            self.userLocation = location
            do {
                let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
                self.cityName = placemarks.first?.locality
                    ?? placemarks.first?.administrativeArea
                    ?? "My Location"
            } catch { }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            #if os(iOS)
            let status = manager.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            }
            #endif
        }
    }
}
