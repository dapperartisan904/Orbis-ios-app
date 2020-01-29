//
//  PostDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 07/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import RxFirebaseDatabase
import Firebase
import FirebaseDatabase
import CodableFirebase

class PostDAO {
    
    private static let postsRef = database().reference(withPath: "posts")
    private static let postsByGroupRef = database().reference(withPath: "postsByGroup")
    private static let postsByPlaceRef = database().reference(withPath: "postsByPlace")
    
    private static func postRef(postKey: String) -> DatabaseReference {
        return postsRef.child(postKey)
    }
    
    private static func postsByGroupRef(groupKey: String) -> DatabaseReference {
        return postsByGroupRef.child(groupKey)
    }
    
    private static func postsByPlaceRef(placeKey: String) -> DatabaseReference {
        return postsByPlaceRef.child(placeKey)
    }
    
    static func newKey() -> String? {
        return postsRef.childByAutoId().key
    }
    
    private static func save(post: OrbisPost, value: OrbisPost?, group: Group?, place: Place?) -> Single<Bool> {
        let data = try! FirebaseEncoder().encode(value)
        return postRef(postKey: post.postKey).rx
            .setValue(data)
            .flatMap { (_ : DatabaseReference) -> Single<DatabaseReference?> in
                if let k = post.winnerGroupKey {
                    print2("save post [1]")
                    return postsByGroupRef(groupKey: k)
                        .child(post.postKey).rx
                        .setValue(data)
                        .map { ref in
                            let opt: DatabaseReference? = ref
                            return opt
                        }
                }
                else {
                    print2("save post [2]")
                    return Single.just(nil)
                }
            }
            .flatMap { (_ : DatabaseReference?) -> Single<DatabaseReference?> in
                if let k = post.loserGroupKey {
                    print2("save post [3]")
                    return postsByGroupRef(groupKey: k)
                        .child(post.postKey).rx
                        .setValue(data)
                        .map { ref in
                            let opt: DatabaseReference? = ref
                            return opt
                        }
                }
                else {
                    print2("save post [4]")
                    return Single.just(nil)
                }
            }
            .flatMap { (_ : DatabaseReference?) -> Single<DatabaseReference?> in
                if let k = post.placeKey {
                    print2("save post [5]")
                    return postsByPlaceRef(placeKey: k)
                        .child(post.postKey).rx
                        .setValue(data)
                        .map { ref in
                            let opt: DatabaseReference? = ref
                            return opt
                        }
                }
                else {
                    print2("save post [6]")
                    return Single.just(nil)
                }
            }
            .flatMap { (_ : DatabaseReference?) -> Single<Bool> in
                print2("save post [7]")
                
                if value == nil {
                    return GeoFireDAO.deletePostLocation(post: post)
                }
                else {
                    return GeoFireDAO.savePostLocation(post: post)
                }
            }
            .flatMap { (_ : Bool) -> Single<Bool> in
                print2("save post [8]")
                
                let arg0 = UserDefaultsRepository.instance().getMyUser()?.username ?? ""
                let arg1 = place?.name ?? group?.name ?? ""
                
                var topic = ""
                if let placeKey = post.placeKey, let groupKey = post.winnerGroupKey {
                    topic = "'\(groupKey)' in topics || '\(placeKey)' in topics"
                }
                else if let groupKey = post.winnerGroupKey {
                    topic = "'\(groupKey)' in topics"
                }

                let pushData = PostNotificationData(
                    requestCode: RequestCode.openPost,
                    post: post,
                    senderId: UserDefaultsRepository.instance().getMyUser()?.uid,
                    titleLoc: "notification_post_title",
                    messageLoc: "notification_post_message",
                    messageArgs: [arg0, arg1])
            
                return CloudFunctionsDAO.sendNotificationToTopic(topic: topic, data: pushData.toDict())
            }
    }
    
    static func save(post: OrbisPost, group: Group?, place: Place?) -> Single<Bool> {
        return save(post: post, value: post, group: group, place: place)
    }
    
    static func delete(post: OrbisPost) -> Single<Bool> {
        return save(post: post, value: nil, group: nil, place: nil)
    }
    
    private static func serverTimestampRef(postKey: String) -> DatabaseReference {
        return postRef(postKey: postKey).child("serverTimestamp")
    }
    
    private static func updateServerTimestamp(postKey: String) -> Single<DatabaseReference> {
        return serverTimestampRef(postKey: postKey).rx.setValue(ServerValue.timestamp())
    }
    
