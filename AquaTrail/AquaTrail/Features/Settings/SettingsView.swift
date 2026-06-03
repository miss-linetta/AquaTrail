//
//  SettingsView.swift
//  AquaTrail
//

import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var vm = SettingsViewModel()
    @State private var showAuth = false


    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                if authVM.isAuthenticated {
                    profileSection
                }
                aboutSection
                authSection
                if authVM.isAuthenticated {
                    deleteSection
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.navyDeep)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                if authVM.isAuthenticated {
                    await vm.loadProfile()
                }
            }
            .onChange(of: authVM.isAuthenticated) { _, isAuth in
                if isAuth {
                    Task { await vm.loadProfile() }
                    showAuth = false
                }
            }
            .alert("Delete account?", isPresented: $vm.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        vm.isDeleting = true
                        await authVM.deleteAccount()
                        vm.isDeleting = false
                    }
                }
            } message: {
                Text("This will permanently delete your profile, all log entries and your account. This action cannot be undone.")
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
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section {
            NavigationLink {
                ProfileView()
                    .environment(authVM)
            } label: {
                HStack(spacing: 14) {
                    if let url = vm.avatarURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            profilePlaceholder
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                    } else {
                        profilePlaceholder
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.displayName ?? "Profile")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                        Text(vm.certification ?? "Edit profile")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listRowBackground(Color.deepTeal.opacity(0.5))
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(Color.deepTeal)
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundStyle(Color.skyLight)
            )
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            LabeledContent("App name") {
                Text("AquaTrail")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)

            LabeledContent("Version") {
                Text(appVersion)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)

            LabeledContent("Author") {
                Text("Petrovych Nataliia")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)
        } header: {
            Text("About")
                .foregroundStyle(Color.skyLight)
        }
        .listRowBackground(Color.deepTeal.opacity(0.5))
    }

    // MARK: - Auth

    private var authSection: some View {
        Section {
            if authVM.isAuthenticated {
                Button {
                    authVM.signOut()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign out")
                    }
                    .foregroundStyle(.white)
                }
            } else {
                Button {
                    showAuth = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.key.fill")
                        Text("Sign in")
                    }
                    .foregroundStyle(Color.skyLight)
                }
            }
        }
        .listRowBackground(Color.deepTeal.opacity(0.5))
    }

    // MARK: - Delete

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                vm.showDeleteConfirmation = true
            } label: {
                HStack {
                    if vm.isDeleting {
                        ProgressView()
                            .tint(.red)
                    } else {
                        Image(systemName: "trash.fill")
                    }
                    Text("Delete account")
                }
            }
            .disabled(vm.isDeleting)
        }
        .listRowBackground(Color.deepTeal.opacity(0.5))
    }
}

#Preview {
    SettingsView()
        .environment(AuthViewModel())
}
