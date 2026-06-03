//
//  RecommendationEngine.swift
//  AquaTrail
//
//  Recommendation engine based on content-based filtering with
//  multi-criteria weighted scoring, Gaussian kernels for numeric
//  features, Jaccard similarity for interests, and Bayesian
//  confidence smoothing.
//

import Foundation
import CoreLocation

// MARK: – User Preference Profile

/// Aggregated preference vector built from the user's dive log history.
struct UserPreferenceProfile {
    let avgDepth: Double
    let maxDepth: Double
    let depthStdDev: Double
    let avgWaterTemp: Double
    let avgVisibility: Double
    let avgRating: Double
    let preferredDifficulty: Double        // ordinal: 0..3
    let entryTypeDistribution: [String: Double] // "shore": 0.7, "boat": 0.3
    let seasonDistribution: [Int: Double]  // month → frequency
    let interestTags: Set<String>
    let certificationLevel: Int            // ordinal: 0..5
    let totalDives: Int

    /// Bayesian confidence factor ∈ (0, 1].
    /// c(n) = n / (n + k), where k is the smoothing constant.
    var confidence: Double {
        let k = 5.0
        return Double(totalDives) / (Double(totalDives) + k)
    }

    // MARK: – Build from data

    static func build(
        logs: [DiveLog],
        spots: [DiveSpot],
        profile: Profile
    ) -> UserPreferenceProfile {
        let depths = logs.map { Double($0.depth) }
        let avgDepth = depths.isEmpty ? 15.0 : depths.reduce(0, +) / Double(depths.count)
        let maxDepth = depths.max() ?? 15.0
        let depthVariance = depths.isEmpty ? 25.0
            : depths.map { ($0 - avgDepth) * ($0 - avgDepth) }.reduce(0, +) / Double(depths.count)
        let depthStdDev = sqrt(depthVariance)

        let temps = logs.compactMap { $0.waterTemp }.map(Double.init)
        let avgTemp = temps.isEmpty ? 20.0 : temps.reduce(0, +) / Double(temps.count)

        let vis = logs.compactMap { $0.visibility }.map(Double.init)
        let avgVis = vis.isEmpty ? 8.0 : vis.reduce(0, +) / Double(vis.count)

        let ratings = logs.compactMap { $0.rating }.map(Double.init)
        let avgRating = ratings.isEmpty ? 3.0 : ratings.reduce(0, +) / Double(ratings.count)

        // Difficulty: weighted by rating (liked dives weigh more)
        let diffOrdinals = logs.compactMap { log -> (Double, Double)? in
            guard let d = log.difficulty else { return nil }
            let ord = Self.difficultyOrdinal(d)
            let weight = Double(log.rating ?? 3)
            return (ord * weight, weight)
        }
        let prefDiff: Double
        if diffOrdinals.isEmpty {
            prefDiff = 1.0
        } else {
            let sumWeighted = diffOrdinals.map(\.0).reduce(0, +)
            let sumWeights = diffOrdinals.map(\.1).reduce(0, +)
            prefDiff = sumWeighted / sumWeights
        }

        // Entry type distribution
        var entryCount: [String: Double] = [:]
        for log in logs {
            if let e = log.entryType, !e.isEmpty {
                entryCount[e, default: 0] += Double(log.rating ?? 3)
            }
        }
        let entryTotal = entryCount.values.reduce(0, +)
        let entryDist = entryTotal > 0
            ? entryCount.mapValues { $0 / entryTotal }
            : ["shore": 0.5, "boat": 0.5]

        // Season distribution from dive dates
        let calendar = Calendar.current
        var monthCounts: [Int: Double] = [:]
        for log in logs {
            let month = calendar.component(.month, from: log.dateValue)
            monthCounts[month, default: 0] += 1
        }
        let monthTotal = monthCounts.values.reduce(0, +)
        let seasonDist = monthTotal > 0
            ? monthCounts.mapValues { $0 / monthTotal }
            : [:]

        // Interest tags: from profile + highly rated spots
        var interests = Set(profile.interests ?? [])
        let spotLookup = Dictionary(uniqueKeysWithValues: spots.map { ($0.id, $0) })
        for log in logs where (log.rating ?? 0) >= 4 {
            if let spotId = log.diveSpotId,
               let spot = spotLookup[spotId],
               let tags = spot.tags {
                let parsed = tags.split(separator: ",").map {
                    $0.trimmingCharacters(in: .whitespaces).lowercased()
                }
                interests.formUnion(parsed)
            }
        }

        let certLevel = Self.certificationOrdinal(profile.certification ?? "")
        let dives = profile.totalDives ?? logs.count

        return UserPreferenceProfile(
            avgDepth: avgDepth,
            maxDepth: maxDepth,
            depthStdDev: max(depthStdDev, 3),
            avgWaterTemp: avgTemp,
            avgVisibility: avgVis,
            avgRating: avgRating,
            preferredDifficulty: prefDiff,
            entryTypeDistribution: entryDist,
            seasonDistribution: seasonDist,
            interestTags: interests,
            certificationLevel: certLevel,
            totalDives: dives
        )
    }

