//
//  OrbisPost.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 04/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import FirebaseFirestore

class OrbisPost : Codable, Hashable, Equatable {
    
    static func == (lhs: OrbisPost, rhs: OrbisPost) -> Bool {
        return lhs.postKey == rhs.postKey
    }
    
    var hashValue: Int {
        get {
            return postKey.hashValue
        }
    }
    
    var serverTimestamp: Int64!
    var serverTimestamp2: Int64!
    var type: String!
    var postKey: String!
    var placeKey: String?
    var winnerGroupKey: String?
    var loserGroupKey: String?
    var userKey: String?
    var imageUrls: [String]?
    var title: String?
    var details: String?
    var link: String?
    var eventGroup: [OrbisPost]?

    // TODO KINE: richLinkData
    //var richLinkData: RichLinkData? = null

    var sponsored: Bool?

    /*
        Will be false when upload is in progress
     */
    var available: Bool?

    // Transient
    var willBeAvailable: Bool?

    /*
        These fields are copied from place
     */
    var coordinates: Coordinates?
    var geohash: String?

    // Related to Add Event -> Date
    var dateTimestamp: Int64?

    // Related to Add Event -> Hour
    var timeTimestamp: Int64?

    var timestamp: Int64?

    /*
    // Can be either post or user coordinates
    @Transient
    @Exclude
    var coordinatesToCalcDistance: Coordinates? = null; private set
    */

    var serverDate: Date? = nil
    
    func typeEnum() -> PostType? {
        return PostType(rawValue: type)
    }

    init(
         coordinates: Coordinates?,
         geohash: String?,
         imageUrls: [String]?,
         postKey: String,
         timestamp: Int64?,
         serverTimestamp: Int64,
         serverTimestamp2: Int64?,
         dateTimestamp: Int64?,
         timeTimestamp: Int64?,
         sponsored: Bool?,
         title: String?,
         details: String?,
         type: String,
         placeKey: String?,
         userKey: String?,
         winnerGroupKey: String?,
         loserGroupKey: String?,
         link: String?
     ) {
        self.coordinates = coordinates
        self.geohash = geohash
        self.imageUrls = imageUrls
        self.postKey = postKey
        self.timestamp = timestamp
        self.serverTimestamp = serverTimestamp
        self.serverTimestamp2 = serverTimestamp2
        self.dateTimestamp = dateTimestamp
        self.timeTimestamp = timeTimestamp
        self.sponsored = sponsored
        self.title = title
        self.details = details
        self.type = type
        self.userKey = userKey
        self.winnerGroupKey = winnerGroupKey
        self.loserGroupKey = loserGroupKey
        self.placeKey = placeKey
        self.link = link
        
        if let serverTimestamp2 = serverTimestamp2 {
            self.serverDate = Date(timeIntervalSince1970: TimeInterval(serverTimestamp2))
        }
    }
    
    convenience init(type: String) {
        self.init(coordinates: nil, geohash: nil, imageUrls: nil, postKey: "", timestamp: nil, serverTimestamp: 0, serverTimestamp2: nil, dateTimestamp: nil, timeTimestamp: nil, sponsored: nil, title: nil, details: nil, type: type, placeKey: nil, userKey: nil, winnerGroupKey: nil, loserGroupKey: nil, link: nil)
    }

    enum Keys: CodingKey {
        case available, coordinates, geohash, imageUrls, postKey, serverTimestamp, serverTimestamp2
        case sponsored, timestamp, title, type, userKey, willBeAvailable, winnerGroupKey, loserGroupKey
        case dateTimestamp, timeTimestamp, details, placeKey, link
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        //let available: Bool? = try container.decodeIfPresent(Bool.self, forKey: .available)
        let coordinates: Coordinates? = try container.decodeIfPresent(Coordinates.self, forKey: .coordinates)
        let geohash: String? = try container.decodeIfPresent(String.self, forKey: .geohash)
        let imageUrls: [String]? = try container.decodeIfPresent([String].self, forKey: .imageUrls)
        let postKey: String = try container.decode(String.self, forKey: .postKey)
        let type: String = try container.decode(String.self, forKey: .type)
        let serverTimestamp: Int64 = try container.decode(Int64.self, forKey: .serverTimestamp)
        let serverTimestamp2: Int64 = try container.decode(Int64.self, forKey: .serverTimestamp2)
        let dateTimestamp: Int64? = try container.decodeIfPresent(Int64.self, forKey: .dateTimestamp)
        let timeTimestamp: Int64? = try container.decodeIfPresent(Int64.self, forKey: .timeTimestamp)
        let timestamp: Int64? = try container.decodeIfPresent(Int64.self, forKey: .timestamp)
        let sponsored: Bool? = try container.decodeIfPresent(Bool.self, forKey: .sponsored)
        let title: String? = try container.decodeIfPresent(String.self, forKey: .title)
        let details: String? = try container.decodeIfPresent(String.self, forKey: .details)
        let userKey: String? = try container.decodeIfPresent(String.self, forKey: .userKey)
        let winnerGroupKey: String? = try container.decodeIfPresent(String.self, forKey: .winnerGroupKey)
        let loserGroupKey: String? = try container.decodeIfPresent(String.self, forKey: .loserGroupKey)
        let placeKey: String? = try container.decodeIfPresent(String.self, forKey: .placeKey)
        let link: String? = try container.decodeIfPresent(String.self, forKey: .link)

        self.init(
            coordinates: coordinates,
            geohash: geohash,
            imageUrls: imageUrls,
            postKey: postKey,
            timestamp: timestamp,
            serverTimestamp: serverTimestamp,
            serverTimestamp2: serverTimestamp2,
            dateTimestamp: dateTimestamp,
            timeTimestamp: timeTimestamp,
            sponsored: sponsored,
            title: title,
            details: details,
            type: type,
            placeKey: placeKey,
            userKey: userKey,
            winnerGroupKey: winnerGroupKey,
            loserGroupKey: loserGroupKey,
            link: link
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(coordinates, forKey: .coordinates)
        try container.encode(geohash, forKey: .geohash)
        try container.encode(imageUrls, forKey: .imageUrls)
        try container.encode(postKey, forKey: .postKey)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(serverTimestamp*1000, forKey: .serverTimestamp)
        
        if let t = dateTimestamp {
            try container.encode(t*1000, forKey: .dateTimestamp)
        }
        
        if let t = timeTimestamp {
            try container.encode(t*1000, forKey: .timeTimestamp)
        }
        
        try container.encode(sponsored, forKey: .sponsored)
        try container.encode(title, forKey: .title)
        try container.encode(details, forKey: .details)
        try container.encode(type, forKey: .type)
        try container.encode(placeKey, forKey: .placeKey)
        try container.encode(userKey, forKey: .userKey)
        try container.encode(winnerGroupKey, forKey: .winnerGroupKey)
        try container.encode(loserGroupKey, forKey: .loserGroupKey)
        try container.encode(link, forKey: .link)
        try container.encode(serverDate.firebaseDate, forKey: .serverTimestamp2)
    }

    func debug() {
        let jsonEncoder = JSONEncoder()
        if let jsonData = try? jsonEncoder.encode(self) {
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            print2("[PostDebug] \(json ?? "")")
        }
        else {
            print2("[PostDebug] failed")
        }
    }
    
}
