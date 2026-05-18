//
//  ProfileService.swift
//  AquaTrail
//

import Foundation

private struct ProfileUpdate: Encodable {
    var displayName: String?
    var certification: String?
    var totalDives: Int?
    var avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case certification
        case totalDives = "total_dives"
        case avatarUrl = "avatar_url"
    }
}

struct ProfileService {
    static func fetch(userId: UUID) async throws -> Profile {
        try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
    }

    static func insert(_ profile: Profile) async throws {
        try await supabase
            .from("profiles")
            .insert(profile)
            .execute()
    }

    static func update(_ profile: Profile) async throws {
        let update = ProfileUpdate(
            displayName: profile.displayName,
            certification: profile.certification,
            totalDives: profile.totalDives,
            avatarUrl: profile.avatarUrl
        )
        try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: profile.id)
            .execute()
    }
}
