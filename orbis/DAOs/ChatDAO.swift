//
//  ChatDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 28/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import CodableFirebase
import RxSwift
import RxFirebaseDatabase

class ChatDAO {
    
    private static let chatReference = database().reference(withPath: "chat")
    private static let chatByUserRef = database().reference(withPath: "chatByUser")

    static func chatRef(chatKey: String) -> DatabaseReference {
        return chatReference.child(chatKey)
    }
    
    static func chatMessagesRef(chatKey: String) -> DatabaseReference {
        return chatRef(chatKey: chatKey).child("messages")
    }
    
    static func chatMessageRef(chatMessage: ChatMessage) -> DatabaseReference {
        return chatMessagesRef(chatKey: chatMessage.chatKey).child(chatMessage.messageKey)
    }
    
    static func chatUsersKeyRef(chatKey: String) -> DatabaseReference {
        return chatRef(chatKey: chatKey).child("usersKey")
    }
    
    static func chatByUserRef(userId: String, chatKey: String? = nil) -> DatabaseReference {
        if let chatKey = chatKey {
            return chatByUserRef.child(userId).child(chatKey)
        }
        else {
            return chatByUserRef.child(userId)
        }
    }
    
    static func getNewChatKey() -> String? {
        return chatReference.childByAutoId().key
    }
    
    static func getNewMessageKey(chatKey: String) -> String? {
        return chatMessagesRef(chatKey: chatKey).childByAutoId().key
    }
    
    static func loadChatKeysOfUser(userId: String) -> Single<[(String, Bool)]> {
        return chatByUserRef(userId: userId).rx
            .observeSingleEvent(.value)
            .map { snapshot -> [(String, Bool)] in
                var result = [(String, Bool)]()
                print2("loadChatKeysOfUser \(snapshot.key) childCount: \(snapshot.childrenCount)")
                
                for case let child as DataSnapshot in snapshot.children {
                    guard let hasNewMessages = child.valueToType(type: Bool.self) else { continue }
                    let chatKey = child.key
                    result.append((chatKey, hasNewMessages))
                }
                
                return result
            }
    }
    
    static func loadLastMessage(data: (String, Bool)) -> Single<ChatMessageWrapper> {
        let (chatKey, hasNewMessage) = data
        var message: ChatMessage? = nil
        var sender: OrbisUser? = nil
        var receiver: OrbisUser? = nil
        var senderGroup: Group? = nil
        
        return chatMessagesRef(chatKey: chatKey)
            .queryOrderedByKey()
            .queryLimited(toLast: 1).rx
            .observeSingleEvent(.value)
            .flatMap { (snaspshot : DataSnapshot) -> Single<OrbisUser?> in
                guard let msg = snaspshot.firstChild(type: ChatMessage.self) else {
                    return Single.error(OrbisErrors.generic)
                }
                message = msg
                return UserDAO.load(userId: message!.senderId)
            }
            .flatMap { (user: OrbisUser?) -> Single<OrbisUser?> in
                guard let user = user else {
                    return Single.error(OrbisErrors.generic)
                }
                sender = user
                return UserDAO.load(userId: message!.receiverId)
            }
            .flatMap { (user: OrbisUser?) -> Single<Group?> in
                guard let user = user else {
                    return Single.error(OrbisErrors.generic)
                }
                receiver = user
                return GroupDAO.findByKey(groupKey: sender!.activeGroupId)
            }
            .flatMap { (group: Group?) -> Single<Group?> in
                senderGroup = group
                return GroupDAO.findByKey(groupKey: receiver!.activeGroupId)
            }
            .map { (group: Group?) -> ChatMessageWrapper in
                return ChatMessageWrapper(
                    message: message!,
                    sender: sender!,
                    receiver: receiver!,
                    senderGroup: senderGroup,
                    receiverGroup: group,
                    hasNewMessages: hasNewMessage)
            }
    }
    
    static func loadLastMessages(userId: String) -> Observable<[ChatMessageWrapper]> {
        return loadChatKeysOfUser(userId: userId)
            .asObservable()
            .flatMap { (data: [(String, Bool)]) -> Observable<(String, Bool)> in
                print2("loadLastMessages [1]. Count: \(data.count)")
                return Observable.from(data)
            }
            .flatMap { data in
                return loadLastMessage(data: data)
            }
            .toArray()
            .asObservable()
            .map { wrappers in
                return wrappers.sorted(by: \ChatMessageWrapper.message!.serverDate, ascending: false)
            }
    }
    
