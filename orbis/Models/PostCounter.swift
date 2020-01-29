//
//  PostCounter.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 14/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class PostCounter : Codable {

    var commentsCount: Int?
    var likesCount: Int?
    var serverDate: Date?

    enum Keys: CodingKey {
        case commentsCount
        case likesCount
        case serverTimestamp
    }
    
    init(commentsCount: Int?, likesCount: Int?, serverDate: Date?) {
        self.commentsCount = commentsCount
        self.likesCount = likesCount
        self.serverDate = serverDate
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let commentsCount: Int? = try container.decodeIfPresent(Int.self, forKey: .commentsCount)
        let likesCount: Int? = try container.decodeIfPresent(Int.self, forKey: .likesCount)
        let serverTimestamp: Int64 = try container.decode(Int64.self, forKey: .serverTimestamp)
        self.init(commentsCount: commentsCount, likesCount: likesCount, serverDate: Date(timeIntervalSince1970: TimeInterval(serverTimestamp)))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(commentsCount, forKey: .commentsCount)
        try container.encode(likesCount, forKey: .likesCount)
        try container.encode(serverDate.firebaseDate, forKey: .serverTimestamp)
    }

    func notEqual(other: PostCounter?) -> Bool {
        guard let other = other else { return true }
        return commentsCount != other.commentsCount || likesCount != other.likesCount
    }

}
