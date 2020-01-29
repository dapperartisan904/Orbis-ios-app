//
//  HandlePresenceEventResponse.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 02/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

struct HandlePresenceEventResponse: Codable {
    let placeSize: PlaceSize?
    let dominance: Dominance?
    let touchedPlaces: [TouchedPlace]?
    let touchedBy: [Touch]?
    let error: String?
    var place: Place? // Transient
    
    init(error: String) {
        self.error = error
        self.placeSize = nil
        self.dominance = nil
        self.touchedPlaces = nil
        self.touchedBy = nil
    }
    
    func toPlaceChange() -> PlaceChange {
        let placeChange = PlaceChange()
        placeChange.placeKey = place?.key
        placeChange.dominantGroupKey = dominance?.winnerGroup?.key
        placeChange.currentSize = placeSize?.actualPlaceSize?.float ?? 0.0
        placeChange.prevSize = placeSize?.prevPlaceSize?.float ?? 0.0
        placeChange.shouldSpin = true
        return placeChange
    }
}

struct Dominance: Codable {
    let eventType: String
    let points: [Point]
    let winnerGroup: Group?
    let loserGroup: Group?
}

struct Point: Codable {
    let checkInCount: Int
    let groupKey, placeKey: String?
    let lastTimeBecomeDominant: Int64?
    let mostRecentCheckinTimestamp: Int64
    let mostRecentCheckinIsExpired: Bool?
    let percentage: Double?
}

struct PlaceSize: Codable {
    let placeKey: String
    let prevPlaceSize: Int?
    let actualPlaceSize: Int?
}

struct TouchedPlace: Codable {
    let key: String
    let size: Int
    let touches: [Touch]
}

struct Touch: Codable {
    let count: Int
    let timestamp: Int64
    let touchedPlaceKey, touchingPlaceKey: String
    let valid: Bool
}

struct TouchesCount : Codable {
    var touchingPlaceKey: String
    var touchedPlaceKey: String
    var count = 0
    var valid: Bool = false
    var timestamp: Int64 = 0
}

// MARK: Encode/decode helpers

class JSONNull: Codable, Hashable {
    
    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }
    
    public var hashValue: Int {
        return 0
    }
    
    public init() {}
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
