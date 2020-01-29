//
//  ChatMessageWrapper.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 28/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class ChatMessageWrapper {
    
    var message: ChatMessage?
    let sender: OrbisUser
    let receiver: OrbisUser
    let senderGroup: Group?
    let receiverGroup: Group?
    let hasNewMessages: Bool
    
    init(
        message: ChatMessage?,
        sender: OrbisUser,
        receiver: OrbisUser,
        senderGroup: Group?,
        receiverGroup: Group?,
        hasNewMessages: Bool) {
        
        self.message = message
        self.sender = sender
        self.receiver = receiver
        self.senderGroup = senderGroup
        self.receiverGroup = receiverGroup
        self.hasNewMessages = hasNewMessages
    }
    
    func oppositeUser(user: OrbisUser) -> OrbisUser {
        if sender.uid == user.uid {
            return receiver
        }
        else {
            return sender
        }
    }
    
    func oppositeUserAndGroup(user: OrbisUser) -> (OrbisUser, Group?) {
        if sender.uid == user.uid {
            return (receiver, receiverGroup)
        }
        else {
            return (sender, senderGroup)
        }
    }
    
}
