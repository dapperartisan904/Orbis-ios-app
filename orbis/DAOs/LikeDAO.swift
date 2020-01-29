//
//  LikeDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 12/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import Firebase
import RxFirebaseDatabase
import RxSwift
import CodableFirebase
import FirebaseDatabase

class LikeDAO {
    
    private static let likesByCommentRef = database().reference(withPath: "likesByComment")
    private static let likesByPostImageRef = database().reference(withPath: "likesByPostImage")
    private static let likesByPostRef = database().reference(withPath: "likesByPost")
    private static let likesByUserRef = database().reference(withPath: "likesByUser")
    
    private static func userLikesRef(userId: String) -> DatabaseReference {
        return likesByUserRef.child(userId)
    }
    
    private static func userLikesRef(userId: String, likeType: LikeType, likeInfo: LikeInfo) -> DatabaseReference {
        return userLikesRef(userId: userId)
            .child(likeType.rawValue)
            .child(likeInfo.mainKey)
    }
    
    private static func userLikesRefToPostImages(userId: String) -> DatabaseReference {
        return userLikesRef(userId: userId).child("postImages")
    }
    
    private static func userLikesRef(userId: String, imageName: String) -> DatabaseReference {
        return userLikesRefToPostImages(userId: userId).child(imageName)
    }
    
    static func userLikesSnapshotToDictionay(snapshot: DataSnapshot) -> [LikeType : [String : LikeInfo]] {
        var likes = [LikeType : [String : LikeInfo]]()
        
        for case let snapshot2 as DataSnapshot in snapshot.children {
            print2("[LikesByUser] snapshot2 key: \(snapshot2.key)")
            
            guard let type = LikeType.init(rawValue: snapshot2.key) else {
                print2("[LikesByUser] unknown like type")
                continue
            }
            
            var likesByType = [String : LikeInfo]()
            
            for case let snapshot3 as DataSnapshot in snapshot2.children {
                if let likeInfo = snapshot3.valueToType(type: LikeInfo.self) {
                    likesByType[snapshot3.key] = likeInfo
                }
            }
            
            likes[type] = likesByType
        }
        
        return likes
    }
    
    static func loadUserLikes(userId: String?) -> Single<[LikeType : [String : LikeInfo]]> {
        guard let userId = userId else {
            return Single.just([LikeType : [String : LikeInfo]]())
        }
    
        return userLikesRef(userId: userId).rx
            .observeSingleEvent(.value)
            .map { snapshot -> [LikeType : [String : LikeInfo]] in
                return userLikesSnapshotToDictionay(snapshot: snapshot)
            }
    }
    
    static func observeLikeChanges(userId: String?, serverTimestamp: Int64) -> [Observable<(LikeType, LikeInfo?)>]? {
        guard let userId = userId else {
            return nil
        }
    
        print2("[LikesDebug] observeLikeChanges userId: \(userId) serverTimestamp: \(serverTimestamp)")
        
        // .childAdded is required in case addition is made by Android
        let eventTypes = [DataEventType.childAdded, DataEventType.childChanged]
        var observables = [Observable<(LikeType, LikeInfo?)>]()
        
        LikeType.allCases.forEach { likeType in
            eventTypes.forEach { eventType in
                let obs = userLikesRef(userId: userId)
                    .child(likeType.rawValue)
                    .queryOrdered(byChild: "serverTimestamp")
                    .queryStarting(atValue: serverTimestamp + 1, childKey: "serverTimestamp")
                    .rx
                    .observeEvent(eventType)
                    .map { snapshot -> (LikeType, LikeInfo?) in
                        print2("[LikesDebug] [\(likeType.rawValue)] [\(eventType.rawValue)] observeLikeChanges key: \(snapshot.key)")
                        
                        for case let snapshot2 as DataSnapshot in snapshot.children {
                            print2("[LikesDebug] [\(likeType.rawValue)] [\(eventType.rawValue)] observeLikeChanges key[2]: \(snapshot2.key) \(String(describing: snapshot2.value))")
                        }
                        
                        return (likeType, snapshot.valueToType(type: LikeInfo.self))
                }
                
                observables.append(obs)
            }
        }
        
        return observables
    }
    
    static func saveMyLike(userId: String, likeType: LikeType, mainKey: String, value: Bool, receiverId: String?, postKey: String) -> Single<Bool> {
        let likeInfo = LikeInfo(mainKey: mainKey, liked: value, serverDate: nil)
        let data = try! FirebaseEncoder().encode(likeInfo)
        let notificationSingle: Single<Bool>
        
        if let myUser = UserDefaultsRepository.instance().getMyUser(), let receiverId = receiverId, value {
            let pushData = LikedNotificationData(
                requestCode: RequestCode.liked,
                receiverId: receiverId,
                liked: value,
                likeType: likeType,
                postKey: postKey,
                senderId: userId,
                titleLoc: "notification_liked_title",
                messageLoc: likeType.localizableMsg(),
                messageArgs: [myUser.username])
            
            print2("pushData: \(pushData.toDict())")
            
            notificationSingle = CloudFunctionsDAO.sendNotificationToUser(userId: receiverId, data: pushData.toDict())
        }
        else {
            notificationSingle = Single.just(true)
        }
        
        return userLikesRef(userId: userId, likeType: likeType, likeInfo: likeInfo).rx
            .setValue(data)
            .flatMap { (_ : DatabaseReference) -> Single<Bool> in
                return notificationSingle
            }
    }

    private static func saveLikeOnUsers(userId: String, likeType: LikeType, mainKey: String) {
        
    }
}
