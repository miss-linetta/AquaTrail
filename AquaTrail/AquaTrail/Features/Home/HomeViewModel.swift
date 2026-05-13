//
//  HomeViewModel.swift
//  AquaTrail
//

import SwiftUI
import CoreLocation
import Observation

@Observable
@MainActor
class HomeViewModel {
    private(set) var cityPhotoURL: URL?
    private(set) var weather: WeatherData?
    private(set) var diveSpots: [DiveSpot] = []

    let location = LocationManager()

    var sortedSpots: [DiveSpot] {
        diveSpots.sorted {
            ($0.distanceKm(from: location.userLocation) ?? Int.max) <
            ($1.distanceKm(from: location.userLocation) ?? Int.max)
        }
    }

    func start() {
        location.requestLocation()
    }

    func cityDidChange(_ city: String) {
        Task {
            cityPhotoURL = try? await UnsplashPhotoService.fetchPhotoURL(for: city)
        }
    }

    func locationDidChange(_ newLocation: CLLocation?) {
        guard let newLocation else { return }
        Task {
            weather = await WeatherService.fetch(
                latitude: newLocation.coordinate.latitude,
                longitude: newLocation.coordinate.longitude
            )
        }
    }

    func loadDiveSpots() async {
        diveSpots = (try? await DiveSpotService.fetchAll()) ?? []
    }
}
