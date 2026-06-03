//
//  DiveLogDetailView.swift
//  AquaTrail
//

import SwiftUI

struct DiveLogDetailView: View {
    let log: DiveLog
    var displaySpotName: String?
    @State private var showEdit = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header card
                VStack(spacing: 8) {
                    Text(displaySpotName ?? log.spotName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(log.dateValue, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    if let rating = log.rating, rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundStyle(star <= rating ? Color.skyLight : .white.opacity(0.3))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.deepTeal)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Main stats
                HStack(spacing: 12) {
                    statCard(icon: "arrow.down.to.line", title: "Depth", value: "\(log.depth) m")
                    statCard(icon: "clock.fill", title: "Time", value: "\(log.duration) min")
                }

                // Conditions
                let conditions = buildConditions()
                if !conditions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Conditions")
                            .font(.headline)
                            .foregroundStyle(.white)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(conditions, id: \.title) { item in
                                statCard(icon: item.icon, title: item.title, value: item.value)
                            }
                        }
                    }
                }

                // Difficulty
                if let difficulty = log.difficulty {
                    infoRow(icon: "gauge.medium", title: "Difficulty", value: difficultyLabel(difficulty))
                }

                // Entry type
                if let entry = log.entryType {
                    infoRow(icon: "figure.water.fitness", title: "Entry type", value: entryLabel(entry))
                }

                // Buddy
                if let buddy = log.buddyName, !buddy.isEmpty {
                    infoRow(icon: "person.2.fill", title: "Buddy", value: buddy)
                }

                // Notes
                if let notes = log.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "note.text")
                                .foregroundStyle(Color.skyLight)
                            Text("Notes")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(Color.deepTeal.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Color.navyDeep)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
                    .foregroundStyle(Color.skyLight)
            }
        }
        .navigationDestination(isPresented: $showEdit) {
            DiveLogFormView(editLog: log)
        }
    }

    private func statCard(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.skyLight)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.deepTeal.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.skyLight)
                .frame(width: 28)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(14)
        .background(Color.deepTeal.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private struct ConditionItem {
        let icon: String
        let title: String
        let value: String
    }

    private func buildConditions() -> [ConditionItem] {
        var items: [ConditionItem] = []
        if let temp = log.waterTemp {
            items.append(ConditionItem(icon: "thermometer.medium", title: "Water temp.", value: "\(temp)°C"))
        }
        if let vis = log.visibility {
            items.append(ConditionItem(icon: "eye.fill", title: "Visibility", value: "\(vis) m"))
        }
        return items
    }

    private func difficultyLabel(_ d: String) -> String {
        switch d {
        case "beginner": return "Beginner"
        case "intermediate": return "Intermediate"
        case "advanced": return "Advanced"
        case "expert": return "Expert"
        default: return d
        }
    }

    private func entryLabel(_ e: String) -> String {
        switch e {
        case "shore": return "Shore"
        case "boat": return "Boat"
        default: return e
        }
    }
}
