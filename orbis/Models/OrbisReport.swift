//
//  OrbisReport.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 05/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class OrbisReport : Codable {
    
    var reportKey: String!
    var type: String!
    
    var postType: String?
    var postKey: String?
    var placeKey: String?
    var commentKey: String?
    var groupKey: String?
    var message: String?
    var recipients: [String]?
    
    // Refers to user that made the report
    var userKey: String?
    
    var serverTimestamp: Int64!
    
    enum Keys: CodingKey {
        case reportKey, type, userKey, postType, postKey, placeKey, commentKey, groupKey
        case message, recipients, serverTimestamp
    }
    
    init(
        reportKey: String? = nil,
        type: String? = nil,
        userKey: String? = nil,
        postType: String? = nil,
        postKey: String? = nil,
        placeKey: String? = nil,
        commentKey: String? = nil,
        groupKey: String? = nil,
        message: String? = nil,
        recipients: [String]? = nil) {
        
        self.reportKey = reportKey
        self.type = type
        self.userKey = userKey
        self.postType = postType
        self.postKey = postKey
        self.placeKey = placeKey
        self.commentKey = commentKey
        self.groupKey = groupKey
        self.message = message
        self.recipients = recipients
    }
    
    convenience init(type: String?) {
        self.init(
            reportKey: nil,
            type: type,
            userKey: nil,
            postType: nil,
            postKey: nil,
            placeKey: nil,
            commentKey: nil,
            groupKey: nil,
            message: nil,
            recipients: nil)
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let reportKey: String = try container.decode(String.self, forKey: .reportKey)
        let type: String = try container.decode(String.self, forKey: .type)
        let userKey: String? = try container.decodeIfPresent(String.self, forKey: .userKey)
        let postType: String? = try container.decodeIfPresent(String.self, forKey: .postType)
        let postKey: String? = try container.decodeIfPresent(String.self, forKey: .postKey)
        let placeKey: String? = try container.decodeIfPresent(String.self, forKey: .placeKey)
        let commentKey: String? = try container.decodeIfPresent(String.self, forKey: .commentKey)
        let groupKey: String? = try container.decodeIfPresent(String.self, forKey: .groupKey)
        let message: String? = try container.decodeIfPresent(String.self, forKey: .message)
        let recipients: [String]? = try container.decodeIfPresent([String].self, forKey: .recipients)
    
        self.init(
            reportKey: reportKey,
            type: type,
            userKey: userKey,
            postType: postType,
            postKey: postKey,
            placeKey: placeKey,
            commentKey: commentKey,
            groupKey: groupKey,
            message: message,
            recipients: recipients)
    }

    func typeEnum() -> ReportType? {
        return ReportType.from(value: type)
    }
}
