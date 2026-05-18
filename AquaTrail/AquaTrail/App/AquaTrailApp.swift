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

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isLoading {
                    ZStack {
                        Color.navyDeep.ignoresSafeArea()
                        ProgressView()
                            .tint(.white)
                    }
                } else {
                    ContentView()
                        .environment(authVM)
                }
            }
            .task {
                await authVM.checkSession()
            }
        }
    }
}
