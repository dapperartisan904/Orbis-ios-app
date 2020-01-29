//
//  ChatMessage.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 28/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import FirebaseFirestore

class ChatMessage : Codable {
    
    static func generateUsersKey(chatMessage: ChatMessage) -> String {
        return generateUsersKey(userId: chatMessage.senderId, userId2: chatMessage.receiverId)
    }
    
    static func generateUsersKey(userId: String, userId2: String) -> String {
        if userId < userId2 {
            return userId + userId2
        }
        else {
            return userId2 + userId
        }
    }
    
    let chatKey: String
    let messageKey: String
    let senderId: String
    let receiverId: String
    let text: String?
    let imageUrls: [String]?
    let openedByReceiver: Bool
    let welcomeMessage: Bool?
    let serverDate: Date?
    
    enum Keys: CodingKey {
        case chatKey
        case messageKey
        case senderId
        case receiverId
        case text
        case imageUrls
        case openedByReceiver
        case serverTimestamp
        case welcomeMessage
    }
    
    init(
        chatKey: String,
        messageKey: String,
        senderId: String,
        receiverId: String,
        text: String?,
        imageUrls: [String]?,
        openedByReceiver: Bool,
        welcomeMessage: Bool?,
        serverTimestamp: Int64?) {
        
        self.chatKey = chatKey
        self.messageKey = messageKey
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.imageUrls = imageUrls
        self.openedByReceiver = openedByReceiver
        self.welcomeMessage = welcomeMessage
        
        if let serverTimestamp = serverTimestamp {
            self.serverDate = Date(timeIntervalSince1970: TimeInterval(serverTimestamp))
        }
        else {
            self.serverDate = nil
        }
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let chatKey = try container.decode(String.self, forKey: .chatKey)
        let messageKey = try container.decode(String.self, forKey: .messageKey)
        let senderId = try container.decode(String.self, forKey: .senderId)
        let receiverId = try container.decode(String.self, forKey: .receiverId)
        let text = try container.decodeIfPresent(String.self, forKey: .text)
        let imageUrls = try container.decodeIfPresent([String].self, forKey: .imageUrls)
        let openedByReceiver = try container.decode(Bool.self, forKey: .openedByReceiver)
        let serverTimestamp: Int64 = try container.decode(Int64.self, forKey: .serverTimestamp) / 1000
        let welcomeMessage = try container.decodeIfPresent(Bool.self, forKey: .openedByReceiver)
        
        self.init(
            chatKey: chatKey,
            messageKey: messageKey,
            senderId: senderId,
            receiverId: receiverId,
            text: text,
            imageUrls: imageUrls,
            openedByReceiver: openedByReceiver,
            welcomeMessage: welcomeMessage,
            serverTimestamp: serverTimestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(chatKey, forKey: .chatKey)
        try container.encode(messageKey, forKey: .messageKey)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(receiverId, forKey: .receiverId)
        try container.encode(text, forKey: .text)
        try container.encode(imageUrls, forKey: .imageUrls)
        try container.encode(openedByReceiver, forKey: .openedByReceiver)
        try container.encode(serverDate.firebaseDate, forKey: .serverTimestamp)
        try container.encode(welcomeMessage, forKey: .welcomeMessage)
    }
    
}
