//
//  EquipmentFormViewModel.swift
//  AquaTrail
//

import Foundation
import Observation

@Observable
@MainActor
class EquipmentFormViewModel {
    var name = ""
    var type = "regulator"
    var brand = ""
    var model = ""
    var hasPurchaseDate = false
    var purchaseDate = Date()
    var hasServiceDate = false
    var lastServiceDate = Date()
    var hasHydroTestDate = false
    var hydroTestDate = Date()
    var notes = ""

    var isSaving = false
    var errorMessage: String?

    private var editingId: UUID?
    var isEditing: Bool { editingId != nil }

    func loadForEdit(_ item: Equipment) {
        editingId = item.id
        name = item.name
        type = item.type
        brand = item.brand ?? ""
        model = item.model ?? ""
        notes = item.notes ?? ""
        if let date = item.purchaseDateValue {
            hasPurchaseDate = true
            purchaseDate = date
        }
        if let date = item.lastServiceDateValue {
            hasServiceDate = true
            lastServiceDate = date
        }
        if let date = item.hydroTestDateValue {
            hasHydroTestDate = true
            hydroTestDate = date
        }
    }

    func save() async -> Bool {
        guard !name.isEmpty else {
            errorMessage = String(localized: "Specify equipment name")
            return false
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let userId = try await supabase.auth.session.user.id

            if let itemId = editingId {
                let update = EquipmentUpdate(
                    name: name,
                    type: type,
                    brand: brand.isEmpty ? nil : brand,
                    model: model.isEmpty ? nil : model,
                    purchaseDate: hasPurchaseDate ? Equipment.dateString(from: purchaseDate) : nil,
                    lastServiceDate: hasServiceDate ? Equipment.dateString(from: lastServiceDate) : nil,
                    hydroTestDate: hasHydroTestDate ? Equipment.dateString(from: hydroTestDate) : nil,
                    notes: notes.isEmpty ? nil : notes
                )
                try await EquipmentService.update(id: itemId, update)
            } else {
                let insert = EquipmentInsert(
                    userId: userId,
                    name: name,
                    type: type,
                    brand: brand.isEmpty ? nil : brand,
                    model: model.isEmpty ? nil : model,
                    purchaseDate: hasPurchaseDate ? Equipment.dateString(from: purchaseDate) : nil,
                    lastServiceDate: hasServiceDate ? Equipment.dateString(from: lastServiceDate) : nil,
                    hydroTestDate: hasHydroTestDate ? Equipment.dateString(from: hydroTestDate) : nil,
                    notes: notes.isEmpty ? nil : notes
                )
                try await EquipmentService.insert(insert)
            }

            return true
        } catch {
            errorMessage = String(localized: "Save error: \(error.localizedDescription)")
            return false
        }
    }
}
