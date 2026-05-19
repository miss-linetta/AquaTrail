//
//  DiveSpotDetailView.swift
//  AquaTrail
//

import SwiftUI
import MapKit

struct DiveSpotDetailView: View {
    let spot: DiveSpot
    let userLocation: CLLocation?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroImage
                content
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.navyDeep)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: – Hero

    private var heroImage: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: spot.photoUrl.flatMap { URL(string: $0) }) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                LinearGradient(
                    colors: [Color.deepTeal, Color.navyDeep],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(maxWidth: .infinity, minHeight: 320)
            .clipped()

            LinearGradient(
                colors: [.clear, Color.navyDeep],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                if let km = spot.distanceKm(from: userLocation) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text("\(km) км від вас")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(20)
        }
    }

    // MARK: – Content

    private var content: some View {
        VStack(spacing: 20) {
            quickInfoGrid
            if let description = spot.description, !description.isEmpty {
                descriptionSection(description)
            }
            conditionsSection
            requirementsSection
            mapSection
            logDiveButton
        }
        .padding(16)
        .padding(.bottom, 40)
    }

    // MARK: – Log dive

    private var logDiveButton: some View {
        NavigationLink {
            DiveLogFormView(prefillSpot: spot)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "pencil.and.list.clipboard")
                Text("Записати занурення")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.oceanBlue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: – Quick info

    private var quickInfoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if let depth = spot.maxDepth {
                infoCard(icon: "arrow.down.to.line", title: "Макс. глибина", value: "\(depth) м")
            }
            if let difficulty = spot.difficulty {
                infoCard(icon: "gauge.medium", title: "Складність", value: difficulty)
            }
            if let entry = spot.entryType {
                infoCard(icon: "figure.walk", title: "Вхід", value: entry)
            }
            if let season = spot.bestSeason {
                infoCard(icon: "calendar", title: "Найкращий сезон", value: season)
            }
        }
    }

    private func infoCard(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.skyLight)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.deepTeal.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: – Description

    private func descriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Опис")
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: – Conditions

    private var conditionsSection: some View {
        let rows: [(String, String, String)] = [
            spot.visibilitySummerM.map { ("eye.fill", "Видимість (літо)", "\($0) м") },
            spot.visibilityWinterM.map { ("eye.fill", "Видимість (зима)", "\($0) м") },
            spot.waterTempSurfaceC.map { ("thermometer.medium", "Темп. поверхні", "\($0)°C") },
            spot.waterTempBottomC.map { ("thermometer.snowflake", "Темп. на дні", "\($0)°C") },
            spot.thermoclineDepthM.map { ("water.waves", "Термоклін", "\($0) м") },
        ].compactMap { $0 }

        return Group {
            if !rows.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionTitle("Умови")
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                            conditionRow(icon: row.0, title: row.1, value: row.2)
                            if index < rows.count - 1 {
                                Divider().background(.white.opacity(0.15))
                            }
                        }
                    }
                    .background(Color.deepTeal.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func conditionRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.skyLight)
                .frame(width: 28)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: – Requirements

    private var requirementsSection: some View {
        let rows: [(String, String, String)] = [
            spot.minCertification.map { ("checkmark.seal.fill", "Мін. сертифікація", $0) },
            spot.minDives.map { ("number", "Мін. занурень", "\($0)") },
            spot.drysuitRecommended == true ? ("suit.fill", "Сухий костюм", "Рекомендовано") : nil,
            spot.access.map { ("road.lanes", "Доступ", $0) },
            spot.infrastructure.map { ("building.2.fill", "Інфраструктура", $0) },
        ].compactMap { $0 }

        return Group {
            if !rows.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionTitle("Вимоги")
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                            conditionRow(icon: row.0, title: row.1, value: row.2)
                            if index < rows.count - 1 {
                                Divider().background(.white.opacity(0.15))
                            }
                        }
                    }
                    .background(Color.deepTeal.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: – Map

    @State private var showNavigationSheet = false

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("На карті")
            Map(initialPosition: .region(MKCoordinateRegion(
                center: spot.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))) {
                Marker(spot.name, coordinate: spot.coordinate)
                    .tint(Color.oceanBlue)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .mapControlVisibility(.hidden)
            .onTapGesture {
                showNavigationSheet = true
            }

            Button {
                showNavigationSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    Text("Прокласти маршрут")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.navyDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.skyLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .confirmationDialog("Відкрити в", isPresented: $showNavigationSheet) {
            Button("Apple Maps") { openAppleMaps() }
            Button("Google Maps") { openGoogleMaps() }
            Button("Waze") { openWaze() }
            Button("Скасувати", role: .cancel) { }
        }
    }

    private func openAppleMaps() {
        let url = URL(string: "http://maps.apple.com/?daddr=\(spot.latitude),\(spot.longitude)")!
        UIApplication.shared.open(url)
    }

    private func openGoogleMaps() {
        let gm = URL(string: "comgooglemaps://?daddr=\(spot.latitude),\(spot.longitude)&directionsmode=driving")!
        if UIApplication.shared.canOpenURL(gm) {
            UIApplication.shared.open(gm)
        } else {
            let web = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(spot.latitude),\(spot.longitude)")!
            UIApplication.shared.open(web)
        }
    }

    private func openWaze() {
        let waze = URL(string: "waze://?ll=\(spot.latitude),\(spot.longitude)&navigate=yes")!
        if UIApplication.shared.canOpenURL(waze) {
            UIApplication.shared.open(waze)
        } else {
            let web = URL(string: "https://waze.com/ul?ll=\(spot.latitude),\(spot.longitude)&navigate=yes")!
            UIApplication.shared.open(web)
        }
    }

    // MARK: – Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.white)
    }
}
