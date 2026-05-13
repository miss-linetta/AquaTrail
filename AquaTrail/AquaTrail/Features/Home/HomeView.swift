//
//  HomeView.swift
//  AquaTrail
//

import SwiftUI

struct HomeView: View {
    @State private var vm = HomeViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    locationPanel
                    VStack(spacing: 16) {
                        heroBanner
                        destinationsSection
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 90)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .background(Color.navyDeep)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            vm.start()
            await vm.loadDiveSpots()
        }
        .onChange(of: vm.location.cityName) { _, city in
            vm.cityDidChange(city)
        }
        .onChange(of: vm.location.userLocation) { _, location in
            vm.locationDidChange(location)
        }
    }

    // MARK: – Header

    private var header: some View {
        HStack {
            Color.clear.frame(width: 44, height: 44)

            Spacer()

            Text("AQUATRAIL")
                .font(.title3)
                .fontWeight(.heavy)
                .foregroundStyle(Color.navyDeep)

            Spacer()

            Button { } label: {
                Image(systemName: "person.fill")
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.oceanBlue)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white)
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    // MARK: – Location panel

    private var locationPanel: some View {
        ZStack {
            AsyncImage(url: vm.cityPhotoURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                LinearGradient(
                    colors: [Color.deepTeal, Color.navyDeep],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            LinearGradient(
                colors: [.black.opacity(0.2), .black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 4) {
                Text("Моя локація")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))

                Text(vm.location.cityName)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                if let weather = vm.weather {
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "thermometer.medium")
                                .foregroundStyle(.white.opacity(0.75))
                            Text("\(Int(weather.airTemp.rounded()))°C")
                                .foregroundStyle(.white)
                        }
                        if let waterTemp = weather.waterTemp {
                            HStack(spacing: 6) {
                                Image(systemName: "drop.fill")
                                    .foregroundStyle(.white.opacity(0.75))
                                Text("\(Int(waterTemp.rounded()))°C")
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .clipped()
    }

    // MARK: – Hero banner

    private var heroBanner: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color.deepTeal, Color.navyDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: "figure.open.water.swim")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.skyLight.opacity(0.2))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 24)
                    .padding(.bottom, 50)

                VStack(alignment: .leading, spacing: 8) {
                    Text("ПРИЄДНУЙСЯ")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("Створи акаунт щоб вести щоденник занурень, збирати колекцію видів, керувати спорядженням та отримувати персональні рекомендації маршрутів.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }

            Button { } label: {
                HStack(spacing: 8) {
                    Text("Зареєструватись")
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(Color.navyDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.skyLight)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.diveBlue.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.oceanBlue.opacity(0.3), radius: 16, y: 6)
        .padding(.horizontal, 16)
    }

    // MARK: – Destinations

    private var destinationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Місця поруч")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
                Button("Всі місця") { }
                    .font(.subheadline)
                    .foregroundStyle(Color.skyLight)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.sortedSpots) { spot in
                        destinationCard(spot)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 20)
    }

    private func destinationCard(_ spot: DiveSpot) -> some View {
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
            .frame(width: 220, height: 260)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )

            VStack(alignment: .leading, spacing: 2) {
                if let km = spot.distanceKm(from: vm.location.userLocation) {
                    Text("Відстань")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("\(km) km")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Text(spot.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(16)
            .frame(width: 220, height: 260, alignment: .bottomLeading)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.5), .clear, .black.opacity(0.3)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
        .frame(width: 220, height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    HomeView()
}
