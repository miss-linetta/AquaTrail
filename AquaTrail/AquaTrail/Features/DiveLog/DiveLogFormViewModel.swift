//
//  DiveLogFormViewModel.swift
//  AquaTrail
//

import Foundation
import CoreLocation
import Observation

@Observable
@MainActor
class DiveLogFormViewModel {
    var spotName = ""
    var diveSpotId: UUID?
    var date = Date()
    var depthText = ""
    var durationText = ""
    var waterTempText = ""
    var visibilityText = ""
    var entryType = ""
    var difficulty = ""
    var rating: Int = 0
    var notes = ""
    var buddyName = ""
    var latitude: Double?
    var longitude: Double?

    var isSaving = false
    var errorMessage: String?
    var savedSuccessfully = false

    // Spot search
    var allSpots: [DiveSpot] = []
    var showSuggestions = false

    var filteredSpots: [DiveSpot] {
        guard !spotName.isEmpty else { return [] }
        let query = spotName.lowercased()
        return allSpots.filter {
            $0.name.lowercased().contains(query) ||
            ($0.nameEn?.lowercased().contains(query) ?? false)
        }
    }

    private var editingLogId: UUID?

    var isEditing: Bool { editingLogId != nil }

    let difficulties = ["beginner", "intermediate", "advanced", "expert"]
    let difficultyLabels = ["Початковий", "Середній", "Просунутий", "Експертний"]
    let entryTypes = ["shore", "boat"]
    let entryTypeLabels = ["Берег", "Човен"]

    func loadSpots() async {
        allSpots = (try? await DiveSpotService.fetchAll()) ?? []
    }

    func selectSpot(_ spot: DiveSpot) {
        spotName = spot.name
        diveSpotId = spot.id
        latitude = spot.latitude
        longitude = spot.longitude
        if let d = spot.maxDepth { depthText = "\(d)" }
        difficulty = spot.difficulty ?? ""
        entryType = spot.entryType ?? ""
        showSuggestions = false
    }

    func clearSpotSelection() {
        diveSpotId = nil
    }

    func loadForEdit(_ log: DiveLog) {
        editingLogId = log.id
        spotName = log.spotName
        diveSpotId = log.diveSpotId
        date = log.dateValue
        depthText = "\(log.depth)"
        durationText = "\(log.duration)"
        if let t = log.waterTemp { waterTempText = "\(t)" }
        if let v = log.visibility { visibilityText = "\(v)" }
        entryType = log.entryType ?? ""
        difficulty = log.difficulty ?? ""
        rating = log.rating ?? 0
        notes = log.notes ?? ""
        buddyName = log.buddyName ?? ""
        // Load coordinates from linked spot if available
        if let spotId = log.diveSpotId,
           let spot = allSpots.first(where: { $0.id == spotId }) {
            latitude = spot.latitude
            longitude = spot.longitude
        }
    }

    func loadFromSpot(_ spot: DiveSpot) {
        spotName = spot.name
        diveSpotId = spot.id
        latitude = spot.latitude
        longitude = spot.longitude
        if let d = spot.maxDepth { depthText = "\(d)" }
        difficulty = spot.difficulty ?? ""
        entryType = spot.entryType ?? ""
    }

    func save() async -> Bool {
        guard !spotName.isEmpty else {
            errorMessage = "Вкажіть назву місця"
            return false
        }
        guard let depth = Int(depthText), depth > 0 else {
            errorMessage = "Вкажіть коректну глибину"
            return false
        }
        guard let duration = Int(durationText), duration > 0 else {
            errorMessage = "Вкажіть коректну тривалість"
            return false
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let userId = try await supabase.auth.session.user.id

            if let logId = editingLogId {
                let update = DiveLogUpdate(
                    diveSpotId: diveSpotId,
                    spotName: spotName,
                    date: DiveLog.dateString(from: date),
                    depth: depth,
                    duration: duration,
                    waterTemp: Int(waterTempText),
                    visibility: Int(visibilityText),
                    entryType: entryType.isEmpty ? nil : entryType,
                    difficulty: difficulty.isEmpty ? nil : difficulty,
                    rating: rating > 0 ? rating : nil,
                    notes: notes.isEmpty ? nil : notes,
                    buddyName: buddyName.isEmpty ? nil : buddyName
                )
                try await DiveLogService.update(id: logId, update)
            } else {
                let insert = DiveLogInsert(
                    userId: userId,
                    diveSpotId: diveSpotId,
                    spotName: spotName,
                    date: DiveLog.dateString(from: date),
                    depth: depth,
                    duration: duration,
                    waterTemp: Int(waterTempText),
                    visibility: Int(visibilityText),
                    entryType: entryType.isEmpty ? nil : entryType,
                    difficulty: difficulty.isEmpty ? nil : difficulty,
                    rating: rating > 0 ? rating : nil,
                    notes: notes.isEmpty ? nil : notes,
                    buddyName: buddyName.isEmpty ? nil : buddyName
                )
                try await DiveLogService.insert(insert)
            }

            savedSuccessfully = true
            return true
        } catch {
            errorMessage = "Помилка збереження: \(error.localizedDescription)"
            return false
        }
    }
}
