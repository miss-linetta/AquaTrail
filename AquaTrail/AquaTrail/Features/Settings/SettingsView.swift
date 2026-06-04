//
//  SettingsView.swift
//  AquaTrail
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.requestReview) private var requestReview
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
                languageSection
                aboutSection
                shareSection
                authSection
                if authVM.isAuthenticated {
                    deleteSection
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 16, for: .scrollContent)
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
        .listRowBackground(Color.slateTeal)
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(Color.slateTeal)
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundStyle(Color.skyLight)
            )
    }

    // MARK: - Language

    private var languageSection: some View {
        Section {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "globe")
                    Text("Language")
                    Spacer()
                    Text(Locale.current.localizedString(forLanguageCode: Bundle.main.preferredLocalizations.first ?? "en")?.capitalized ?? "")
                        .foregroundStyle(Color.mistGray)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.mistGray)
                }
                .foregroundStyle(.white)
            }
        }
        .listRowBackground(Color.slateTeal)
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            LabeledContent("App name") {
                Text("AquaTrail")
                    .foregroundStyle(Color.mistGray)
            }
            .foregroundStyle(.white)

            LabeledContent("Version") {
                Text(appVersion)
                    .foregroundStyle(Color.mistGray)
            }
            .foregroundStyle(.white)

        } header: {
            Text("About")
                .foregroundStyle(Color.skyLight)
        }
        .listRowBackground(Color.slateTeal)
    }

    // MARK: - Share & Rate

    private let appURL = URL(string: "https://apps.apple.com/app/aquatrail/id0000000000")!

    private var shareSection: some View {
        Section {
            Button {
                requestReview()
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Rate the app")
                }
                .foregroundStyle(Color.skyLight)
            }

            ShareLink(item: appURL) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share AquaTrail")
                }
                .foregroundStyle(.white)
            }
        }
        .listRowBackground(Color.slateTeal)
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
                    .foregroundStyle(Color.coralAccent)
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
        .listRowBackground(Color.slateTeal)
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
        .listRowBackground(Color.slateTeal)
    }
}

#Preview {
    SettingsView()
        .environment(AuthViewModel())
}
