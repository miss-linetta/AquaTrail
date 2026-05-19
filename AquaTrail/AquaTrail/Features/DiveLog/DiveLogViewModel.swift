//
//  DiveLogViewModel.swift
//  AquaTrail
//

import Foundation
import Observation

@Observable
@MainActor
class DiveLogViewModel {
    var logs: [DiveLog] = []
    var isLoading = false
    var errorMessage: String?

    // Stats for recommendation engine
    var totalDives: Int { logs.count }
    var averageDepth: Double? {
        guard !logs.isEmpty else { return nil }
        return Double(logs.map(\.depth).reduce(0, +)) / Double(logs.count)
    }
    var averageRating: Double? {
        let rated = logs.compactMap(\.rating)
        guard !rated.isEmpty else { return nil }
        return Double(rated.reduce(0, +)) / Double(rated.count)
    }
    var totalBottomTime: Int {
        logs.map(\.duration).reduce(0, +)
    }

    func load() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            logs = try await DiveLogService.fetchAll(userId: userId)
        } catch {
            errorMessage = "Не вдалось завантажити записи"
        }
    }

    func delete(_ log: DiveLog) async {
        do {
            try await DiveLogService.delete(id: log.id)
            logs.removeAll { $0.id == log.id }
        } catch {
            errorMessage = "Не вдалось видалити запис"
        }
    }
}
