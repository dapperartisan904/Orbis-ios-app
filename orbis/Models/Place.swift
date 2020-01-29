//
//  Place.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 18/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import CoreLocation

class Place : Codable {
    
    var key: String!
    var name: String!
    var type: String!
    var coordinates: Coordinates!
    var geohash: String!
    var lowercaseName: String?
    var userCreatedKey: String!
    var groupCreatedKey: String?
    var groupEditedKey: String?
    var userEditedKey: String?
    var description: String?
    var address: String?
    var temporary = false
    var wasTemporary = false
    var googlePlaceId: String?
    var source: String?
    var deleted = false
    var csvHash: String?
    var csvUrl: String?
    var phone: String?
    var cityPlusCategoryKey2: String?
    
    // Fields related to subscription through paypal
    var ownerId: String?

    var creationDate: Date?

    var subscriptionDate: Date?
    
    /*
        Last time a not duplicated check in was made on this place
     */
    var lastCheckInDate: Date?
    
    /*
        This key indicates the dominant group of this place at last time it was check
     */
    var dominantGroupKey: String?
    
    enum Keys: CodingKey {
        case key, name, type, coordinates, geohash, lowercaseName, userCreatedKey, groupCreatedKey, groupEditedKey, userEditedKey
        case description, address, temporary, wasTemporary, googlePlaceId, source, deleted, ownerId, dominantGroupKey, phone
    }
    
    init(key: String,
        name: String,
        type: String,
        coordinates: Coordinates,
        geohash: String,
        lowercaseName: String?,
        userCreatedKey: String,
        groupCreatedKey: String?,
        groupEditedKey: String?,
        userEditedKey: String?,
        description: String?,
        address: String?,
        temporary: Bool,
        wasTemporary: Bool,
        googlePlaceId: String?,
        source: String?,
        deleted: Bool,
        csvHash: String?,
        csvUrl: String?,
        phone: String?,
        cityPlusCategoryKey2: String?,
        ownerId: String?,
        dominantGroupKey: String?,
        creationDate: Date?,
        subscriptionDate: Date?,
        lastCheckInDate: Date?) {
        
        self.key = key
        self.name = name
        self.type = type
        self.coordinates = coordinates
        self.geohash = geohash
        self.lowercaseName = lowercaseName
        self.userCreatedKey = userCreatedKey
        self.groupCreatedKey = groupCreatedKey
        self.groupEditedKey = groupEditedKey
        self.userEditedKey = userEditedKey
        self.description = description
        self.address = address
        self.temporary = temporary
        self.wasTemporary = wasTemporary
        self.googlePlaceId = googlePlaceId
        self.source = source
        self.deleted = deleted
        self.csvHash = csvHash
        self.csvUrl = csvUrl
        self.phone = phone
        self.cityPlusCategoryKey2 = cityPlusCategoryKey2
        self.ownerId = ownerId
        self.dominantGroupKey = dominantGroupKey
        self.creationDate = creationDate
        self.subscriptionDate = subscriptionDate
        self.lastCheckInDate = lastCheckInDate
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        
        /*
            for k in container.allKeys {
                print2("Decoder key: \(k)")
            }
         */

        let key: String = try container.decode(String.self, forKey: .key)
        let name: String = try container.decode(String.self, forKey: .name)
        let type: String = try container.decode(String.self, forKey: .type)
        let coordinates: Coordinates = try container.decode(Coordinates.self, forKey: .coordinates)
        let geohash: String = try container.decode(String.self, forKey: .geohash)
        let userCreatedKey: String = try container.decode(String.self, forKey: .userCreatedKey)
        let temporary: Bool = try container.decodeIfPresent(Bool.self, forKey: .temporary) ?? false
        let wasTemporary: Bool = try container.decodeIfPresent(Bool.self, forKey: .wasTemporary) ?? false
        let deleted: Bool = try container.decodeIfPresent(Bool.self, forKey: .deleted) ?? false
        let lowercaseName: String? = try container.decodeIfPresent(String.self, forKey: .lowercaseName)
        let groupCreatedKey: String? = try container.decodeIfPresent(String.self, forKey: .groupCreatedKey)
        let groupEditedKey: String? = try container.decodeIfPresent(String.self, forKey: .groupEditedKey)
        let userEditedKey: String? = try container.decodeIfPresent(String.self, forKey: .userEditedKey)
        let description: String? = try container.decodeIfPresent(String.self, forKey: .description)
        let address: String? = try container.decodeIfPresent(String.self, forKey: .address)
        let googlePlaceId: String? = try container.decodeIfPresent(String.self, forKey: .googlePlaceId)
        let source: String? = try container.decodeIfPresent(String.self, forKey: .source)
        let phone: String? = try container.decodeIfPresent(String.self, forKey: .phone)
        let dominantGroupKey: String? = try container.decodeIfPresent(String.self, forKey: .dominantGroupKey)
        let ownerId: String? = try container.decodeIfPresent(String.self, forKey: .ownerId)
        
        self.init(key: key,
                 name: name,
                 type: type,
                 coordinates: coordinates,
                 geohash: geohash,
                 lowercaseName: lowercaseName,
                 userCreatedKey: userCreatedKey,
                 groupCreatedKey: groupCreatedKey,
                 groupEditedKey: groupEditedKey,
                 userEditedKey: userEditedKey,
                 description: description,
                 address: address,
                 temporary: temporary,
                 wasTemporary: wasTemporary,
                 googlePlaceId: googlePlaceId,
                 source: source,
                 deleted: deleted,
                 csvHash: nil,
                 csvUrl: nil,
                 phone: phone,
                 cityPlusCategoryKey2: nil,
                 ownerId: ownerId,
                 dominantGroupKey: dominantGroupKey,
                 creationDate: nil,
                 subscriptionDate: nil,
                 lastCheckInDate: nil)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(key, forKey: .key)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(coordinates, forKey: .coordinates)
        try container.encode(geohash, forKey: .geohash)
        try container.encode(lowercaseName, forKey: .lowercaseName)
        try container.encode(userCreatedKey, forKey: .userCreatedKey)
        try container.encode(groupCreatedKey, forKey: .groupCreatedKey)
        try container.encode(groupEditedKey, forKey: .groupEditedKey)
        try container.encode(userEditedKey, forKey: .userEditedKey)
        try container.encode(description, forKey: .description)
        try container.encode(address, forKey: .address)
        try container.encode(temporary, forKey: .temporary)
        try container.encode(wasTemporary, forKey: .wasTemporary)
        try container.encode(googlePlaceId, forKey: .googlePlaceId)
        try container.encode(source, forKey: .source)
        try container.encode(deleted, forKey: .deleted)
        try container.encode(ownerId, forKey: .ownerId)
        try container.encode(dominantGroupKey, forKey: .dominantGroupKey)
    }
    
