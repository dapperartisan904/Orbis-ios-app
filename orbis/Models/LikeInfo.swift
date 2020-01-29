//
//  LikeInfo.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 12/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import FirebaseFirestore

class LikeInfo : Codable {
    
    // Can be post key, comment key, post image name
    var mainKey: String!
    var liked = true
    var serverDate: Date? = nil
    
    //var serverTimestamp: [AnyHashable : Any] = ServerValue.timestamp()
    //var serverTimestamp: Int64
    //var serverTimestamp: Timestamp!
    
    enum Keys: CodingKey {
        case mainKey
        case liked
        case serverTimestamp
    }

    init(mainKey: String, liked: Bool, serverDate: Date?) {
        self.mainKey = mainKey
        self.liked = liked
        self.serverDate = serverDate
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let mainKey: String = try container.decode(String.self, forKey: .mainKey)
        let liked: Bool = try container.decode(Bool.self, forKey: .liked)
        let serverTimestamp: Int64 = try container.decode(Int64.self, forKey: .serverTimestamp)
        self.init(mainKey: mainKey, liked: liked, serverDate: Date(timeIntervalSince1970: TimeInterval(serverTimestamp)))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(mainKey, forKey: .mainKey)
        try container.encode(liked, forKey: .liked)
        try container.encode(serverDate.firebaseDate, forKey: .serverTimestamp)
    }

    func notEqual(other: LikeInfo?) -> Bool {
        guard let other = other else { return true }
        return mainKey != other.mainKey || liked != other.liked
    }
    
}
