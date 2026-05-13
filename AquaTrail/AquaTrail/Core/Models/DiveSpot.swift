//
//  DiveSpot.swift
//  AquaTrail
//

import Foundation
import CoreLocation

struct DiveSpot: Decodable, Identifiable {
    let id: UUID
    let name: String
    let nameEn: String?
    let latitude: Double
    let longitude: Double
    let description: String?
    let maxDepth: Int?
    let difficulty: String?
    let photoUrl: String?
    let tags: String?
    let visibilitySummerM: Int?
    let visibilityWinterM: Int?
    let waterTempSurfaceC: Int?
    let waterTempBottomC: Int?
    let thermoclineDepthM: Int?
    let access: String?
    let infrastructure: String?
    let entryType: String?
    let minCertification: String?
    let minDives: Int?
    let drysuitRecommended: Bool?
    let bestSeason: String?

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, description, difficulty, access, infrastructure, tags
        case nameEn = "name_en"
        case maxDepth = "max_depth"
        case photoUrl = "photo_url"
        case visibilitySummerM = "visibility_summer_m"
        case visibilityWinterM = "visibility_winter_m"
        case waterTempSurfaceC = "water_temp_surface_c"
        case waterTempBottomC = "water_temp_bottom_c"
        case thermoclineDepthM = "thermocline_depth_m"
        case entryType = "entry_type"
        case minCertification = "min_certification"
        case minDives = "min_dives"
        case drysuitRecommended = "drysuit_recommended"
        case bestSeason = "best_season"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func distanceKm(from location: CLLocation?) -> Int? {
        guard let location else { return nil }
        let dest = CLLocation(latitude: latitude, longitude: longitude)
        return Int(location.distance(from: dest) / 1000)
    }
}
