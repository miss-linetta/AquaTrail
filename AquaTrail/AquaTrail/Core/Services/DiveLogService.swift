//
//  DiveLogService.swift
//  AquaTrail
//

import Foundation

struct DiveLogService {
    static func fetchAll(userId: UUID) async throws -> [DiveLog] {
        try await supabase
            .from("dive_logs")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .execute()
            .value
    }

    static func insert(_ log: DiveLogInsert) async throws {
        try await supabase
            .from("dive_logs")
            .insert(log)
            .execute()
    }

    static func update(id: UUID, _ log: DiveLogUpdate) async throws {
        try await supabase
            .from("dive_logs")
            .update(log)
            .eq("id", value: id)
            .execute()
    }

    static func delete(id: UUID) async throws {
        try await supabase
            .from("dive_logs")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
