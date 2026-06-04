//
//  EquipmentViewModel.swift
//  AquaTrail
//

import Foundation
import Observation

@Observable
@MainActor
class EquipmentViewModel {
    var items: [Equipment] = []
    var isLoading = false
    var errorMessage: String?

    func load() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await EquipmentService.fetchAll(userId: userId)
        } catch {
            errorMessage = String(localized: "Failed to load equipment")
        }
    }

    func delete(_ item: Equipment) async {
        do {
            try await EquipmentService.delete(id: item.id)
            items.removeAll { $0.id == item.id }
        } catch {
            errorMessage = String(localized: "Failed to delete equipment")
        }
    }
}
