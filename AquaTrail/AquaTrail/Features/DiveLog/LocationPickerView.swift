//
//  LocationPickerView.swift
//  AquaTrail
//

import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    @Binding var latitude: Double?
    @Binding var longitude: Double?
    @Environment(\.dismiss) private var dismiss

    @State private var pin: CLLocationCoordinate2D?
    @State private var position: MapCameraPosition
    @State private var locationManager = CLLocationManager()

    private let hasExistingCoord: Bool

    init(latitude: Binding<Double?>, longitude: Binding<Double?>) {
        _latitude = latitude
        _longitude = longitude

        if let lat = latitude.wrappedValue, let lon = longitude.wrappedValue {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            _pin = State(initialValue: coord)
            _position = State(initialValue: .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )))
            hasExistingCoord = true
        } else {
            _position = State(initialValue: .userLocation(fallback: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 48.38, longitude: 31.17),
                span: MKCoordinateSpan(latitudeDelta: 6, longitudeDelta: 6)
            ))))
            hasExistingCoord = false
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MapReader { proxy in
                    Map(position: $position) {
                        UserAnnotation()
                        if let pin {
                            Marker("Dive spot", coordinate: pin)
                                .tint(Color.oceanBlue)
                        }
                    }
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                    }
                    .onTapGesture { screenCoord in
                        if let coordinate = proxy.convert(screenCoord, from: .local) {
                            pin = coordinate
                        }
                    }
                }

                VStack {
                    Spacer()
                    if let pin {
                        Text(String(format: "%.4f, %.4f", pin.latitude, pin.longitude))
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(.bottom, 8)
                    }

                    Text("Tap the map to select a location")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Select location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        latitude = pin?.latitude
                        longitude = pin?.longitude
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.skyLight)
                    .disabled(pin == nil)
                }
            }
        }
    }
}
