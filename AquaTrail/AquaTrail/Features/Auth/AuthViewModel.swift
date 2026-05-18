//
//  AuthViewModel.swift
//  AquaTrail
//

import Foundation
import Observation
import Supabase

@Observable
@MainActor
class AuthViewModel {
    var isAuthenticated = false
    var isLoading = true
    var errorMessage: String?

    func checkSession() async {
        defer { isLoading = false }
        do {
            _ = try await supabase.auth.session
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }

    func signUp(email: String, password: String) async {
        errorMessage = nil
        do {
            try await supabase.auth.signUp(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = mapError(error)
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            try await supabase.auth.signIn(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = mapError(error)
        }
    }

    func signOut() {
        Task {
            try? await supabase.auth.signOut(scope: .local)
            isAuthenticated = false
        }
    }

    private func mapError(_ error: Error) -> String {
        let message = error.localizedDescription
        if message.contains("Invalid login") || message.contains("invalid_credentials") {
            return "Невірний email або пароль"
        }
        if message.contains("already registered") || message.contains("already been registered") {
            return "Цей email вже зареєстрований"
        }
        if message.contains("valid email") {
            return "Введіть коректний email"
        }
        if message.contains("at least") || message.contains("too short") {
            return "Пароль має бути не менше 6 символів"
        }
        return "Помилка: \(message)"
    }
}