    static func loadAllPosts() -> Single<[OrbisPost]> {
        return postsRef.rx
            .observeSingleEvent(.value)
            .map { snapshot -> [OrbisPost] in
                return snapshotToPosts(snapshot: snapshot)
            }
            //.single()
    }
    
    static func load(postKey: String?) -> Single<OrbisPost?> {
        guard let postKey = postKey else {
            return Single.just(nil)
        }
        
        return postRef(postKey: postKey).rx
            .observeSingleEvent(.value)
            .flatMap({ (snapshot: DataSnapshot) -> Single<OrbisPost?> in
                return Single.just(snapshot.valueToType(type: OrbisPost.self))
            })
    }
    
    static func loadWrapper(postKey: String, activeGroup: Group?) -> Single<PostWrapper?> {
        return PostDAO.load(postKey: postKey)
            .flatMap { (post: OrbisPost?) -> Single<PostWrapper?> in
                guard let post = post else {
                    return Single.just(nil)
                }
                return PostDAO.loadWrapper(post: post, activeGroup: activeGroup)
            }
    }
    
    static func loadWrapper(post: OrbisPost, activeGroup: Group?) -> Single<PostWrapper?> {
        guard let userKey = post.userKey else {
            return Single.just(nil)
        }
    
        return UserDAO.load(userId: userKey)
            .flatMap { (user: OrbisUser?) -> Single<PostWrapper?> in
                guard let user = user else {
                    return Single.just(nil)
                }
                return PostDAO.loadWrapper(post: post, user: user, activeGroup: activeGroup)
            }
    }
    
    static func loadWrapper(post: OrbisPost, user: OrbisUser, activeGroup: Group?) -> Single<PostWrapper?> {
        let wrapper = PostWrapper(
            post: post,
            winnerGroup: nil,
            loserGroup: nil,
            activeGroup: activeGroup,
            user: user,
            place: nil,
            counter: nil,
            isLiking: false)
        
        var groupKeys = [String]()
        
        if let k = post.winnerGroupKey {
            groupKeys.append(k)
        }
        
        if let k = post.loserGroupKey {
            groupKeys.append(k)
        }
    
        return GroupDAO.loadGroups(groupKeys: groupKeys)
            .flatMap({ (groups: [Group?]) -> Single<Place?> in
                groups.forEach {
                    if $0?.key == post.winnerGroupKey {
                        wrapper.winnerGroup = $0
                    }
                    else if $0?.key == post.loserGroupKey {
                        wrapper.loserGroup = $0
                    }
                }
                
                return PlaceDAO.load(placeKey: post.placeKey)
            })
            .flatMap({ (place: Place?) -> Single<(String, PostCounter?)> in
                wrapper.place = place
                return CountersDAO.loadCounter(postKey: post.postKey)
            })
            .map { (counter: (String, PostCounter?)) -> PostWrapper in
                wrapper.counter = counter.1
                return wrapper
            }
    }
    
    static func loadPostsByKeys(postKeys: [String]) -> Single<[String : OrbisPost]> {
        return Observable
            .from(postKeys)
            .flatMap { (postKey : String) -> Single<OrbisPost?> in
                return load(postKey: postKey)
            }
            .toArray()
            .map { (posts : [OrbisPost?]) -> [String : OrbisPost] in
                let items = posts.filter { post in return post != nil }
                var result = [String : OrbisPost]()
                items.forEach { post in result[post!.postKey] = post! }
                return result
            }
    }
    
    static func loadPostsByGroup(groupKey: String) -> Single<[OrbisPost]> {
        return postsByGroupRef(groupKey: groupKey).rx
            .observeSingleEvent(.value)
            .map { snapshot -> [OrbisPost] in
                return snapshotToPosts(snapshot: snapshot)
            }
    }
    
    static func loadPostsByGroups(groupKeys: [String]) -> Single<[OrbisPost]> {
        return Observable.from(groupKeys)
            .flatMap { groupKey in
                return loadPostsByGroup(groupKey: groupKey)
            }
            .toArray()
            .map { array in
                array.flatMap { return $0 }
            }
    }
    
    static func loadPostsByPlace(placeKey: String) -> Single<[OrbisPost]> {
        return postsByPlaceRef(placeKey: placeKey).rx
            .observeSingleEvent(.value)
            .map { snapshot -> [OrbisPost] in
                return snapshotToPosts(snapshot: snapshot)
            }
    }
    
    static func loadPostsByPlaces(placeKeys: [String]) -> Single<[OrbisPost]> {
        return Observable.from(placeKeys)
            .flatMap { placeKey in
                return loadPostsByPlace(placeKey: placeKey)
            }
            .toArray()
            .map { array in
                array.flatMap { return $0 }
            }
    }
    