    static func loadChat(userId: String, userId2: String) -> Single<[ChatMessage]> {
        let usersKey = ChatMessage.generateUsersKey(userId: userId, userId2: userId2)
        print2("loadChat usersKey \(usersKey)")
        
        return chatReference
            .queryOrdered(byChild: "usersKey")
            .queryEqual(toValue: usersKey).rx
            //.queryLimited(toFirst: 1.uInt).rx
            .observeSingleEvent(.value)
            .map { (snapshot: DataSnapshot) -> [ChatMessage] in
                var messages = [ChatMessage]()
                print2("loadChat iterating \(snapshot.key) childCount: \(snapshot.childrenCount)")
                
                for case let child as DataSnapshot in snapshot.children {
                    if !child.hasChild("messages") {
                        continue
                    }
                    
                    for case let child2 as DataSnapshot in child.childSnapshot(forPath: "messages").children {
                        if let msg = child2.valueToType(type: ChatMessage.self) {
                            messages.append(msg)
                        }
                    }
                }
                return messages
        }
    }
    
    static func observeAdditionEvents(chatKey: String, lastMsgKey: String?) -> Observable<ChatMessage?> {
        var query = chatMessagesRef(chatKey: chatKey)
            .queryOrderedByKey()
    
        if let k = lastMsgKey {
            query = query.queryStarting(atValue: k)
        }
    
        return query.rx
            .observeEvent(DataEventType.childAdded)
            .map { snapshot in
                return snapshot.valueToType(type: ChatMessage.self)
            }
    }
    
    static func saveMessage(msg: ChatMessage, isNewChat: Bool) -> Single<Bool> {
        let firstObservable: Single<Bool>
        let data = try! FirebaseEncoder().encode(msg)

        if isNewChat {
            firstObservable = chatUsersKeyRef(chatKey: msg.chatKey).rx
                .setValue(ChatMessage.generateUsersKey(chatMessage: msg))
                .map { _ in return true }
        }
        else {
            firstObservable = Single.just(true)
        }

        let pushData = ChatNotificationData(
            requestCode: RequestCode.openChat,
            senderId: msg.senderId,
            receiverId: msg.receiverId,
            chatKey: msg.chatKey,
            title: Words.notificationChatTitle.localized,
            message: String(format: Words.notificationChatTitle.localized, UserDefaultsRepository.instance().getMyUser()?.username ?? ""))
        
        return firstObservable
            .flatMap{ _ in return chatMessageRef(chatMessage: msg).rx.setValue(data) }
            .flatMap { _ in return saveChatByUser(userId: msg.senderId, chatKey: msg.chatKey, hasNewMessages: false) }
            .flatMap { _ in return saveChatByUser(userId: msg.receiverId, chatKey: msg.chatKey, hasNewMessages: true) }
            .flatMap { _ in return CloudFunctionsDAO.sendNotificationToUser(userId: msg.receiverId, data: pushData.toDict()) }
    }
    
    static func saveChatByUser(userId: String, chatKey: String, hasNewMessages: Bool) -> Single<DatabaseReference> {
        return chatByUserRef(userId: userId, chatKey: chatKey).rx.setValue(hasNewMessages)
    }
    
    static func saveWelcomeChat(receiverId: String?) -> Single<Bool> {
        guard
            let receiverId = receiverId,
            let chatKey = getNewChatKey(),
            let messageKey = getNewMessageKey(chatKey: chatKey)
        else {
            return Single.just(true)
        }
    
        let chatMessage = ChatMessage(
            chatKey: chatKey,
            messageKey: messageKey,
            senderId: isProduction() ? felipeUser : asusUser,
            receiverId: receiverId,
            text: Words.welcomeChatMessage.localized,
            imageUrls: nil,
            openedByReceiver: false,
            welcomeMessage: true,
            serverTimestamp: nil)
        
        return saveMessage(msg: chatMessage, isNewChat: true)
            .catchErrorJustReturn(true)
    }
}
