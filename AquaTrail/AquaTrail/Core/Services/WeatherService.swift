//
//  WeatherService.swift
//  AquaTrail
//

import Foundation

struct WeatherData {
    let airTemp: Double?
    let waterTemp: Double?
}

struct WeatherService {
    static func fetch(latitude: Double, longitude: Double) async -> WeatherData {
        async let airTemp = fetchAirTemperature(latitude: latitude, longitude: longitude)
        async let waterTemp = fetchWaterTemperature(latitude: latitude, longitude: longitude)
        return WeatherData(airTemp: try? await airTemp, waterTemp: try? await waterTemp)
    }

    private static func fetchAirTemperature(latitude: Double, longitude: Double) async throws -> Double {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m&temperature_unit=celsius"
        let (data, _) = try await URLSession.shared.data(from: URL(string: urlString)!)
        return try JSONDecoder().decode(OpenMeteoResponse.self, from: data).current.temperature2m
    }

    private static func fetchWaterTemperature(latitude: Double, longitude: Double) async throws -> Double {
        let urlString = "https://marine-api.open-meteo.com/v1/marine?latitude=\(latitude)&longitude=\(longitude)&current=sea_surface_temperature&temperature_unit=celsius"
        let (data, _) = try await URLSession.shared.data(from: URL(string: urlString)!)
        return try JSONDecoder().decode(MarineResponse.self, from: data).current.seaSurfaceTemperature
    }
}

private struct OpenMeteoResponse: Decodable {
    let current: Current
    struct Current: Decodable {
        let temperature2m: Double
        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
        }
    }
}

private struct MarineResponse: Decodable {
    let current: Current
    struct Current: Decodable {
        let seaSurfaceTemperature: Double
        enum CodingKeys: String, CodingKey {
            case seaSurfaceTemperature = "sea_surface_temperature"
        }
    }
}
