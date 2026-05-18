//
//  ProfileViewModel.swift
//  AquaTrail
//

import Foundation
import Observation
import Supabase
import SwiftUI
import PhotosUI

@Observable
@MainActor
class ProfileViewModel {
    var profile: Profile?
    var isLoading = false
    var isSaving = false
    var isUploadingAvatar = false
    var errorMessage: String?
    var savedSuccessfully = false
    var avatarImage: Image?

    // Editable fields
    var displayName = ""
    var certification = ""
    var totalDives = ""

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let userId = try await supabase.auth.session.user.id
            do {
                let p = try await ProfileService.fetch(userId: userId)
                profile = p
            } catch {
                let newProfile = Profile(id: userId)
                try await ProfileService.insert(newProfile)
                profile = newProfile
            }
            displayName = profile?.displayName ?? ""
            certification = profile?.certification ?? ""
            totalDives = profile?.totalDives.map { "\($0)" } ?? ""
            await loadAvatarImage()
        } catch {
            errorMessage = "Не вдалось завантажити профіль: \(error.localizedDescription)"
        }
    }

    func save() async {
        guard var profile else { return }
        isSaving = true
        savedSuccessfully = false
        defer { isSaving = false }
        do {
            profile.displayName = displayName.isEmpty ? nil : displayName
            profile.certification = certification.isEmpty ? nil : certification
            profile.totalDives = Int(totalDives)
            try await ProfileService.update(profile)
            self.profile = profile
            savedSuccessfully = true
        } catch {
            errorMessage = "Не вдалось зберегти: \(error.localizedDescription)"
        }
    }

    func uploadAvatar(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        await uploadAvatar(uiImage: uiImage)
    }

    func uploadAvatar(uiImage: UIImage) async {
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.7) else { return }
        await uploadJPEG(jpegData, preview: Image(uiImage: uiImage))
    }

    func uploadAvatar(data: Data) async {
        guard let uiImage = UIImage(data: data) else {
            errorMessage = "Не вдалось прочитати зображення"
            return
        }
        await uploadAvatar(uiImage: uiImage)
    }

    private func uploadJPEG(_ jpegData: Data, preview: Image) async {
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        do {
            let userId = try await supabase.auth.session.user.id
            let path = "\(userId.uuidString)/avatar.jpg"

            do {
                try await supabase.storage
                    .from("avatars")
                    .upload(path, data: jpegData, options: .init(contentType: "image/jpeg", upsert: true))
            } catch {
                errorMessage = "Storage upload: \(error.localizedDescription)"
                return
            }

            let publicURL = try supabase.storage
                .from("avatars")
                .getPublicURL(path: path)
            let finalURL = publicURL.absoluteString + "?t=\(Int(Date().timeIntervalSince1970))"

            if var p = profile {
                p.avatarUrl = finalURL
                try await ProfileService.update(p)
                profile = p
            }

            avatarImage = preview
        } catch {
            errorMessage = "Не вдалось завантажити фото: \(error.localizedDescription)"
        }
    }

    func deleteAvatar() async {
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        do {
            let userId = try await supabase.auth.session.user.id
            let path = "\(userId.uuidString)/avatar.jpg"

            try await supabase.storage
                .from("avatars")
                .remove(paths: [path])

            if var p = profile {
                p.avatarUrl = nil
                try await ProfileService.update(p)
                profile = p
            }

            avatarImage = nil
        } catch {
            errorMessage = "Не вдалось видалити фото: \(error.localizedDescription)"
        }
    }

    private func loadAvatarImage() async {
        guard let urlString = profile?.avatarUrl,
              let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                avatarImage = Image(uiImage: uiImage)
            }
        } catch { }
    }
}
