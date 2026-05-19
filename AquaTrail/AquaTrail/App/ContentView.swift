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
                .tabItem { Label("Головна", systemImage: "house.fill") }

            DiveLogListView()
                .tabItem { Label("Щоденник", systemImage: "book.fill") }

            Text("Планування")
                .tabItem { Label("Планування", systemImage: "map.fill") }

            Text("Налаштування")
                .tabItem { Label("Налаштування", systemImage: "gearshape") }
        }
        .tint(.cyan)
    }
}

#Preview {
    ContentView()
}
