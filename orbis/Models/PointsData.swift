//
//  PointsData.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 16/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class PointsData : Codable {
    var groupKey: String
    var placeKey: String
    //var lastCheckIn: PresenceEvent!
    //var checkInCount: Int?
    //var lastTimeBecomeDominant: Int64?
    //var mostRecentCheckinIsExpired: Int?
    //var mostRecentCheckinTimestamp: Int64?
    var percentage: Double
    //var circleSize: Double = 0.0
    
    enum Keys: CodingKey {
        case groupKey
        case placeKey
        case percentage
    }
    
    init(groupKey: String, placeKey: String, percentage: Double) {
        self.groupKey = groupKey
        self.placeKey = placeKey
        self.percentage = percentage
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let groupKey: String = try container.decode(String.self, forKey: .groupKey)
        let placeKey: String = try container.decode(String.self, forKey: .placeKey)
        let percentage: Double = try container.decode(Double.self, forKey: .percentage)
        self.init(groupKey: groupKey, placeKey: placeKey, percentage: percentage)
    }
}

class PointsDataResponse : Codable {
    var result: [PointsData]
}
