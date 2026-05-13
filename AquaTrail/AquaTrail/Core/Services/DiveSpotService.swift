//
//  DiveSpotService.swift
//  AquaTrail
//

import Foundation

struct DiveSpotService {
    static func fetchAll() async throws -> [DiveSpot] {
        try await supabase
            .from("dive_spots")
            .select()
            .execute()
            .value
    }
}
