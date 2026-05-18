//
//  AllSpotsView.swift
//  AquaTrail
//

import SwiftUI
import CoreLocation

struct AllSpotsView: View {
    let spots: [DiveSpot]
    let userLocation: CLLocation?
    @Environment(\.dismiss) private var dismiss

    private var sortedSpots: [DiveSpot] {
        spots.sorted {
            ($0.distanceKm(from: userLocation) ?? Int.max) <
            ($1.distanceKm(from: userLocation) ?? Int.max)
        }
    }

    var body: some View {
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
            }
            .padding(16)
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
    }

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
