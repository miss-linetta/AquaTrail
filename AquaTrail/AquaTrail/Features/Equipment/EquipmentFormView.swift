//
//  EquipmentFormView.swift
//  AquaTrail
//

import SwiftUI

struct EquipmentFormView: View {
    @State private var vm = EquipmentFormViewModel()
    @Environment(\.dismiss) private var dismiss

    var editItem: Equipment?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                nameField
                typeSection
                brandModelRow
                purchaseDateSection
                serviceDateSection
                if vm.type == "tank" {
                    hydroTestSection
                }
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
        .navigationTitle(vm.isEditing ? "Edit" : "New equipment")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            if let item = editItem {
                vm.loadForEdit(item)
            }
        }
    }

    // MARK: – Name

    private var nameField: some View {
        field(title: "Name", text: $vm.name, placeholder: "Equipment name")
    }

    // MARK: – Type

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Type")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Equipment.allTypes, id: \.self) { type in
                        Button {
                            vm.type = type
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: Equipment.typeIcons[type] ?? "wrench.fill")
                                    .font(.caption)
                                Text(Equipment.localizedTypeLabel(type))
                                    .font(.subheadline)
                            }
                            .foregroundStyle(vm.type == type ? Color.navyDeep : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(vm.type == type ? Color.skyLight : Color.deepTeal.opacity(0.5))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: – Brand & Model

    private var brandModelRow: some View {
        HStack(spacing: 12) {
            field(title: "Brand", text: $vm.brand, placeholder: "Scubapro")
            field(title: "Model", text: $vm.model, placeholder: "MK25")
        }
    }

    // MARK: – Purchase date

    private var purchaseDateSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: $vm.hasPurchaseDate) {
                Text("Purchase date")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .tint(Color.skyLight)

            if vm.hasPurchaseDate {
                DatePicker("", selection: $vm.purchaseDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: – Service date

    private var serviceDateSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: $vm.hasServiceDate) {
                Text("Last service")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .tint(Color.skyLight)

            if vm.hasServiceDate {
                DatePicker("", selection: $vm.lastServiceDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: – Hydrostatic test (tank only)

    private var hydroTestSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: $vm.hasHydroTestDate) {
                Text("Hydrostatic test")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .tint(Color.skyLight)

            if vm.hasHydroTestDate {
                DatePicker("", selection: $vm.hydroTestDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)

                Text("Next test: in 5 years")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
}
