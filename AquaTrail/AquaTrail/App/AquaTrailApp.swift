//
//  AquaTrailApp.swift
//  AquaTrail
//
//  Created by admin on 06.05.2026.
//

import SwiftUI

@main
struct AquaTrailApp: App {
    @State private var authVM = AuthViewModel()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authVM.isLoading {
                    Color.navyDeep.ignoresSafeArea()
                } else {
                    ContentView()
                        .environment(authVM)
                }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                await authVM.checkSession()
                try? await Task.sleep(for: .seconds(1.8))
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}