    func placeType() -> PlaceType? {
        guard let type = type?.lowercased() else {
            return nil
        }
        
        let rawValue: String
        if type == "shopping" {
            rawValue = "place_shop"
        }
        else {
            rawValue = "place_\(type)"
        }

        return PlaceType(rawValue: rawValue)
    }
    
    static func build(item: NearbySearchItem) -> Place? {
        guard
            let placeKey = PlaceDAO.newKey(),
            let name = item.name,
            let address = item.vicinity,
            let googlePlaceID = item.placeID,
            let location = item.geometry?.location,
            let type = item.types?.first(where: { value in
                return googlePlaceTypes[value] != nil
            })
        else {
            return nil
        }

        let location2D = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
        
        guard let geohash = location2D.geohash() else {
            return nil
        }
        
        return Place(key: placeKey,
                        name: name,
                        type: googlePlaceTypes[type]?.valueForDB() ?? PlaceType.location.valueForDB(),
                        coordinates: Coordinates(coordinate2D: location2D),
                        geohash: geohash,
                        lowercaseName: name.lowercased(),
                        userCreatedKey: googlePlaceUserId,
                        groupCreatedKey: UserDefaultsRepository.instance().getActiveGroup()?.key,
                        groupEditedKey: nil,
                        userEditedKey: nil,
                        description: nil,
                        address: address,
                        temporary: false,
                        wasTemporary: false,
                        googlePlaceId: googlePlaceID,
                        source: PlaceSource.google.rawValue,
                        deleted: false,
                        csvHash: nil,
                        csvUrl: nil,
                        phone: nil,
                        cityPlusCategoryKey2: nil,
                        ownerId: nil,
                        dominantGroupKey: nil,
                        creationDate: Date(),
                        subscriptionDate: nil,
                        lastCheckInDate: nil)
    }
    
