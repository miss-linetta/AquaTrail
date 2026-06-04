//
//  Equipment.swift
//  AquaTrail
//

import Foundation

struct Equipment: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var name: String
    var type: String
    var brand: String?
    var model: String?
    var purchaseDate: String?
    var lastServiceDate: String?
    var hydroTestDate: String?
    var notes: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, type, brand, model, notes
        case purchaseDate = "purchase_date"
        case lastServiceDate = "last_service_date"
        case hydroTestDate = "hydro_test_date"
        case createdAt = "created_at"
    }

    var purchaseDateValue: Date? {
        guard let purchaseDate else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: purchaseDate)
    }

    var lastServiceDateValue: Date? {
        guard let lastServiceDate else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: lastServiceDate)
    }

    var hydroTestDateValue: Date? {
        guard let hydroTestDate else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: hydroTestDate)
    }

    static func dateString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    static let allTypes = [
        "regulator", "bcd", "wetsuit", "drysuit", "mask",
        "fins", "computer", "torch", "tank"
    ]

    static let typeIcons: [String: String] = [
        "regulator": "gauge.with.dots.needle.bottom.50percent",
        "bcd": "lifejacket.fill",
        "wetsuit": "figure.dress.line.vertical.figure",
        "drysuit": "snowflake",
        "mask": "eyeglasses",
        "fins": "shoe.fill",
        "computer": "applewatch",
        "torch": "flashlight.on.fill",
        "tank": "cylinder.fill"
    ]

    static let typeLabelsEn: [String: String] = [
        "regulator": "Regulator", "bcd": "BCD", "wetsuit": "Wetsuit",
        "drysuit": "Drysuit", "mask": "Mask", "fins": "Fins",
        "computer": "Computer", "torch": "Torch", "tank": "Tank"
    ]

    static let typeLabelsUk: [String: String] = [
        "regulator": "Регулятор", "bcd": "BCD", "wetsuit": "Мокрий костюм",
        "drysuit": "Сухий костюм", "mask": "Маска", "fins": "Ласти",
        "computer": "Комп'ютер", "torch": "Ліхтар", "tank": "Балон"
    ]

    static func localizedTypeLabel(_ type: String) -> String {
        if DiveSpot.isAppEnglish {
            return typeLabelsEn[type] ?? type.capitalized
        }
        return typeLabelsUk[type] ?? type.capitalized
    }

    var localizedType: String {
        Self.localizedTypeLabel(type)
    }

    var typeIcon: String {
        Self.typeIcons[type] ?? "wrench.fill"
    }

    // MARK: – Service intervals (months)

    static let serviceIntervalMonths: [String: Int] = [
        "regulator": 12,
        "bcd": 12,
        "drysuit": 12,
        "computer": 18,
        "tank": 12,
        "wetsuit": 0,
        "mask": 0,
        "fins": 0,
        "torch": 0
    ]

    var serviceIntervalMonths: Int {
        Self.serviceIntervalMonths[type] ?? 0
    }

    var needsService: Bool {
        serviceIntervalMonths > 0 && serviceStatus == .overdue
    }

    var serviceStatus: ServiceStatus {
        guard serviceIntervalMonths > 0 else { return .notRequired }
        guard let lastService = lastServiceDateValue else { return .unknown }
        let calendar = Calendar.current
        guard let dueDate = calendar.date(byAdding: .month, value: serviceIntervalMonths, to: lastService) else { return .unknown }
        let now = Date()
        let daysUntilDue = calendar.dateComponents([.day], from: now, to: dueDate).day ?? 0

        if daysUntilDue < 0 { return .overdue }
        if daysUntilDue <= 30 { return .dueSoon }
        return .ok
    }

    // MARK: – Hydrostatic test (tanks only, every 5 years)

    var hydroTestStatus: ServiceStatus {
        guard type == "tank" else { return .notRequired }
        guard let lastTest = hydroTestDateValue else { return .unknown }
        let calendar = Calendar.current
        guard let dueDate = calendar.date(byAdding: .month, value: 60, to: lastTest) else { return .unknown }
        let now = Date()
        let daysUntilDue = calendar.dateComponents([.day], from: now, to: dueDate).day ?? 0

        if daysUntilDue < 0 { return .overdue }
        if daysUntilDue <= 90 { return .dueSoon }
        return .ok
    }

    /// Worst status across service + hydro test
    var worstStatus: ServiceStatus {
        let statuses = [serviceStatus, hydroTestStatus].filter { $0 != .notRequired }
        if statuses.contains(.overdue) { return .overdue }
        if statuses.contains(.dueSoon) { return .dueSoon }
        if statuses.contains(.unknown) { return .unknown }
        if statuses.contains(.ok) { return .ok }
        return .notRequired
    }

    enum ServiceStatus {
        case ok, dueSoon, overdue, unknown, notRequired

        var label: String {
            switch self {
            case .ok: return String(localized: "Service OK")
            case .dueSoon: return String(localized: "Service due soon")
            case .overdue: return String(localized: "Service overdue")
            case .unknown: return String(localized: "No service date")
            case .notRequired: return ""
            }
        }

        var color: String {
            switch self {
            case .ok: return "green"
            case .dueSoon: return "orange"
            case .overdue: return "red"
            case .unknown: return "gray"
            case .notRequired: return "clear"
            }
        }
    }
}

struct EquipmentInsert: Encodable {
    var userId: UUID
    var name: String
    var type: String
    var brand: String?
    var model: String?
    var purchaseDate: String?
    var lastServiceDate: String?
    var hydroTestDate: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name, type, brand, model, notes
        case purchaseDate = "purchase_date"
        case lastServiceDate = "last_service_date"
        case hydroTestDate = "hydro_test_date"
    }
}

struct EquipmentUpdate: Encodable {
    var name: String
    var type: String
    var brand: String?
    var model: String?
    var purchaseDate: String?
    var lastServiceDate: String?
    var hydroTestDate: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case name, type, brand, model, notes
        case purchaseDate = "purchase_date"
        case lastServiceDate = "last_service_date"
        case hydroTestDate = "hydro_test_date"
    }
}
