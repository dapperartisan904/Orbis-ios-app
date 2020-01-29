//
//  OrbisComment.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class OrbisComment : Codable {
    
    let userId: String
    let postKey: String
    let commentKey: String
    let message: String?
    let parentCommentKey: String?
    let groupKey: String?
    let imageUrls: [String]?
    let serverDate: Date?
    
    enum Keys: CodingKey {
        case userId
        case postKey
        case commentKey
        case message
        case parentCommentKey
        case groupKey
        case imageUrls
        case serverTimestamp
    }
    
    init(
        userId: String,
        postKey: String,
        commentKey: String,
        message: String?,
        parentCommentKey: String?,
        groupKey: String?,
        imageUrls: [String]?,
        serverTimestamp: Int64?) {
      
        self.userId = userId
        self.postKey = postKey
        self.commentKey = commentKey
        self.message = message
        self.parentCommentKey = parentCommentKey
        self.groupKey = groupKey
        self.imageUrls = imageUrls
        
        if let serverTimestamp = serverTimestamp {
            self.serverDate = Date(timeIntervalSince1970: TimeInterval(serverTimestamp))
        }
        else {
            self.serverDate = nil
        }
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let userId = try container.decode(String.self, forKey: .userId)
        let postKey = try container.decode(String.self, forKey: .postKey)
        let commentKey = try container.decode(String.self, forKey: .commentKey)
        let message = try container.decodeIfPresent(String.self, forKey: .message)
        let parentCommentKey = try container.decodeIfPresent(String.self, forKey: .parentCommentKey)
        let groupKey = try container.decodeIfPresent(String.self, forKey: .groupKey)
        let imageUrls = try container.decodeIfPresent([String].self, forKey: .imageUrls)
        let serverTimestamp: Int64 = try container.decode(Int64.self, forKey: .serverTimestamp) / 1000
    
        self.init(
            userId: userId,
            postKey: postKey,
            commentKey: commentKey,
            message: message,
            parentCommentKey: parentCommentKey,
            groupKey: groupKey,
            imageUrls: imageUrls,
            serverTimestamp: serverTimestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(postKey, forKey: .postKey)
        try container.encode(commentKey, forKey: .commentKey)
        try container.encode(message, forKey: .message)
        try container.encode(parentCommentKey, forKey: .parentCommentKey)
        try container.encode(groupKey, forKey: .groupKey)
        try container.encode(imageUrls, forKey: .imageUrls)
        try container.encode(serverDate.firebaseDate, forKey: .serverTimestamp)
    }
    
    func isMainThread() -> Bool {
        return parentCommentKey == nil || parentCommentKey == commentKey
    }
    
    func isSubComment() -> Bool {
        return !isMainThread()
    }

}