    // MARK: – Ordinal mappings

    static func difficultyOrdinal(_ d: String) -> Double {
        switch d.lowercased() {
        case "beginner": return 0
        case "intermediate": return 1
        case "advanced": return 2
        case "expert": return 3
        default: return 1
        }
    }

    static func certificationOrdinal(_ c: String) -> Int {
        switch c.uppercased() {
        case "CMAS 1*", "OWD": return 1
        case "CMAS 2*", "AOWD": return 2
        case "CMAS 3*": return 3
        case "RESCUE DIVER": return 4
        default: return 0
        }
    }

    static func spotCertificationRequired(_ c: String?) -> Int {
        guard let c else { return 0 }
        return certificationOrdinal(c)
    }
}

// MARK: – Recommendation Engine

struct RecommendationEngine {

    /// Feature weights (must sum to 1.0).
    struct Weights {
        var depth: Double = 0.20
        var difficulty: Double = 0.18
        var temperature: Double = 0.12
        var visibility: Double = 0.10
        var interests: Double = 0.20
        var entryType: Double = 0.08
        var season: Double = 0.07
        var distance: Double = 0.05
    }

    let weights: Weights

    init(weights: Weights = Weights()) {
        self.weights = weights
    }

    // MARK: – Public API

    struct ScoredSpot: Identifiable {
        let spot: DiveSpot
        let score: Double
        let matchPercentage: Int
        let reasons: [String]
        var id: UUID { spot.id }
    }

