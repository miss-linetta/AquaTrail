//
//  DiveLogFormView.swift
//  AquaTrail
//

import SwiftUI

struct DiveLogFormView: View {
    @State private var vm = DiveLogFormViewModel()
    @Environment(\.dismiss) private var dismiss

    var editLog: DiveLog?
    var prefillSpot: DiveSpot?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Spot name
                field(title: "Місце занурення", text: $vm.spotName, placeholder: "Назва дайв-споту")

                // Date
                VStack(alignment: .leading, spacing: 6) {
                    Text("Дата")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    DatePicker("", selection: $vm.date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(.dark)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Depth & Duration
                HStack(spacing: 12) {
                    field(title: "Глибина (м)", text: $vm.depthText, placeholder: "0")
                        .keyboardType(.numberPad)
                    field(title: "Тривалість (хв)", text: $vm.durationText, placeholder: "0")
                        .keyboardType(.numberPad)
                }

                // Water temp & Visibility
                HStack(spacing: 12) {
                    field(title: "Темп. води (°C)", text: $vm.waterTempText, placeholder: "—")
                        .keyboardType(.numberPad)
                    field(title: "Видимість (м)", text: $vm.visibilityText, placeholder: "—")
                        .keyboardType(.numberPad)
                }

                // Entry type
                VStack(alignment: .leading, spacing: 6) {
                    Text("Тип входу")
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

                // Difficulty
                VStack(alignment: .leading, spacing: 6) {
                    Text("Складність")
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

                // Rating
                VStack(alignment: .leading, spacing: 6) {
                    Text("Оцінка")
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

                // Buddy
                field(title: "Бадді", text: $vm.buddyName, placeholder: "Ім'я напарника")

                // Notes
                VStack(alignment: .leading, spacing: 6) {
                    Text("Нотатки")
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

                // Error
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

                // Save button
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
                        Text(vm.isEditing ? "Оновити" : "Зберегти")
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
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Color.navyDeep)
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationTitle(vm.isEditing ? "Редагувати" : "Нове занурення")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            if let log = editLog {
                vm.loadForEdit(log)
            } else if let spot = prefillSpot {
                vm.loadFromSpot(spot)
            }
        }
    }

    private func field(title: String, text: Binding<String>, placeholder: String) -> some View {
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
