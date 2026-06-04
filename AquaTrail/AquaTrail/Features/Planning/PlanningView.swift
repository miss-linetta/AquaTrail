//
//  PlanningView.swift
//  AquaTrail
//

import SwiftUI
import MapKit

struct PlanningView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var vm = PlanningViewModel()
    @State private var showAuth = false
    @State private var selectedSpot: RecommendationEngine.ScoredSpot?
    @State private var showMap = false

    var body: some View {
        NavigationStack {
            Group {
                if !authVM.isAuthenticated {
                    notAuthenticatedView
                } else if vm.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !vm.hasLogs {
                    noLogsView
                } else {
                    recommendationsList
                }
            }
            .background(Color.navyDeep)
            .navigationTitle("Planning")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if authVM.isAuthenticated && !vm.recommendations.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showMap = true
                        } label: {
                            Image(systemName: "map.fill")
                                .foregroundStyle(Color.skyLight)
                        }
                    }
                }
            }
            .task {
                if authVM.isAuthenticated {
                    vm.location.requestLocation()
                    await vm.load()
                }
            }
            .onChange(of: authVM.isAuthenticated) { _, isAuth in
                if isAuth {
                    showAuth = false
                    Task {
                        vm.location.requestLocation()
                        await vm.load()
                    }
                }
            }
            .fullScreenCover(isPresented: $showAuth) {
                NavigationStack {
                    AuthView(vm: authVM)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button { showAuth = false } label: {
                                    Image(systemName: "xmark")
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showMap) {
                recommendationsMap
            }
        }
    }

    // MARK: – Not authenticated

    private var notAuthenticatedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(Color.skyLight.opacity(0.5))

            Text("Sign in to get personalized recommendations")
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Button { showAuth = true } label: {
                Text("Sign in")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.navyDeep)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.skyLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: – No logs

    private var noLogsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(Color.skyLight.opacity(0.5))

            Text("Add records to your log")
                .font(.headline)
                .foregroundStyle(.white)

            Text("The system will analyze your dives and suggest the best spots")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: – Profile summary

    private var profileSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(Color.skyLight)
                Text("Your diver profile")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            if let prefs = vm.userProfile {
                HStack(spacing: 0) {
                    profileStat(
                        value: "\(Int(prefs.avgDepth.rounded()))",
                        unit: "м",
                        label: "Avg. depth"
                    )
                    profileStat(
                        value: String(format: "%.1f", prefs.preferredDifficulty),
                        unit: "/3",
                        label: "Difficulty"
                    )
                    profileStat(
                        value: "\(Int(prefs.avgWaterTemp.rounded()))",
                        unit: "°C",
                        label: "Temp."
                    )
                    profileStat(
                        value: "\(Int((prefs.confidence * 100).rounded()))",
                        unit: "%",
                        label: "Confidence"
                    )
                }

                if !prefs.interestTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array(prefs.interestTags).sorted(), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.oceanBlue.opacity(0.4))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.deepTeal)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    private func profileStat(value: String, unit: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.skyLight)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Color.skyLight.opacity(0.7))
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Recommendations list

    private var recommendationsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                profileSummary

                HStack {
                    Text("Recommended spots")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)

                ForEach(vm.recommendations) { scored in
                    NavigationLink {
                        DiveSpotDetailView(
                            spot: scored.spot,
                            userLocation: vm.location.userLocation
                        )
                    } label: {
                        recommendationCard(scored)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 16)
            .padding(.bottom, 40)
        }
    }

    private func recommendationCard(_ scored: RecommendationEngine.ScoredSpot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scored.spot.localizedName)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    if let km = scored.spot.distanceKm(from: vm.location.userLocation) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text("\(km) km")
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                // Match percentage
                ZStack {
                    Circle()
                        .stroke(Color.deepTeal, lineWidth: 3)
                        .frame(width: 48, height: 48)
                    Circle()
                        .trim(from: 0, to: Double(scored.matchPercentage) / 100)
                        .stroke(matchColor(scored.matchPercentage), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))
                    Text("\(scored.matchPercentage)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }

            // Quick stats
            HStack(spacing: 16) {
                if let depth = scored.spot.maxDepth {
                    miniStat(icon: "arrow.down.to.line", value: "\(depth) м")
                }
                if let diff = scored.spot.difficulty {
                    miniStat(icon: "gauge.medium", value: diffLabel(diff))
                }
                if let temp = scored.spot.waterTempSurfaceC {
                    miniStat(icon: "thermometer.medium", value: "\(temp)°C")
                }
            }

            // Reasons
            if !scored.reasons.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundStyle(Color.skyLight)
                    Text(scored.reasons.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(Color.skyLight)
                        .lineLimit(2)
                }
            }
        }
        .padding(16)
        .background(Color.deepTeal.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.diveBlue.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func miniStat(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func matchColor(_ percentage: Int) -> Color {
        if percentage >= 70 { return .green }
        if percentage >= 45 { return Color.skyLight }
        return .orange
    }

    private func diffLabel(_ d: String) -> String {
        switch d {
        case "beginner": return "Begn."
        case "intermediate": return "Interm."
        case "advanced": return "Adv."
        case "expert": return "Expert"
        default: return d
        }
    }

    // MARK: – Map

    private var recommendationsMap: some View {
        NavigationStack {
            Map {
                ForEach(vm.recommendations) { scored in
                    Marker(
                        "\(scored.spot.localizedName) (\(scored.matchPercentage)%)",
                        coordinate: scored.spot.coordinate
                    )
                    .tint(matchColor(scored.matchPercentage))
                }
                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .navigationTitle("Recommendations on map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showMap = false }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}
