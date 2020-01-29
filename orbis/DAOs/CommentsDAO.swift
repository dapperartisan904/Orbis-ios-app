//
//  CommentsDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import FirebaseDatabase
import CodableFirebase
import RxSwift
import RxFirebaseDatabase

class CommentsDAO {
    
    private static let commentsByPostReference = database().reference(withPath: "commentsByPost")

    private static func ref(postKey: String) -> DatabaseReference {
        return commentsByPostReference.child(postKey)
    }
    
    private static func ref(postKey: String, commentKey: String) -> DatabaseReference {
        return ref(postKey: postKey).child(commentKey)
    }
    
    private static func ref(comment: OrbisComment) -> DatabaseReference {
        return ref(postKey: comment.postKey, commentKey: comment.commentKey)
    }

    static func newKey() -> String? {
        return commentsByPostReference.childByAutoId().key
    }

    static func saveComment(post: OrbisPost, comment: OrbisComment) -> Single<Bool> {
        let data = try! FirebaseEncoder().encode(comment)
        
        return ref(comment: comment).rx
            .setValue(data)
            .flatMap { _ in
                return CountersDAO.updateCommentsCount(likeType: LikeType.post, mainKey: post.postKey, increment: 1)
            }
            .flatMap { (_ : DatabaseReference) -> Single<Bool> in
                guard let receiverId = post.userKey else {
                    return Single.just(false)
                }
                
                let pushData = CommentNotificationData(
                    requestCode: RequestCode.openComment,
                    comment: comment,
                    receiverId: receiverId,
                    title: Words.notificationCommentTitle.localized,
                    message: String(format: Words.notificationCommentMessage3.localized, UserDefaultsRepository.instance().getMyUser()?.username ?? ""))
                
                return CloudFunctionsDAO.sendNotificationToUser(userId: receiverId, data: pushData.toDict())
            }
    }
    
    static func loadComments(postKey: String) -> Single<([OrbisComment], [String : Group], [String : OrbisUser], [String : PostCounter])> {
        var comments = [OrbisComment]()
        var counters = [String : PostCounter]()
        var groups = [String : Group]()
    
        return ref(postKey: postKey)
            .queryOrdered(byChild: "parentCommentKey").rx
            .observeSingleEvent(.value)
            .flatMap { (snapshot : DataSnapshot) -> Single<[String : PostCounter]> in
                for case let child as DataSnapshot in snapshot.children {
                    if let comment = child.valueToType(type: OrbisComment.self) {
                        comments.append(comment)
                    }
                }
            
                return CountersDAO.loadCommentsCounters(postKey: postKey)
            }
            .flatMap { (result : [String : PostCounter]) -> Single<[String : Group]> in
                counters = result
                
                let groupKeys = comments
                    .map { $0.groupKey }
                    .filter { $0 != nil }
                    .map { $0! }

                return GroupDAO.loadGrousAsDictionary(groupKeys: groupKeys)
            }
            .flatMap { (result : [String : Group]) -> Single<[String : OrbisUser]> in
                groups = result
                let userKeys = comments.map { $0.userId }
                return UserDAO.loadUsersByIds(userIds: userKeys)
            }
            .map { (users : [String : OrbisUser]) -> ([OrbisComment], [String : Group], [String : OrbisUser], [String : PostCounter]) in
                return (comments, groups, users, counters)
            }
    }
    
    static func observeCommentAdditions(postKey: String, serverTimestamp: Int64) -> Observable<OrbisComment?> {
        return ref(postKey: postKey)
            .queryOrdered(byChild: "serverTimestamp")
            .queryStarting(atValue: serverTimestamp+1).rx
            .observeEvent(.childAdded)
            .map { (snapshot : DataSnapshot) -> OrbisComment? in
                return snapshot.valueToType(type: OrbisComment.self)
            }
    }

}
