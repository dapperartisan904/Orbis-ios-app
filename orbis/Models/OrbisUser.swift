//
//  OrbisUser.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation

class OrbisUser : Codable {
    
    var uid: String!
    var username: String!
    
    var email: String?
    var emailInVk: String?
    var vkId: String?
    var imageName: String?
    var geohash: String?
    var coordinates: Coordinates?
    var unit: String?
    var pushNotificationsEnabled = true
    var language: String?
    var superAdmin = false
    var deleted = false
    var flavor: String?
    
    // We need this field in order to access provider images of other users
    var providerImageUrl: String?
    
    // Last user check in
    var checkIn: PresenceEvent?
    
    /*
        When leaving the active group, we save "".
        That way we receive REMOVED event when listening a particular user
     */
    var activeGroupId: String?
    
    var gender: String?
    var dateOfBirth: Int64?
    
    // Indicates if groups and places at profile screen are public or private
    var groupsArePublic: Bool?
    var placesArePublic: Bool?
    
    // Firebase cloud messaging token
    var fcmToken: String?
    
    var activeServerDate: Date?
    
    static var emptyUser: OrbisUser = {
        let user = OrbisUser()
        user.username = "empty"
        user.uid = "empty"
        return user
    }()
    
    enum Keys: CodingKey {
        case uid
        case username
        case email
        case imageName
        case geohash
        case coordinates
        case activeServerTimestamp
        case unit
        case pushNotificationsEnabled
        case language
        case superAdmin
        case deleted
        case flavor
        case providerImageUrl
        case checkIn
        case activeGroupId
        case gender
        case dateOfBirth
        case groupsArePublic
        case placesArePublic
    }
    
    init() { }
    
    convenience init(
        uid: String,
        username: String,
        email: String?,
        imageName: String?,
        geohash: String?,
        coordinates: Coordinates?,
        activeServerTimestamp: Int64?,
        unit: String?,
        pushNotificationsEnabled: Bool,
        language: String?,
        superAdmin: Bool,
        deleted: Bool,
        flavor: String?,
        providerImageUrl: String?,
        checkIn: PresenceEvent?,
        activeGroupId: String?,
        gender: String?,
        dateOfBirth: Int64?,
        groupsArePublic: Bool,
        placesArePublic: Bool) {
        
        self.init()
        self.uid = uid
        self.username = username
        self.email = email
        self.imageName = imageName
        self.geohash = geohash
        self.coordinates = coordinates
        self.unit = unit
        self.pushNotificationsEnabled = pushNotificationsEnabled
        self.language = language
        self.superAdmin = superAdmin
        self.deleted = deleted
        self.flavor = flavor
        self.providerImageUrl = providerImageUrl
        self.checkIn = checkIn
        self.activeGroupId = activeGroupId
        self.gender = gender
        self.dateOfBirth = dateOfBirth
        self.groupsArePublic = groupsArePublic
        self.placesArePublic = placesArePublic
        
        if let t = activeServerTimestamp, t > 0 {
            self.activeServerDate = Date(timeIntervalSince1970: TimeInterval(t))
        }
        else {
            self.activeServerDate = nil
        }
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let uid  = try container.decode(String.self, forKey: .uid)
        let username = try container.decode(String.self, forKey: .username)
        let email = try container.decodeIfPresent(String.self, forKey: .email)
        let imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        let geohash = try container.decodeIfPresent(String.self, forKey: .geohash)
        let coordinates = try container.decodeIfPresent(Coordinates.self, forKey: .coordinates)
        let activeServerTimestamp = (try container.decodeIfPresent(Int64.self, forKey: .activeServerTimestamp) ?? 0) / 1000
        let unit = try container.decodeIfPresent(String.self, forKey: .unit)
        let pushNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .pushNotificationsEnabled) ?? true
        let language = try container.decodeIfPresent(String.self, forKey: .language)
        let superAdmin = try container.decodeIfPresent(Bool.self, forKey: .superAdmin) ?? false
        let deleted = try container.decodeIfPresent(Bool.self, forKey: .deleted) ?? false
        let flavor = try container.decodeIfPresent(String.self, forKey: .flavor)
        let providerImageUrl = try container.decodeIfPresent(String.self, forKey: .providerImageUrl)
        let checkIn = try container.decodeIfPresent(PresenceEvent.self, forKey: .checkIn)
        let activeGroupId = try container.decodeIfPresent(String.self, forKey: .activeGroupId)
        let gender = try container.decodeIfPresent(String.self, forKey: .gender)
        let dateOfBirth = try container.decodeIfPresent(Int64.self, forKey: .dateOfBirth)
        let groupsArePublic = try container.decodeIfPresent(Bool.self, forKey: .groupsArePublic) ?? true
        let placesArePublic = try container.decodeIfPresent(Bool.self, forKey: .placesArePublic) ?? true
    
        self.init(
            uid: uid,
            username: username,
            email: email,
            imageName: imageName,
            geohash: geohash,
            coordinates: coordinates,
            activeServerTimestamp: activeServerTimestamp,
            unit: unit,
            pushNotificationsEnabled: pushNotificationsEnabled,
            language: language,
            superAdmin: superAdmin,
            deleted: deleted,
            flavor: flavor,
            providerImageUrl: providerImageUrl,
            checkIn: checkIn,
            activeGroupId: activeGroupId,
            gender: gender,
            dateOfBirth: dateOfBirth,
            groupsArePublic: groupsArePublic,
            placesArePublic: placesArePublic)
    }
}
