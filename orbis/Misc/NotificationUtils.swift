//
//  NotificationUtils.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 07/02/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import FirebaseMessaging

class NotificationUtils {
    
    static func subscribeTo(topic: String) {
        print2("[Push] subscribeTo \(topic)")
        Messaging.messaging().subscribe(toTopic: topic)
    }
    
    static func unsubscribeFrom(topic: String) {
        print2("[Push] unsubscribeFrom \(topic)")
        Messaging.messaging().unsubscribe(fromTopic: topic)
    }
   
}

class OrbisPushNotificationData {
    let requestCode: RequestCode
    
    init(requestCode: RequestCode) {
        self.requestCode = requestCode
    }
}

// Inbox and outbox
class ChatNotificationData : OrbisPushNotificationData {
    let senderId, receiverId, chatKey: String
    let title, message: String?

    init(requestCode: RequestCode, senderId: String, receiverId: String, chatKey: String, title: String? = nil, message: String? = nil) {
        self.senderId = senderId
        self.receiverId = receiverId
        self.chatKey = chatKey
        self.title = title
        self.message = message
        super.init(requestCode: requestCode)
    }

    func toDict() -> [String : Any?] {
        return [
            NotificationKey.requestCode.rawValue : requestCode.rawValue.string,
            NotificationKey.chatKey.rawValue : chatKey,
            NotificationKey.receiverId.rawValue : receiverId,
            NotificationKey.senderId.rawValue : senderId,
            NotificationKey.title.rawValue : title,
            NotificationKey.message.rawValue : message
        ]
    }
}

// Outbox
class CommentNotificationData : OrbisPushNotificationData {
    let comment: OrbisComment
    let receiverId: String
    let title, message: String?
    
    init(requestCode: RequestCode, comment: OrbisComment, receiverId: String, title: String?, message: String?) {
        self.comment = comment
        self.receiverId = receiverId
        self.title = title
        self.message = message
        super.init(requestCode: requestCode)
    }
    
    func toDict() -> [String : Any?] {
        return [
            NotificationKey.requestCode.rawValue : requestCode.rawValue.string,
            NotificationKey.commentKey.rawValue : comment.commentKey,
            NotificationKey.postKey.rawValue : comment.postKey,
            NotificationKey.receiverId.rawValue : receiverId,
            NotificationKey.title.rawValue : title,
            NotificationKey.message.rawValue : message
        ]
    }
}

// Inbox
class CommentReceivedData : OrbisPushNotificationData {
    
    let postWrapper: PostWrapper
    
    init(requestCode: RequestCode, postWrapper: PostWrapper) {
        self.postWrapper = postWrapper
        super.init(requestCode: requestCode)
    }
    
    func toDict() -> [String : Any?] { return [:] }
    
}

class PostNotificationData : OrbisPushNotificationData {
    let post: OrbisPost
    let senderId: String?
    let titleLoc: String
    let messageLoc: String
    let messageArgs: [String]
    
    init(requestCode: RequestCode, post: OrbisPost, senderId: String?, titleLoc: String, messageLoc: String, messageArgs: [String]) {
        self.post = post
        self.senderId = senderId
        self.titleLoc = titleLoc
        self.messageLoc = messageLoc
        self.messageArgs = messageArgs
        super.init(requestCode: requestCode)
    }
    
    func toDict() -> [String : Any?] {
        return [
            NotificationKey.requestCode.rawValue : requestCode.rawValue.string,
            NotificationKey.postKey.rawValue : post.postKey,
            NotificationKey.postType.rawValue : post.type,
            NotificationKey.senderId.rawValue : senderId,
            NotificationKey.titleLoc.rawValue : titleLoc,
            NotificationKey.messageLoc.rawValue : messageLoc,
            NotificationKey.messageArgs.rawValue : messageArgs.joined(separator: "###"),
            NotificationKey.isLocalizable.rawValue : "true"
        ]
    }
}

class LikedNotificationData : OrbisPushNotificationData {
    let receiverId: String
    let liked: Bool
    let likeType: LikeType
    let postKey: String
    let senderId: String
    let titleLoc: String
    let messageLoc: String
    let messageArgs: [String]
    
    init(requestCode: RequestCode, receiverId: String, liked: Bool, likeType: LikeType, postKey: String, senderId: String, titleLoc: String, messageLoc: String, messageArgs: [String]) {
        self.receiverId = receiverId
        self.liked = liked
        self.likeType = likeType
        self.postKey = postKey
        self.senderId = senderId
        self.titleLoc = titleLoc
        self.messageLoc = messageLoc
        self.messageArgs = messageArgs
        super.init(requestCode: requestCode)
    }
    
    func toDict() -> [String : Any?] {
        return [
            NotificationKey.requestCode.rawValue : requestCode.rawValue.string,
            NotificationKey.postKey.rawValue : postKey,
            NotificationKey.receiverId.rawValue : receiverId,
            NotificationKey.senderId.rawValue : senderId,
            NotificationKey.likeType.rawValue : "\(likeType.index())",
            NotificationKey.titleLoc.rawValue : titleLoc,
            NotificationKey.messageLoc.rawValue : messageLoc,
            NotificationKey.messageArgs.rawValue : messageArgs.joined(separator: "###"),
            NotificationKey.isLocalizable.rawValue : "true"
        ]
    }
}

class JoinNotificationData : OrbisPushNotificationData {
    let user: OrbisUser
    let group: Group
    
    init(requestCode: RequestCode, user: OrbisUser, group: Group) {
        self.user = user
        self.group = group
        super.init(requestCode: requestCode)
    }
    
    func toDict() -> [String : Any?] {
        let messageArgs: [String] = [user.username, group.name]
        
        return [
            NotificationKey.requestCode.rawValue : requestCode.rawValue.string,
            NotificationKey.senderId.rawValue : user.uid,
            NotificationKey.groupKey.rawValue : group.key,
            NotificationKey.titleLoc.rawValue : "notification_joined_title",
            NotificationKey.messageLoc.rawValue : "notification_joined_message",
            NotificationKey.messageArgs.rawValue : messageArgs.joined(separator: "###"),
            NotificationKey.isLocalizable.rawValue : "true"
        ]
    }
}

class OpenGroupNotificationData : OrbisPushNotificationData {
    let group: Group
    
    init(requestCode: RequestCode, group: Group) {
        self.group = group
        super.init(requestCode: requestCode)
    }
}

/*
 fun likedNotification(
 liked: Boolean,
 post: OrbisPost,
 sender: OrbisUser,
 application: OrbisApplication) : Completable {
 
 if (!liked) {
 return Completable.complete()
 }
 
 val receiverId = post.userKey ?: return Completable.complete()
 
 val data = mapOf(
 "title" to "New like",
 "message" to "Like msg",
 "postKey" to post.postKey,
 "likeType" to LikesDAO.LikeType.POST.ordinal.toString(),
 Extras.SENDER_ID.name to sender.uid,
 Extras.RECEIVER_ID.name to receiverId,
 Extras.REQUEST_CODE.name to RequestCodes.LIKED.toString())
 
 return Completable.fromSingle(OrbisCloudFunctions.sendNotificationToUser(receiverId, data))
 .onErrorComplete()
 }
 */


