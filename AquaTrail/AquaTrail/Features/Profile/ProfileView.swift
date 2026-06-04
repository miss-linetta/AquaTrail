//
//  ProfileView.swift
//  AquaTrail
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var vm = ProfileViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showFilePicker = false
    @State private var showPhotoSource = false
    @State private var showGallery = false

    private let certifications = ["CMAS 1*", "CMAS 2*", "CMAS 3*", "OWD", "AOWD", "Rescue Diver"]

    var showCloseButton = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                avatar
                formSection
                saveButton
                signOutButton
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Color.navyDeep)
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if showCloseButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .task {
            await vm.load()
        }
        .overlay {
            if vm.isLoading {
                ProgressView()
                    .tint(.white)
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task { await vm.uploadAvatar(from: newItem) }
        }
        .photosPicker(isPresented: $showGallery, selection: $selectedPhoto, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                Task { await vm.uploadAvatar(uiImage: image) }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showFilePicker) {
            DocumentPicker { data in
                Task { await vm.uploadAvatar(data: data) }
            }
        }
    }

    // MARK: – Avatar

    private var avatar: some View {
        VStack(spacing: 12) {
            Button { showPhotoSource = true } label: {
                ZStack {
                    if let image = vm.avatarImage {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.deepTeal)
                            .frame(width: 100, height: 100)

                        Text(initials)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(Color.skyLight)
                    }

                    Circle()
                        .fill(Color.oceanBlue)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                        )
                        .offset(x: 36, y: 36)

                    if vm.isUploadingAvatar {
                        Circle()
                            .fill(.black.opacity(0.5))
                            .frame(width: 100, height: 100)
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
            .confirmationDialog("Choose photo", isPresented: $showPhotoSource) {
                Button("Take photo") { showCamera = true }
                Button("Choose from gallery") { showGallery = true }
                Button("Choose from files") { showFilePicker = true }
                if vm.avatarImage != nil {
                    Button("Delete photo", role: .destructive) {
                        Task { await vm.deleteAvatar() }
                    }
                }
                Button("Cancel", role: .cancel) { }
            }

            if let email = try? supabase.auth.currentSession?.user.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.top, 12)
    }

    private var initials: String {
        let name = vm.displayName
        if name.isEmpty { return "?" }
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    // MARK: – Form

    private var formSection: some View {
        VStack(spacing: 16) {
            field(title: "Name", text: $vm.displayName, placeholder: "What's your name?")

            VStack(alignment: .leading, spacing: 6) {
                Text("Certification")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(certifications, id: \.self) { cert in
                            Button {
                                vm.certification = vm.certification == cert ? "" : cert
                            } label: {
                                Text(cert)
                                    .font(.subheadline)
                                    .foregroundStyle(vm.certification == cert ? Color.navyDeep : .white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(vm.certification == cert ? Color.skyLight : Color.deepTeal.opacity(0.5))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            field(title: "Number of dives", text: $vm.totalDives, placeholder: "0")
                .keyboardType(.numberPad)

            // Interests
            VStack(alignment: .leading, spacing: 6) {
                Text("Interests (for recommendations)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
                    ForEach(ProfileViewModel.allInterests, id: \.self) { interest in
                        let selected = vm.selectedInterests.contains(interest)
                        Button {
                            if selected {
                                vm.selectedInterests.remove(interest)
                            } else {
                                vm.selectedInterests.insert(interest)
                            }
                        } label: {
                            Text(ProfileViewModel.interestLabels[interest] ?? interest)
                                .font(.subheadline)
                                .foregroundStyle(selected ? Color.navyDeep : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selected ? Color.skyLight : Color.deepTeal.opacity(0.5))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

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

            if vm.savedSuccessfully {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Saved")
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

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

    // MARK: – Buttons

    private var saveButton: some View {
        Button {
            Task { await vm.save() }
        } label: {
            HStack(spacing: 8) {
                if vm.isSaving {
                    ProgressView().tint(Color.navyDeep)
                }
                Text("Save")
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

    private var signOutButton: some View {
        Button {
            authVM.signOut()
        } label: {
            Text("Sign out")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 8)
    }
}
