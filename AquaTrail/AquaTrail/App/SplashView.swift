//
//  SplashView.swift
//  AquaTrail
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.navyDeep, Color.deepTeal, Color.navyDeep],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.skyLight.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 40)

            VStack(spacing: 24) {
                Image(systemName: "figure.open.water.swim")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.skyLight)

                Text("AQUATRAIL")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(.white)

                Text("Dive deeper. Explore more.")
                    .font(.subheadline)
                    .foregroundStyle(Color.skyLight.opacity(0.7))
            }
        }
    }
}
