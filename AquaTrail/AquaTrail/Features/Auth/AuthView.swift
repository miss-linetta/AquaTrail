//
//  AuthView.swift
//  AquaTrail
//

import SwiftUI

struct AuthView: View {
    @Bindable var vm: AuthViewModel
    @State private var isSignUp = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                logo
                form
                if let error = vm.errorMessage {
                    errorBanner(error)
                }
                submitButton
                toggleMode
            }
            .padding(24)
            .padding(.top, 40)
        }
        .background(Color.navyDeep)
    }

    // MARK: – Logo

    private var logo: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.open.water.swim")
                .font(.system(size: 56))
                .foregroundStyle(Color.skyLight)

            Text("AQUATRAIL")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundStyle(.white)

            Text(isSignUp ? "Create account" : "Sign into account")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.bottom, 8)
    }

    // MARK: – Form

    private var form: some View {
        VStack(spacing: 16) {
            field(icon: "envelope.fill", placeholder: "Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)

            field(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)
                .textContentType(isSignUp ? .newPassword : .password)

            if isSignUp {
                field(icon: "lock.fill", placeholder: "Confirm password", text: $confirmPassword, isSecure: true)
                    .textContentType(.newPassword)
            }
        }
    }

    private func field(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.skyLight.opacity(0.7))
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
            }
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(Color.deepTeal.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.diveBlue.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: – Error

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
        }
        .font(.subheadline)
        .foregroundStyle(.white)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: – Submit

    private var canSubmit: Bool {
        let base = !email.isEmpty && password.count >= 6
        if isSignUp {
            return base && password == confirmPassword
        }
        return base
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView()
                        .tint(Color.navyDeep)
                }
                Text(isSignUp ? "Register" : "Sign in")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Color.navyDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canSubmit ? Color.skyLight : Color.skyLight.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!canSubmit || isSubmitting)
    }

    private func submit() {
        isSubmitting = true
        Task {
            if isSignUp {
                await vm.signUp(email: email, password: password)
            } else {
                await vm.signIn(email: email, password: password)
            }
            isSubmitting = false
        }
    }

    // MARK: – Toggle

    private var toggleMode: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSignUp.toggle()
                vm.errorMessage = nil
            }
        } label: {
            HStack(spacing: 4) {
                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                    .foregroundStyle(.white.opacity(0.6))
                Text(isSignUp ? "Sign in" : "Register")
                    .foregroundStyle(Color.skyLight)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
        }
    }
}
