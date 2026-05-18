//
//  AllSpotsView.swift
//  AquaTrail
//

import SwiftUI
import CoreLocation

// MARK: – Sort

enum SpotSortOption: String, CaseIterable {
    case nearest = "Найближчі"
    case farthest = "Найдальші"
    case easiest = "Легкі → Складні"
    case hardest = "Складні → Легкі"
    case shallowest = "Мілкі → Глибокі"
    case deepest = "Глибокі → Мілкі"
}

// MARK: – Filter

struct SpotFilter {
    var difficulties: Set<String> = []
    var certifications: Set<String> = []
    var maxDistanceKm: Int? = nil
    var maxDepth: Int? = nil

    var isActive: Bool {
        !difficulties.isEmpty || !certifications.isEmpty || maxDistanceKm != nil || maxDepth != nil
    }
}

struct AllSpotsView: View {
    let spots: [DiveSpot]
    let userLocation: CLLocation?
    @Environment(\.dismiss) private var dismiss
    @State private var sortOption: SpotSortOption = .nearest
    @State private var filter = SpotFilter()
    @State private var showFilters = false

    private static let difficultyOrder: [String: Int] = [
        "beginner": 0, "intermediate": 1, "advanced": 2, "expert": 3
    ]

    private var filteredSpots: [DiveSpot] {
        spots.filter { spot in
            if !filter.difficulties.isEmpty,
               let d = spot.difficulty, !filter.difficulties.contains(d) {
                return false
            }
            if !filter.certifications.isEmpty,
               let c = spot.minCertification, !filter.certifications.contains(c) {
                return false
            }
            if let maxDist = filter.maxDistanceKm,
               let km = spot.distanceKm(from: userLocation), km > maxDist {
                return false
            }
            if let maxD = filter.maxDepth,
               let depth = spot.maxDepth, depth > maxD {
                return false
            }
            return true
        }
    }

    private var sortedSpots: [DiveSpot] {
        let list = filteredSpots
        switch sortOption {
        case .nearest:
            return list.sorted {
                ($0.distanceKm(from: userLocation) ?? Int.max) <
                ($1.distanceKm(from: userLocation) ?? Int.max)
            }
        case .farthest:
            return list.sorted {
                ($0.distanceKm(from: userLocation) ?? 0) >
                ($1.distanceKm(from: userLocation) ?? 0)
            }
        case .easiest:
            return list.sorted {
                let d0 = Self.difficultyOrder[$0.difficulty ?? ""] ?? 99
                let d1 = Self.difficultyOrder[$1.difficulty ?? ""] ?? 99
                if d0 != d1 { return d0 < d1 }
                return ($0.maxDepth ?? Int.max) < ($1.maxDepth ?? Int.max)
            }
        case .hardest:
            return list.sorted {
                let d0 = Self.difficultyOrder[$0.difficulty ?? ""] ?? 99
                let d1 = Self.difficultyOrder[$1.difficulty ?? ""] ?? 99
                if d0 != d1 { return d0 > d1 }
                return ($0.maxDepth ?? 0) > ($1.maxDepth ?? 0)
            }
        case .shallowest:
            return list.sorted {
                ($0.maxDepth ?? Int.max) < ($1.maxDepth ?? Int.max)
            }
        case .deepest:
            return list.sorted {
                ($0.maxDepth ?? 0) > ($1.maxDepth ?? 0)
            }
        }
    }

    // MARK: – Available values for filters

    private var availableDifficulties: [String] {
        Array(Set(spots.compactMap(\.difficulty))).sorted {
            (Self.difficultyOrder[$0] ?? 99) < (Self.difficultyOrder[$1] ?? 99)
        }
    }

    private var availableCertifications: [String] {
        Array(Set(spots.compactMap(\.minCertification))).sorted()
    }

    // MARK: – Body

