//
//  HiddenPost.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 12/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class HiddenPost : Codable {
    
    let userId: String
    let postKey: String
    var serverDate: Date?

    enum Keys: CodingKey {
        case userId
        case postKey
        case serverTimestamp
    }
    
    init(userId: String, postKey: String, serverDate: Date?) {
        self.userId = userId
        self.postKey = postKey
        self.serverDate = serverDate
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let userId: String = try container.decode(String.self, forKey: .userId)
        let postKey: String = try container.decode(String.self, forKey: .postKey)
        let serverTimestamp: Int64 = try container.decode(Int64.self, forKey: .serverTimestamp)
        self.init(userId: userId, postKey: postKey, serverDate: Date(timeIntervalSince1970: TimeInterval(serverTimestamp)))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(postKey, forKey: .postKey)
        try container.encode(serverDate.firebaseDate, forKey: .serverTimestamp)
    }
}