    static private let opacityZoomLevels = [
        12.0 + mapZoomDiffToAndroid,
        13.0 + mapZoomDiffToAndroid,
        14.0 + mapZoomDiffToAndroid,
        14.5 + mapZoomDiffToAndroid,
        15.5 + mapZoomDiffToAndroid,
        16.5 + mapZoomDiffToAndroid
    ]
    
    static private let opacitySizes = [
        500.0 * iosSizeFactor,
        250.0 * iosSizeFactor,
        150.0 * iosSizeFactor,
        100.0 * iosSizeFactor,
        50.0 * iosSizeFactor,
        25.0 * iosSizeFactor
    ]
    
    static private let opacities = [
        [1.0, 0.8, 0.6, 0.4, 0.2, 0.1],
        [0.8, 1.0, 0.8, 0.6, 0.4, 0.2],
        [0.6, 0.8, 1.0, 0.8, 0.6, 0.4],
        [0.4, 0.6, 0.8, 1.0, 0.8, 0.6],
        [0.2, 0.4, 0.6, 0.8, 1.0, 0.8],
        [0.1, 0.2, 0.4, 0.6, 0.8, 1.0]
    ]

    static func zoomIndex(zoomLevel: Double) -> Int {
        var zoomIndex: Int = -1
        
        if zoomLevel <= opacityZoomLevels[0] {
            zoomIndex = 0
        }
        else if zoomLevel > opacityZoomLevels.last! {
            zoomIndex = opacityZoomLevels.endIndex - 1
        }
        else {
            for i in 1...opacityZoomLevels.endIndex - 1 {
                let prev = opacityZoomLevels[i-1]
                let curr = opacityZoomLevels[i]
                if zoomLevel > prev && zoomLevel <= curr {
                    zoomIndex = i
                    break
                }
            }
        }
    
        return zoomIndex
    }
    
    /*
        Do not turn this method public. See getOpacity below
     */
    static private func getOpacity(touchesCount: Int, size: Double, zoomLevel: Double, placeName: String?) -> Double {
        if touchesCount == 0 {
            return 1.0
        }
        
        let zi = zoomIndex(zoomLevel: zoomLevel)
        var sizeIndex: Int = -1
        
        if size >= opacitySizes[0] {
            sizeIndex = 0
        }
        else if size < opacitySizes.last! {
            sizeIndex = opacitySizes.endIndex - 1
        }
        else {
            for i in 1...opacitySizes.endIndex - 1 {
                let prev = opacitySizes[i-1]
                let curr = opacitySizes[i]
                if size < prev && size >= curr {
                    sizeIndex = i
                    break
                }
            }
        }

        let opacity = 1.0 - opacities[sizeIndex][zi]
        //print2("getOpacity [\(placeName ?? "")] touchesCount: \(touchesCount) size: \(size) sizeIndex: \(sizeIndex) zoomLevel: \(zoomLevel) zoomIndex: \(zi) opacity: \(opacity)")
        
        return opacity
    }
    
    static func getOpacity(touchesCount: Int, size: Double, zoomIndex: Int, placeName: String) -> Double {
        let zi = min(max(0, zoomIndex), opacityZoomLevels.endIndex - 1)
        return getOpacity(touchesCount: touchesCount, size: size * 0.5, zoomLevel: opacityZoomLevels[zi], placeName: placeName)
    }
 
    static func debugOpacities() {
        for zl in 14...18 {
            let zi = zoomIndex(zoomLevel: zl.double)
            let opacity = getOpacity(touchesCount: 1, size: 1928.0, zoomIndex: zi, placeName: "")
            print2("[DebugOpacities] zoomLevel: \(zl) zoomIndex: \(zi) opacity: \(opacity)")
        }
    }
}
