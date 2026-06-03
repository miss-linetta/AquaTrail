//
//  PlanningViewModel.swift
//  AquaTrail
//

import Foundation
import CoreLocation
import Observation

@Observable
@MainActor
class PlanningViewModel {
    var recommendations: [RecommendationEngine.ScoredSpot] = []
    var allSpots: [DiveSpot] = []
    var isLoading = false
    var errorMessage: String?
    var userProfile: UserPreferenceProfile?
    var hasLogs = false

    let location = LocationManager()
    private let engine = RecommendationEngine()

    func load() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            async let spotsTask = DiveSpotService.fetchAll()
            async let logsTask = DiveLogService.fetchAll(userId: userId)
            async let profileTask = ProfileService.fetch(userId: userId)

            let spots = (try? await spotsTask) ?? []
            let logs = (try? await logsTask) ?? []
            let profile = try await profileTask

            allSpots = spots
            hasLogs = !logs.isEmpty

            let prefs = UserPreferenceProfile.build(
                logs: logs,
                spots: spots,
                profile: profile
            )
            userProfile = prefs

            let visitedIds = Set(logs.compactMap(\.diveSpotId))

            recommendations = engine.recommend(
                spots: spots,
                userProfile: prefs,
                userLocation: location.userLocation,
                visitedSpotIds: visitedIds
            )
        } catch {
            errorMessage = "Не вдалось завантажити дані"
        }
    }
}