    var body: some View {
        VStack(spacing: 0) {
            sortAndFilterBar
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(sortedSpots) { spot in
                        NavigationLink {
                            DiveSpotDetailView(spot: spot, userLocation: userLocation)
                        } label: {
                            spotRow(spot)
                        }
                        .buttonStyle(.plain)
                    }
                    if sortedSpots.isEmpty {
                        Text("Немає місць за обраними фільтрами")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 40)
                    }
                }
                .padding(16)
            }
        }
        .background(Color.navyDeep)
        .navigationTitle("Всі місця")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showFilters) {
            filterSheet
        }
    }

    // MARK: – Sort & filter bar

    private var sortAndFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    showFilters = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("Фільтри")
                        if filter.isActive {
                            Circle()
                                .fill(Color.skyLight)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(filter.isActive ? Color.navyDeep : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(filter.isActive ? Color.skyLight : Color.deepTeal.opacity(0.5))
                    .clipShape(Capsule())
                }

                ForEach(SpotSortOption.allCases, id: \.self) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            sortOption = option
                        }
                    } label: {
                        Text(option.rawValue)
                            .font(.subheadline)
                            .fontWeight(sortOption == option ? .semibold : .regular)
                            .foregroundStyle(sortOption == option ? Color.navyDeep : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(sortOption == option ? Color.skyLight : Color.deepTeal.opacity(0.5))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: – Filter sheet

    private var filterSheet: some View {
        NavigationStack {
            List {
                Section("Складність") {
                    ForEach(availableDifficulties, id: \.self) { diff in
                        Button {
                            toggleFilter(&filter.difficulties, value: diff)
                        } label: {
                            HStack {
                                Text(diff)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if filter.difficulties.contains(diff) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.oceanBlue)
                                }
                            }
                        }
                    }
                }

                if !availableCertifications.isEmpty {
                    Section("Мін. сертифікація") {
                        ForEach(availableCertifications, id: \.self) { cert in
                            Button {
                                toggleFilter(&filter.certifications, value: cert)
                            } label: {
                                HStack {
                                    Text(cert)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if filter.certifications.contains(cert) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.oceanBlue)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Макс. відстань") {
                    HStack {
                        Text("До")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { filter.maxDistanceKm ?? 0 },
                            set: { filter.maxDistanceKm = $0 == 0 ? nil : $0 }
                        )) {
                            Text("Будь-яка").tag(0)
                            Text("50 км").tag(50)
                            Text("100 км").tag(100)
                            Text("200 км").tag(200)
                            Text("500 км").tag(500)
                        }
                        .labelsHidden()
                    }
                }

                Section("Макс. глибина") {
                    HStack {
                        Text("До")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { filter.maxDepth ?? 0 },
                            set: { filter.maxDepth = $0 == 0 ? nil : $0 }
                        )) {
                            Text("Будь-яка").tag(0)
                            Text("10 м").tag(10)
                            Text("20 м").tag(20)
                            Text("30 м").tag(30)
                            Text("40 м").tag(40)
                            Text("50 м").tag(50)
                        }
                        .labelsHidden()
                    }
                }
            }
            .navigationTitle("Фільтри")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { showFilters = false }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скинути") {
                        filter = SpotFilter()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: – Helpers

    private func toggleFilter(_ set: inout Set<String>, value: String) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }

    // MARK: – Row

    private func spotRow(_ spot: DiveSpot) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: spot.photoUrl.flatMap { URL(string: $0) }) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                LinearGradient(
                    colors: [Color.deepTeal, Color.navyDeep],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let difficulty = spot.difficulty {
                    Text(difficulty)
                        .font(.caption)
                        .foregroundStyle(Color.skyLight)
                }

                if let km = spot.distanceKm(from: userLocation) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text("\(km) км")
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer()

            if let depth = spot.maxDepth {
                VStack(spacing: 2) {
                    Text("\(depth)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("м")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(12)
        .background(Color.deepTeal.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
