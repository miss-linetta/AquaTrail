//
//  EquipmentDetailView.swift
//  AquaTrail
//

import SwiftUI

struct EquipmentDetailView: View {
    let item: Equipment
    @State private var showEdit = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerCard
                detailsSection
                serviceSection
                if item.type == "tank" {
                    hydroTestSection
                }
                if let notes = item.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Color.navyDeep)
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
                    .foregroundStyle(Color.skyLight)
            }
        }
        .navigationDestination(isPresented: $showEdit) {
            EquipmentFormView(editItem: item)
        }
    }

    // MARK: – Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.deepTeal)
                    .frame(width: 72, height: 72)
                Image(systemName: item.typeIcon)
                    .font(.title)
                    .foregroundStyle(Color.skyLight)
            }

            Text(item.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(item.localizedType)
                .font(.subheadline)
                .foregroundStyle(Color.skyLight)

            if let brand = item.brand, let model = item.model {
                Text("\(brand) \(model)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            } else if let brand = item.brand {
                Text(brand)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.deepTeal)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: – Details

    private var detailsSection: some View {
        VStack(spacing: 0) {
            if let date = item.purchaseDateValue {
                infoRow(
                    icon: "cart.fill",
                    title: "Purchase date",
                    value: date.formatted(date: .long, time: .omitted)
                )
            }
        }
        .background(Color.deepTeal.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: – Service

    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Service")

            VStack(spacing: 0) {
                if let date = item.lastServiceDateValue {
                    infoRow(
                        icon: "wrench.fill",
                        title: "Last service",
                        value: date.formatted(date: .long, time: .omitted)
                    )
                    Divider().background(.white.opacity(0.15))
                }

                if item.serviceIntervalMonths > 0 {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.body)
                            .foregroundStyle(Color.skyLight)
                            .frame(width: 28)
                        Text("Interval")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text("\(item.serviceIntervalMonths) \(String(localized: "months"))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    Divider().background(.white.opacity(0.15))
                }

                statusRow(item.serviceStatus)
            }
            .background(Color.deepTeal.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: – Hydro test

    private var hydroTestSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Hydrostatic test")

            VStack(spacing: 0) {
                if let date = item.hydroTestDateValue {
                    infoRow(
                        icon: "gauge.with.dots.needle.bottom.50percent",
                        title: "Last test",
                        value: date.formatted(date: .long, time: .omitted)
                    )
                    Divider().background(.white.opacity(0.15))
                }

                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.body)
                        .foregroundStyle(Color.skyLight)
                        .frame(width: 28)
                    Text("Interval")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("5 \(String(localized: "years"))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                Divider().background(.white.opacity(0.15))

                statusRow(item.hydroTestStatus)
            }
            .background(Color.deepTeal.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: – Notes

    private func notesSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Notes")
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.deepTeal.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: – Helpers

    private func sectionTitle(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.white)
    }

    private func infoRow(icon: String, title: LocalizedStringKey, value: String) -> some View {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func statusRow(_ status: Equipment.ServiceStatus) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor(status))
                .frame(width: 10, height: 10)
                .frame(width: 28)
            Text("Status")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(status.label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(statusColor(status))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func statusColor(_ status: Equipment.ServiceStatus) -> Color {
        switch status {
        case .ok: return .green
        case .dueSoon: return .orange
        case .overdue: return .red
        case .unknown: return .gray
        case .notRequired: return .clear
        }
    }
}
