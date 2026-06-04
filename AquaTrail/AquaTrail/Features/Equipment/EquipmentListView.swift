//
//  EquipmentListView.swift
//  AquaTrail
//

import SwiftUI

struct EquipmentListView: View {
    @State private var vm = EquipmentViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.items.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(Color.navyDeep)
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    EquipmentFormView()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.skyLight)
                }
            }
        }
        .task {
            await vm.load()
        }
        .refreshable {
            await vm.load()
        }
    }

    // MARK: – Empty

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.skyLight.opacity(0.5))

                Text("No equipment yet")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Add your diving gear to keep track of it")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                NavigationLink {
                    EquipmentFormView()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Add equipment")
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.navyDeep)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.skyLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 120)
        }
    }

    // MARK: – List

    private var list: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(vm.items) { item in
                    NavigationLink {
                        EquipmentDetailView(item: item)
                    } label: {
                        equipmentRow(item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { await vm.delete(item) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func equipmentRow(_ item: Equipment) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.deepTeal)
                    .frame(width: 48, height: 48)
                Image(systemName: item.typeIcon)
                    .font(.body)
                    .foregroundStyle(Color.skyLight)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(item.localizedType)
                        .font(.caption)
                        .foregroundStyle(Color.skyLight)

                    if let brand = item.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                if item.serviceIntervalMonths > 0 {
                    serviceStatusBadge(item.serviceStatus)
                }
                if item.type == "tank" && item.hydroTestStatus != .notRequired {
                    serviceStatusBadge(item.hydroTestStatus, prefix: String(localized: "Hydro test"))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(14)
        .background(Color.deepTeal.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func serviceStatusBadge(_ status: Equipment.ServiceStatus, prefix: String? = nil) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(status))
                .frame(width: 6, height: 6)
            if let prefix {
                Text("\(prefix): \(status.label)")
                    .font(.caption2)
                    .foregroundStyle(statusColor(status))
            } else {
                Text(status.label)
                    .font(.caption2)
                    .foregroundStyle(statusColor(status))
            }
        }
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
