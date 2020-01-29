//
//  Attendance.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 25/04/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class Attendance : Codable {

    let userId: String
    let postKey: String
    var status: String
    var serverDate: Date?
    
    enum Keys: CodingKey {
        case userId
        case postKey
        case status
        case serverTimestamp
    }
    
    init(
        userId: String,
        postKey: String,
        status: String,
        serverTimestamp: Int64?) {
        
        self.userId = userId
        self.postKey = postKey
        self.status = status
        
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
        let status = try container.decode(String.self, forKey: .status)
        let serverTimestamp: Int64 = try container.decode(Int64.self, forKey: .serverTimestamp) / 1000
        
        self.init(
            userId: userId,
            postKey: postKey,
            status: status,
            serverTimestamp: serverTimestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(postKey, forKey: .postKey)
        try container.encode(status, forKey: .status)
        try container.encode(serverDate.firebaseDate, forKey: .serverTimestamp)
    }
    
    func statusEnum() -> AttendanceStatus {
        return AttendanceStatus.from(value: status) ?? AttendanceStatus.undetermined
    }
}