    /// Scores and ranks all spots for the given user profile.
    func recommend(
        spots: [DiveSpot],
        userProfile: UserPreferenceProfile,
        userLocation: CLLocation?,
        visitedSpotIds: Set<UUID>,
        limit: Int = 20
    ) -> [ScoredSpot] {
        spots
            .filter { !visitedSpotIds.contains($0.id) }
            .map { spot in
                scoreSpot(spot, profile: userProfile, userLocation: userLocation)
            }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: – Scoring

    private func scoreSpot(
        _ spot: DiveSpot,
        profile: UserPreferenceProfile,
        userLocation: CLLocation?
    ) -> ScoredSpot {
        var reasons: [String] = []

        // 1. Depth similarity — Gaussian kernel
        //    s = exp(-(x - μ)² / (2σ²))
        let spotDepth = Double(spot.maxDepth ?? Int(profile.avgDepth))
        let depthScore = gaussian(
            value: spotDepth,
            mean: profile.avgDepth,
            sigma: max(profile.depthStdDev * 1.5, 5)
        )
        if depthScore > 0.7 {
            reasons.append(String(localized: "Depth in your range"))
        }

        // 2. Difficulty match — ordinal distance with Gaussian
        let spotDiff = UserPreferenceProfile.difficultyOrdinal(spot.difficulty ?? "intermediate")
        let diffScore = gaussian(value: spotDiff, mean: profile.preferredDifficulty, sigma: 1.0)
        if diffScore > 0.8 {
            reasons.append(String(localized: "Suitable difficulty"))
        }

        // 3. Temperature — Gaussian kernel
        let spotTemp = Double(spot.waterTempSurfaceC ?? Int(profile.avgWaterTemp))
        let tempScore = gaussian(value: spotTemp, mean: profile.avgWaterTemp, sigma: 5.0)

        // 4. Visibility — higher is better, use Gaussian around preferred
        let spotVis = Double(spot.visibilitySummerM ?? Int(profile.avgVisibility))
        let visScore = gaussian(value: spotVis, mean: profile.avgVisibility, sigma: 5.0)

        // 5. Interest/tag overlap — Jaccard similarity
        //    J(A,B) = |A ∩ B| / |A ∪ B|
        let spotTags = parseSpotTags(spot.tags)
        let interestScore: Double
        if profile.interestTags.isEmpty && spotTags.isEmpty {
            interestScore = 0.5
        } else if profile.interestTags.isEmpty || spotTags.isEmpty {
            interestScore = 0.3
        } else {
            let intersection = Double(profile.interestTags.intersection(spotTags).count)
            let union = Double(profile.interestTags.union(spotTags).count)
            interestScore = union > 0 ? intersection / union : 0
            if interestScore > 0.3 {
                let matched = profile.interestTags.intersection(spotTags)
                    .prefix(2).joined(separator: ", ")
                reasons.append(String(localized: "Interesting: \(matched)"))
            }
        }

        // 6. Entry type preference
        let entryScore: Double
        if let entry = spot.entryType, let pref = profile.entryTypeDistribution[entry] {
            entryScore = pref
        } else {
            entryScore = 0.5
        }

        // 7. Season match — current month preference
        let currentMonth = Calendar.current.component(.month, from: Date())
        let seasonScore: Double
        if let bestSeason = spot.bestSeason {
            let seasonMonths = parseSeasonMonths(bestSeason)
            if seasonMonths.contains(currentMonth) {
                seasonScore = profile.seasonDistribution[currentMonth] ?? 0.7
                reasons.append(String(localized: "Good season now"))
            } else {
                seasonScore = 0.3
            }
        } else {
            seasonScore = 0.5
        }

        // 8. Distance — closer is better (sigmoid decay)
        let distScore: Double
        if let loc = userLocation {
            let km = Double(spot.distanceKm(from: loc) ?? 500)
            // sigmoid: 1 / (1 + exp((x - 200) / 100))
            distScore = 1.0 / (1.0 + exp((km - 200.0) / 100.0))
        } else {
            distScore = 0.5
        }

        // Weighted sum
        let rawScore =
            weights.depth * depthScore +
            weights.difficulty * diffScore +
            weights.temperature * tempScore +
            weights.visibility * visScore +
            weights.interests * interestScore +
            weights.entryType * entryScore +
            weights.season * seasonScore +
            weights.distance * distScore

        // Eligibility penalty
        let eligibility = eligibilityFactor(spot: spot, profile: profile)
        if eligibility < 1.0 {
            reasons.append(String(localized: "Requires higher certification"))
        }

        // Bayesian confidence smoothing
        // final = c · raw + (1 - c) · prior
        let prior = 0.5
        let confident = profile.confidence * rawScore + (1.0 - profile.confidence) * prior

        let finalScore = confident * eligibility

        return ScoredSpot(
            spot: spot,
            score: finalScore,
            matchPercentage: Int((finalScore * 100).rounded()),
            reasons: reasons
        )
    }

    // MARK: – Math helpers

    /// Gaussian kernel: exp(-(x-μ)² / (2σ²))
    private func gaussian(value: Double, mean: Double, sigma: Double) -> Double {
        let diff = value - mean
        return exp(-(diff * diff) / (2.0 * sigma * sigma))
    }

    /// Eligibility: 1.0 if user meets requirements, 0.3 penalty otherwise.
    private func eligibilityFactor(spot: DiveSpot, profile: UserPreferenceProfile) -> Double {
        var factor = 1.0
        let required = UserPreferenceProfile.spotCertificationRequired(spot.minCertification)
        if required > 0 && profile.certificationLevel < required {
            factor *= 0.3
        }
        if let minDives = spot.minDives, profile.totalDives < minDives {
            factor *= 0.5
        }
        return factor
    }

    /// Parse comma-separated tags into a set.
    private func parseSpotTags(_ tags: String?) -> Set<String> {
        guard let tags, !tags.isEmpty else { return [] }
        return Set(tags.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces).lowercased()
        })
    }

    /// Parse season string to month numbers.
    private func parseSeasonMonths(_ season: String) -> Set<Int> {
        let s = season.lowercased()
        var months = Set<Int>()
        let mapping: [(String, [Int])] = [
            ("spring", [3, 4, 5]), ("весна", [3, 4, 5]),
            ("summer", [6, 7, 8]), ("літо", [6, 7, 8]),
            ("autumn", [9, 10, 11]), ("fall", [9, 10, 11]), ("осінь", [9, 10, 11]),
            ("winter", [12, 1, 2]), ("зима", [12, 1, 2]),
            ("year-round", Array(1...12)), ("цілий рік", Array(1...12)),
            ("jun", [6]), ("jul", [7]), ("aug", [8]),
            ("may", [5]), ("sep", [9]), ("oct", [10]),
        ]
        for (key, ms) in mapping where s.contains(key) {
            months.formUnion(ms)
        }
        // If nothing matched, assume year-round
        return months.isEmpty ? Set(1...12) : months
    }
}
