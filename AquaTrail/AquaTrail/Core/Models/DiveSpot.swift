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
    let descriptionEn: String?
    let maxDepth: Int?
    let difficulty: String?
    let difficultyUk: String?
    let photoUrl: String?
    let tags: String?
    let visibilitySummerM: Int?
    let visibilityWinterM: Int?
    let waterTempSurfaceC: Int?
    let waterTempBottomC: Int?
    let thermoclineDepthM: Int?
    let access: String?
    let accessUk: String?
    let infrastructure: String?
    let infrastructureUk: String?
    let entryType: String?
    let entryTypeUk: String?
    let minCertification: String?
    let minDives: Int?
    let drysuitRecommended: Bool?
    let bestSeason: String?
    let bestSeasonUk: String?

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, description, difficulty, access, infrastructure, tags
        case nameEn = "name_en"
        case descriptionEn = "description_en"
        case difficultyUk = "difficulty_uk"
        case maxDepth = "max_depth"
        case photoUrl = "photo_url"
        case visibilitySummerM = "visibility_summer_m"
        case visibilityWinterM = "visibility_winter_m"
        case waterTempSurfaceC = "water_temp_surface_c"
        case waterTempBottomC = "water_temp_bottom_c"
        case thermoclineDepthM = "thermocline_depth_m"
        case accessUk = "access_uk"
        case infrastructureUk = "infrastructure_uk"
        case entryType = "entry_type"
        case entryTypeUk = "entry_type_uk"
        case minCertification = "min_certification"
        case minDives = "min_dives"
        case drysuitRecommended = "drysuit_recommended"
        case bestSeason = "best_season"
        case bestSeasonUk = "best_season_uk"
    }

    static var isAppEnglish: Bool {
        Bundle.main.preferredLocalizations.first == "en"
    }

    var localizedName: String {
        if Self.isAppEnglish {
            return nameEn ?? name
        }
        return name
    }

    var localizedDescription: String? {
        if Self.isAppEnglish {
            return descriptionEn ?? description
        }
        return description
    }

    private static let difficultyUkMap = [
        "beginner": "Початковий", "intermediate": "Середній",
        "advanced": "Просунутий", "expert": "Експертний"
    ]

    static func localizedDifficultyLabel(_ key: String) -> String {
        if isAppEnglish {
            return key.capitalized
        }
        return difficultyUkMap[key] ?? key.capitalized
    }

    var localizedDifficulty: String? {
        guard let difficulty else { return nil }
        return Self.localizedDifficultyLabel(difficulty)
    }

    private static let entryTypeEnMap = [
        "rock": "Rocky", "beach": "Sandy", "boat": "Boat"
    ]

    var localizedEntryType: String? {
        guard let entryType else { return nil }
        if Self.isAppEnglish {
            return Self.entryTypeEnMap[entryType] ?? entryType.capitalized
        }
        return entryTypeUk ?? entryType
    }

    var localizedBestSeason: String? {
        guard bestSeason != nil else { return nil }
        if Self.isAppEnglish {
            return bestSeason
        }
        return bestSeasonUk ?? bestSeason
    }

    private static let accessEnMap = [
        "easy": "Easy", "moderate": "Moderate", "difficult": "Difficult"
    ]

    var localizedAccess: String? {
        guard let access else { return nil }
        if Self.isAppEnglish {
            return Self.accessEnMap[access] ?? access.capitalized
        }
        return accessUk ?? access
    }

    var localizedInfrastructure: String? {
        guard let infrastructure else { return nil }
        if Self.isAppEnglish {
            return infrastructure.capitalized
        }
        return infrastructureUk ?? infrastructure
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
