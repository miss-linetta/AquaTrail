//
//  Profile.swift
//  AquaTrail
//

import Foundation

struct Profile: Codable {
    let id: UUID
    var displayName: String?
    var certification: String?
    var totalDives: Int?
    var avatarUrl: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case certification
        case totalDives = "total_dives"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
    }
}
