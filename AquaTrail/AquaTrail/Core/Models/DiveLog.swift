//
//  DiveLog.swift
//  AquaTrail
//

import Foundation

struct DiveLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var diveSpotId: UUID?
    var spotName: String
    var date: String
    var depth: Int
    var duration: Int
    var waterTemp: Int?
    var visibility: Int?
    var entryType: String?
    var difficulty: String?
    var rating: Int?
    var notes: String?
    var buddyName: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case diveSpotId = "dive_spot_id"
        case spotName = "spot_name"
        case date
        case depth
        case duration
        case waterTemp = "water_temp"
        case visibility
        case entryType = "entry_type"
        case difficulty
        case rating
        case notes
        case buddyName = "buddy_name"
        case createdAt = "created_at"
    }

    var dateValue: Date {
        get {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.date(from: date) ?? Date()
        }
    }

    static func dateString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

struct DiveLogInsert: Encodable {
    var userId: UUID
    var diveSpotId: UUID?
    var spotName: String
    var date: String
    var depth: Int
    var duration: Int
    var waterTemp: Int?
    var visibility: Int?
    var entryType: String?
    var difficulty: String?
    var rating: Int?
    var notes: String?
    var buddyName: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case diveSpotId = "dive_spot_id"
        case spotName = "spot_name"
        case date
        case depth
        case duration
        case waterTemp = "water_temp"
        case visibility
        case entryType = "entry_type"
        case difficulty
        case rating
        case notes
        case buddyName = "buddy_name"
    }
}

struct DiveLogUpdate: Encodable {
    var diveSpotId: UUID?
    var spotName: String
    var date: String
    var depth: Int
    var duration: Int
    var waterTemp: Int?
    var visibility: Int?
    var entryType: String?
    var difficulty: String?
    var rating: Int?
    var notes: String?
    var buddyName: String?

    enum CodingKeys: String, CodingKey {
        case diveSpotId = "dive_spot_id"
        case spotName = "spot_name"
        case date
        case depth
        case duration
        case waterTemp = "water_temp"
        case visibility
        case entryType = "entry_type"
        case difficulty
        case rating
        case notes
        case buddyName = "buddy_name"
    }
}
