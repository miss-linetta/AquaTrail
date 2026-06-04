//
//  DiveLogFormView.swift
//  AquaTrail
//

import SwiftUI
import MapKit

struct DiveLogFormView: View {
    @State private var vm = DiveLogFormViewModel()
    @Environment(\.dismiss) private var dismiss

    var editLog: DiveLog?
    var prefillSpot: DiveSpot?

    @State private var showMapPicker = false
    @State private var mapPosition: MapCameraPosition = .automatic

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                spotNameSection
                dateSection
                depthDurationRow
                tempVisibilityRow
                entryTypeSection
                difficultySection
                locationMapSection
                ratingSection
                buddyField
                notesSection
                errorView
                saveButton
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Color.navyDeep)
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationTitle(vm.isEditing ? "Edit" : "New dive")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await vm.loadSpots()
            if let log = editLog {
                vm.loadForEdit(log)
            } else if let spot = prefillSpot {
                vm.loadFromSpot(spot)
            }
            updateMapPosition()
        }
    }

    // MARK: – Spot name with autocomplete

    private var spotNameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Dive spot")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            TextField("Dive spot name", text: $vm.spotName)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.deepTeal.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.diveBlue.opacity(0.3), lineWidth: 1)
                )
                .contentShape(Rectangle())
                .onChange(of: vm.spotName) { _, _ in
                    vm.showSuggestions = true
                    vm.clearSpotSelection()
                }

            if vm.showSuggestions && !vm.filteredSpots.isEmpty {
                VStack(spacing: 0) {
                    ForEach(vm.filteredSpots.prefix(5)) { spot in
                        Button {
                            vm.selectSpot(spot)
                            updateMapPosition()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(Color.skyLight)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(spot.localizedName)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    if spot.nameEn != nil && spot.localizedName != spot.name {
                                        Text(spot.name)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.5))
                                    } else if let nameEn = spot.nameEn {
                                        Text(nameEn)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                                Spacer()
                                if let depth = spot.maxDepth {
                                    Text("\(depth) м")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.deepTeal)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if vm.diveSpotId != nil {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.skyLight)
                    Text("Linked to dive spot")
                        .font(.caption)
                        .foregroundStyle(Color.skyLight)
                }
            }
        }
    }

    // MARK: – Date

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Date")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            DatePicker("", selection: $vm.date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .colorScheme(.dark)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: – Depth & Duration

    private var depthDurationRow: some View {
        HStack(spacing: 12) {
            field(title: "Depth (m)", text: $vm.depthText, placeholder: "0")
                .keyboardType(.numberPad)
            field(title: "Duration (min)", text: $vm.durationText, placeholder: "0")
                .keyboardType(.numberPad)
        }
    }

    // MARK: – Temp & Visibility

    private var tempVisibilityRow: some View {
        HStack(spacing: 12) {
            field(title: "Water temp. (°C)", text: $vm.waterTempText, placeholder: "—")
                .keyboardType(.numberPad)
            field(title: "Visibility (m)", text: $vm.visibilityText, placeholder: "—")
                .keyboardType(.numberPad)
        }
    }

    // MARK: – Entry type

    private var entryTypeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Entry type")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            HStack(spacing: 8) {
                ForEach(Array(zip(vm.entryTypes, vm.entryTypeLabels)), id: \.0) { type, label in
                    Button {
                        vm.entryType = vm.entryType == type ? "" : type
                    } label: {
                        Text(label)
                            .font(.subheadline)
                            .foregroundStyle(vm.entryType == type ? Color.navyDeep : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(vm.entryType == type ? Color.skyLight : Color.deepTeal.opacity(0.5))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: – Difficulty

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Difficulty")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(zip(vm.difficulties, vm.difficultyLabels)), id: \.0) { diff, label in
                        Button {
                            vm.difficulty = vm.difficulty == diff ? "" : diff
                        } label: {
                            Text(label)
                                .font(.subheadline)
                                .foregroundStyle(vm.difficulty == diff ? Color.navyDeep : .white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(vm.difficulty == diff ? Color.skyLight : Color.deepTeal.opacity(0.5))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: – Location map

    private var locationMapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            if let lat = vm.latitude, let lon = vm.longitude {
                Map(position: $mapPosition) {
                    Marker(vm.spotName.isEmpty ? "Place" : vm.spotName,
                           coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                        .tint(Color.oceanBlue)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .mapControlVisibility(.hidden)
                .onTapGesture {
                    showMapPicker = true
                }

                HStack {
                    Text(String(format: "%.4f, %.4f", lat, lon))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Button("Change") { showMapPicker = true }
                        .font(.caption)
                        .foregroundStyle(Color.skyLight)
                }
            } else {
                Button {
                    showMapPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "map")
                        Text("Select on map")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.deepTeal.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.diveBlue.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .sheet(isPresented: $showMapPicker) {
            LocationPickerView(latitude: $vm.latitude, longitude: $vm.longitude)
                .onDisappear { updateMapPosition() }
        }
    }

    // MARK: – Rating

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Rating")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        vm.rating = vm.rating == star ? 0 : star
                    } label: {
                        Image(systemName: star <= vm.rating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(star <= vm.rating ? Color.skyLight : .white.opacity(0.3))
                    }
                }
            }
        }
    }

    // MARK: – Buddy

    private var buddyField: some View {
        field(title: "Buddy", text: $vm.buddyName, placeholder: "Buddy name")
    }

    // MARK: – Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            TextEditor(text: $vm.notes)
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(10)
                .background(Color.deepTeal.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.diveBlue.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // MARK: – Error

    @ViewBuilder
    private var errorView: some View {
        if let error = vm.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(error)
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: – Save

    private var saveButton: some View {
        Button {
            Task {
                let success = await vm.save()
                if success { dismiss() }
            }
        } label: {
            HStack(spacing: 8) {
                if vm.isSaving {
                    ProgressView().tint(Color.navyDeep)
                }
                Text(vm.isEditing ? "Update" : "Save")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Color.navyDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.skyLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(vm.isSaving)
    }

    // MARK: – Helpers

    private func field(title: LocalizedStringKey, text: Binding<String>, placeholder: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            TextField(placeholder, text: text)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.deepTeal.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.diveBlue.opacity(0.3), lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
    }

    private func updateMapPosition() {
        if let lat = vm.latitude, let lon = vm.longitude {
            mapPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
}
