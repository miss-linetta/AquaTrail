//
//  UnsplashPhotoService.swift
//  AquaTrail
//

import Foundation

struct UnsplashPhotoService {
    private static let accessKey = "ElPPp41ginm2y85xPnteFFTLjh-rkXqYkWvkqBclZOY"

    static func fetchPhotoURL(for query: String, width: Int = 800) async throws -> URL? {
        var components = URLComponents(string: "https://api.unsplash.com/search/photos")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "1"),
            URLQueryItem(name: "orientation", value: "landscape"),
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(UnsplashSearchResult.self, from: data)
        guard let photo = result.results.first else { return nil }
        let urlString = photo.urls.regular
        return URL(string: urlString)
    }
}

private struct UnsplashSearchResult: Decodable {
    let results: [UnsplashPhoto]
}

private struct UnsplashPhoto: Decodable {
    let urls: UnsplashURLs
}

private struct UnsplashURLs: Decodable {
    let regular: String
}
