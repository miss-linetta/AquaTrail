//
//  ContentView.swift
//  AquaTrail
//
//  Created by admin on 06.05.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            DiveLogListView()
                .tabItem { Label("Dive Log", systemImage: "book.fill") }

            PlanningView()
                .tabItem { Label("Planning", systemImage: "map.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(.cyan)
    }
}

#Preview {
    ContentView()
}
