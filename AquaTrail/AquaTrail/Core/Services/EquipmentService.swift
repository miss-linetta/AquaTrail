//
//  EquipmentService.swift
//  AquaTrail
//

import Foundation

struct EquipmentService {
    static func fetchAll(userId: UUID) async throws -> [Equipment] {
        try await supabase
            .from("equipment")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    static func insert(_ equipment: EquipmentInsert) async throws {
        try await supabase
            .from("equipment")
            .insert(equipment)
            .execute()
    }

    static func update(id: UUID, _ equipment: EquipmentUpdate) async throws {
        try await supabase
            .from("equipment")
            .update(equipment)
            .eq("id", value: id)
            .execute()
    }

    static func delete(id: UUID) async throws {
        try await supabase
            .from("equipment")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
