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
    private var hasReceivedLocation = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {
        hasReceivedLocation = false
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            guard !self.hasReceivedLocation else { return }
            self.hasReceivedLocation = true
            manager.stopUpdatingLocation()
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
                manager.startUpdatingLocation()
            }
            #endif
        }
    }
}
