//
//  CountersDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 14/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import RxFirebaseDatabase
import Firebase
import CodableFirebase
import SwifterSwift
import FirebaseDatabase

class CountersDAO {
    
    private static let countersByPostRef = database().reference(withPath: "countersByPost")
    private static let countersByPostImageRef = database().reference(withPath: "countersByPostImage")
    private static let countersByCommentRef = database().reference(withPath: "countersByComment")
    
    private static func postRef(postKey: String) -> DatabaseReference {
        return countersByPostRef.child(postKey)
    }
    
    private static func imageRef(imageName: String) -> DatabaseReference {
        return countersByPostImageRef.child(imageName)
    }
    
    private static func commentRef(postKey: String) -> DatabaseReference {
        return countersByCommentRef.child(postKey)
    }
    
    private static func commentRef(postKey: String, commentKey: String) -> DatabaseReference {
        return commentRef(postKey: postKey).child(commentKey)
    }
    
    private static func serverTimestampRef(likeType: LikeType, mainKey: String) -> DatabaseReference {
        switch likeType {
        case .postImage:
            return imageRef(imageName: mainKey).child("serverTimestamp")
        default:
            return postRef(postKey: mainKey).child("serverTimestamp")
        }
    }
    
    static func loadCounter(postKey: String) -> Single<(String, PostCounter?)> {
        return postRef(postKey: postKey).rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> (String, PostCounter?) in
                //print2("Counter key: \(snapshot.key)")
                return (postKey, snapshot.valueToType(type: PostCounter.self))
            }
    }
    
    static func loadCounters(postKeys: [String]) -> Single<[String : PostCounter]> {
        return Observable.from(postKeys)
            .flatMap { (postKey : String) -> Single<(String, PostCounter?)> in
                return loadCounter(postKey: postKey)
            }
            .toArray()
            .map { (counters : [(String, PostCounter?)]) -> [String : PostCounter] in
                let tmp = counters.filter { return $0.1 != nil }
                    .map { return ($0.0, $0.1!) }

                var dict = [String : PostCounter]()
                tmp.forEach {
                    dict[$0.0] = $0.1
                }
                
                return dict
            }
    }
    
    static func loadCommentsCounters(postKey: String) -> Single<[String : PostCounter]> {
        return commentRef(postKey: postKey).rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> [String : PostCounter] in
                var result = [String : PostCounter]()
                
                print2("loadCommentsCounters[1] \(snapshot.key)")
                
                for case let snapshot2 as DataSnapshot in snapshot.children {
                    print2("loadCommentsCounters[2] \(snapshot2.key)")
                    
                    if let value = snapshot2.valueToType(type: PostCounter.self) {
                        print2("loadCommentsCounters[2] \(snapshot2.key) decoded")
                        result[snapshot2.key] = value
                    }
                }
                
                return result
            }
    }
    
    static func observePostCounterChanges(serverTimestamp: Int64) -> [Observable<(String, PostCounter?)>] {
        var observables = [Observable<(String, PostCounter?)>]()
        let eventTypes = [DataEventType.childAdded, DataEventType.childChanged]
        eventTypes.forEach { eventType in
            let obs = countersByPostRef
                .queryOrdered(byChild: "serverTimestamp")
                .queryStarting(atValue: serverTimestamp + 1, childKey: "serverTimestamp")
                .rx
                .observeEvent(eventType)
                .map { (snapshot : DataSnapshot) -> (String, PostCounter?) in
                    return (snapshot.key, snapshot.valueToType(type: PostCounter.self))
                }
            observables.append(obs)
        }
        return observables
    }
    
    static func observeImagesCounterChanges(post: OrbisPost) -> [Observable<(String, PostCounter?)>]? {
        guard let urls = post.imageUrls else {
            return nil
        }

        let images = urls.map { string in return string.deletingPathExtension }
        var observables = [Observable<(String, PostCounter?)>]()
        
        images.forEach { imageName in
            [DataEventType.childAdded, DataEventType.childChanged].forEach { eventType in
                let obs = imageRef(imageName: imageName).rx
                    .observeEvent(eventType)
                    .map { (snapshot : DataSnapshot) -> (String, PostCounter?) in
                        if snapshot.key == "likesCount" {
                            let counter = PostCounter(commentsCount: 0, likesCount: snapshot.valueToType(type: Int.self) ?? 0, serverDate: nil)
                            return (imageName, counter)
                        }
                        else {
                            return (imageName, nil)
                        }
                }
                observables.append(obs)
            }
        }
    
        return observables
    }
    
    static func observeCommentsCounterChanges(post: OrbisPost) -> Observable<(String, PostCounter?)> {
        return commentRef(postKey: post.postKey).rx
            .observeEvent(.childChanged)
            .map { (snapshot : DataSnapshot) -> (String, PostCounter?) in
                print2("[Comments] Counter Changes key: \(snapshot.key)")
                return (snapshot.key, snapshot.valueToType(type: PostCounter.self))
            }
    }
    
    static func updateLikesCount(likeType: LikeType, mainKey: String, increment: Int, superKey: String? = nil) -> Single<DatabaseReference> {
        return updateCount(likeType: likeType, mainKey: mainKey, increment: increment, superKey: superKey, fieldKey: "likesCount")
    }
    
    static func updateCommentsCount(likeType: LikeType, mainKey: String, increment: Int, superKey: String? = nil) -> Single<DatabaseReference> {
        return updateCount(likeType: likeType, mainKey: mainKey, increment: increment, superKey: superKey, fieldKey: "commentsCount")
    }

    private static func updateCount(likeType: LikeType, mainKey: String, increment: Int, superKey: String? = nil, fieldKey: String) -> Single<DatabaseReference> {
        let ref: DatabaseReference

        switch likeType {
        case .post:
            ref = postRef(postKey: mainKey)
        case .postImage:
            ref = imageRef(imageName: mainKey)
        case .comment:
            ref = commentRef(postKey: superKey!, commentKey: mainKey)
        }
        
        return ref.rx
            .runTransactionBlock { currentData in
                if let value = currentData.value, var dict = value as? [String : AnyObject] {
                    let count = (dict[fieldKey] as? Int ?? 0) + increment
                    dict[fieldKey] = count as AnyObject
                    currentData.value = dict
                }
                else {
                    var dict = [String : AnyObject]()
                    dict[fieldKey] = increment as AnyObject
                    currentData.value = dict
                }
                
                return TransactionResult.success(withValue: currentData)
            }
            .flatMap { (result : DatabaseReferenceTransactionResult) -> Single<DatabaseReference> in
                return updateServerTimestamp(likeType: likeType, mainKey: mainKey)
            }
    }
    
    private static func updateServerTimestamp(likeType: LikeType, mainKey: String) -> Single<DatabaseReference> {
        return serverTimestampRef(likeType: likeType, mainKey: mainKey).rx
            .setValue(ServerValue.timestamp())
    }
}