    static func loadPostsByUser(userKey: String, types: [PostType?]?) -> Single<[OrbisPost]> {
        var hiddenPosts = [String : HiddenPost]()
        
        return HiddenPostsDAO.loadHiddenPosts(userId: userKey)
            .flatMap { result in
                hiddenPosts = result
                
                return postsRef
                    .queryOrdered(byChild: "userKey")
                    .queryEqual(toValue: userKey).rx
                    .observeSingleEvent(.value)
            }
            .map { (snapshot : DataSnapshot) -> [OrbisPost] in
                var posts = snapshotToPosts(snapshot: snapshot)

                if let types = types {
                    posts = posts.filter({ types.contains($0.typeEnum()) })
                }
                
                posts = posts
                    .filter { post in
                        !hiddenPosts.has(key: post.postKey)
                    }
                    .sorted(by: \OrbisPost.serverTimestamp2, ascending: false)
                return posts
        }
    }
    
    static func loadMaxTimestamp() -> Single<Int64> {
        return postsRef
            .queryOrdered(byChild: "serverTimestamp2")
            .queryLimited(toLast: 1).rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> Int64 in
                if let post = snapshot.firstChild(type: OrbisPost.self) {
                    return post.serverTimestamp2
                }
                else {
                    return 0
                }
            }
    }
    
    static func postsChildValuesObservers(includeAdditions: Bool) -> [Observable<(DataEventType, OrbisPost?)>] {
        return childValuesObservers(reference: postsRef, includeAdditions: true, includeChanges: false)
    }
    
    static func postsByGroupChildValuesObservers(groupKey: String) -> [Observable<(DataEventType, OrbisPost?)>] {
        return childValuesObservers(reference: postsByGroupRef(groupKey: groupKey), includeAdditions: true, includeChanges: false)
    }
    
    static func postsByPlaceChildValuesObservers(placeKey: String, includeAdditions: Bool, includeChanges: Bool) -> [Observable<(DataEventType, OrbisPost?)>] {
        return childValuesObservers(reference: postsByPlaceRef(placeKey: placeKey), includeAdditions: includeAdditions, includeChanges: includeChanges)
    }
    
    private static func childValuesObservers(reference: DatabaseReference, includeAdditions: Bool, includeChanges: Bool) -> [Observable<(DataEventType, OrbisPost?)>] {
        let obs1 = PostDAO.loadMaxTimestamp()
            .asObservable()
            .flatMap { (timestamp : Int64) -> Observable<DataSnapshot> in
                print2("PostDAO.loadMaxTimestamp: \(timestamp)")
                
                return reference
                    .queryOrdered(byChild: "serverTimestamp2")
                    .queryStarting(atValue: timestamp+1)
                    .rx.observeEvent(.childAdded)
            }
            .map { (snapsthot : DataSnapshot) -> (DataEventType, OrbisPost?) in
                return (DataEventType.childAdded, snapsthot.valueToType(type: OrbisPost.self))
        }
        
        let obs2 = PostDAO.loadMaxTimestamp()
            .asObservable()
            .flatMap { (timestamp : Int64) -> Observable<DataSnapshot> in
                print2("PostDAO.loadMaxTimestamp: \(timestamp)")
                
                return reference
                    .queryOrdered(byChild: "serverTimestamp2")
                    .queryStarting(atValue: timestamp+1)
                    .rx.observeEvent(.childChanged)
            }
            .map { (snapsthot : DataSnapshot) -> (DataEventType, OrbisPost?) in
                return (DataEventType.childChanged, snapsthot.valueToType(type: OrbisPost.self))
        }
        
        let obs3 = reference.rx.observeEvent(.childRemoved)
            .map { (snapsthot : DataSnapshot) -> (DataEventType, OrbisPost?) in
                return (DataEventType.childRemoved, snapsthot.valueToType(type: OrbisPost.self))
        }
        
        var observables = [obs3]
        
        if includeAdditions {
            observables.append(obs1)
        }
        
        if includeChanges {
            observables.append(obs2)
        }
        
        return observables
    }
    
    private static func snapshotToPosts(snapshot: DataSnapshot) -> [OrbisPost] {
        var posts = [OrbisPost]()
        for case let snapshot2 as DataSnapshot in snapshot.children {
            if let post = snapshot2.valueToType(type: OrbisPost.self) {
                posts.append(post)
            }
        }
        return posts
    }
}
