//
//  SettingsViewModel.swift
//  AquaTrail
//

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
class SettingsViewModel {
    var displayName: String?
    var certification: String?
    var avatarURL: URL?
    var showDeleteConfirmation = false
    var isDeleting = false
    var errorMessage: String?

    func loadProfile() async {
        do {
            let userId = try await supabase.auth.session.user.id
            let profile = try await ProfileService.fetch(userId: userId)
            displayName = profile.displayName
            certification = profile.certification
            if let urlString = profile.avatarUrl {
                avatarURL = URL(string: urlString)
            }
        } catch { }
    }
}
