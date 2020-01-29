//
//  RolesDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import Firebase
import RxFirebaseDatabase
import FirebaseDatabase
import RxSwift

class RoleDAO {
    
    // User --> Group
    private static let rolesInGroupRef = database().reference(withPath: "groupsByUser")
    
    // User --> Place
    private static let rolesInPlaceRef = database().reference(withPath: "placesByUser")
    
    // Group --> User
    private static let rolesInUserRef = database().reference(withPath: "usersByGroup")
   
    private static func rolesInGroupReference(userId: String, groupId: String? = nil, role: Roles? = nil) -> DatabaseReference {
        var ref = rolesInGroupRef.child(userId)
        
        if let groupId = groupId {
            ref = ref.child(groupId)
            if let role = role {
                ref = ref.child(String(role.rawValue))
            }
        }
        
        return ref
    }
    
    private static func rolesInPlaceRef(userId: String, placeId: String? = nil, role: Roles? = nil) -> DatabaseReference {
        var ref = rolesInPlaceRef.child(userId)
        
        if let placeId = placeId {
            ref = ref.child(placeId)
            if let role = role {
                ref = ref.child(String(role.rawValue))
            }
        }
        
        return ref
    }
    
    private static func rolesInUserRef(groupId: String, userId: String? = nil, role: Roles? = nil) -> DatabaseReference {
        var ref = rolesInUserRef.child(groupId)
        
        if let userId = userId {
            ref = ref.child(userId)
            if let role = role {
                ref = ref.child(String(role.rawValue))
            }
        }
        
        return ref
    }
    
    private static func rolesInGroupServerTimestampRef(userId: String, groupId: String) -> DatabaseReference {
        return rolesInGroupReference(userId: userId, groupId: groupId).child("serverTimestamp")
    }
    
    private static func rolesInUserServerTimestampRef(groupId: String, userId: String) -> DatabaseReference {
        return rolesInUserRef(groupId: groupId, userId: userId).child("serverTimestamp")
    }
    
    static func saveRoleInGroup(userId: String, groupId: String, role: Roles, add: Bool) -> Single<Bool> {
        let myUser = UserDefaultsRepository.instance().getMyUser()
        let isMe = myUser?.uid == userId
        let shouldSubscribe = add && (role == Roles.member || role == Roles.follower)
        let shouldUnsubscribe = !add && (role == Roles.member || role == Roles.follower)
        var group: Group?
        
        print2("[Push] saveRoleInGroup role: \(role) add: \(add) shouldSubscribe: \(shouldSubscribe) shouldUnsubscribe: \(shouldUnsubscribe)")
        
        var databaseObservable = rolesInGroupReference(userId: userId, groupId: groupId, role: role).rx
            .setValue(add)
            .flatMap { _ in
                saveRoleInUser(groupId: groupId, userId: userId, role: role, add: add)
            }
        
        // Join / leave implicates follow / stop follow
        if role == Roles.member {
            databaseObservable = databaseObservable.flatMap { ref in
                rolesInGroupReference(userId: userId, groupId: groupId, role: Roles.follower).rx
                    .setValue(add)
            }
            .flatMap { _ in
                saveRoleInUser(groupId: groupId, userId: userId, role: Roles.follower, add: add)
            }

            if add && isMe {
                return databaseObservable
                    .flatMap { ref in
                        UserDAO.saveActiveGroup(userId: userId, groupId: groupId)
                    }
                    .flatMap { (res : HandlePresenceEventResponse?) -> Single<Group?> in
                        return GroupDAO.findByKey(groupKey: groupId)
                    }
                    .flatMap { (g: Group?) -> Single<Bool> in
                        group = g
                        if let g = g {
                            HelperRepository.instance().setActiveGroup(group: g, updateUser: true)
                        }
                        return topicObservable(topic: groupId, shouldSubscribe: shouldSubscribe, shouldUnsubscribe: shouldUnsubscribe)
                    }
                    .flatMap { (_: Bool) -> Single<Bool> in
                        if let group = group {
                            let pnData = JoinNotificationData(requestCode: RequestCode.joined, user: myUser!, group: group)
                            return CloudFunctionsDAO.sendNotificationToTopic(topic: "'\(group.key!)' in topics", data: pnData.toDict())
                        }
                        else {
                            return Single.just(true)
                        }
                    }
            }
            
            if !add {
                let isMyActiveGroup = isMe && UserDefaultsRepository.instance().getActiveGroup()?.key == groupId
                
                if isMyActiveGroup {
                    return databaseObservable.flatMap { ref in
                        UserDAO.clearActiveGroup(userId: userId)
                            .flatMap { (res : HandlePresenceEventResponse?) -> Single<Bool> in
                                HelperRepository.instance().setActiveGroup(group: nil, updateUser: false)
                                return topicObservable(topic: groupId, shouldSubscribe: shouldSubscribe, shouldUnsubscribe: shouldUnsubscribe)
                            }
                    }
                }
                else if !isMe {
                    return databaseObservable.flatMap { ref in
                        UserDAO.clearActiveGroupIfNecessary(userId: userId, groupKey: groupId)
                            .asObservable().asSingle()
                            .flatMap { _ in
                                return topicObservable(topic: groupId, shouldSubscribe: shouldSubscribe, shouldUnsubscribe: shouldUnsubscribe)
                            }
                    }
                }
            }
            
        }
    
        return databaseObservable.flatMap { _ in
            return topicObservable(topic: groupId, shouldSubscribe: shouldSubscribe, shouldUnsubscribe: shouldUnsubscribe)
        }
    }
    
    private static func topicObservable(topic: String, shouldSubscribe: Bool, shouldUnsubscribe: Bool) -> Single<Bool> {
        if shouldSubscribe {
            NotificationUtils.subscribeTo(topic: topic)
        }
        else if shouldUnsubscribe {
            NotificationUtils.unsubscribeFrom(topic: topic)
        }
        
        return Single.just(true)
    }
    
    static func saveRoleInPlace(userId: String, placeId: String, role: Roles, add: Bool) -> Single<Bool> {
        return rolesInPlaceRef(userId: userId, placeId: placeId, role: role).rx
            .setValue(add)
            .flatMap { _ in
                return topicObservable(topic: placeId, shouldSubscribe: add, shouldUnsubscribe: !add)
            }
    }
    
    static func saveRoleInUser(groupId: String, userId: String, role: Roles, add: Bool, isMainAction: Bool = false) -> Single<DatabaseReference> {
        var observable = rolesInUserRef(groupId: groupId, userId: userId, role: role).rx
            .setValue(add)
    
        if isMainAction {
            observable = observable.flatMap { _ in
                return rolesInGroupReference(userId: userId, groupId: groupId, role: role).rx
                    .setValue(add)
            }
        }
        
        return observable
    }
    
    static func getRolesOfUserInGroups(userId: String?, requiredRole: Roles? = nil) -> Single<[String : [Roles]]> {
        guard let userId = userId else {
            return Single.just([String : [Roles]]())
        }
        
        return RoleDAO.rolesInGroupReference(userId: userId).rx
            .observeSingleEvent(.value)
            .flatMap({ (snapshot: DataSnapshot) -> Single<[String : [Roles]]> in
                var map = [String : [Roles]]()
                
                for case let snapshot2 as DataSnapshot in snapshot.children {
                    let groupKey = snapshot2.key
                    map[groupKey] = snapshotToRoles(snapshot: snapshot2)
                }
                
                if let role = requiredRole {
                    map = map.filter { (key: String, roles: [Roles]) in
                        return roles.contains(role)
                    }
                }
                
                return Single.just(map)
            })
    }
    
    static func rolesOfUserInGroupsChildAdditions(userId: String) -> Observable<(String, [Roles])> {
        return RoleDAO.rolesInGroupReference(userId: userId).rx
            .observeEvent(.childAdded)
            .flatMap { (snapshot : DataSnapshot) -> Observable<(String, [Roles])> in
                let groupKey = snapshot.key
                let roles = RoleDAO.snapshotToRoles(snapshot: snapshot)
                return Observable.just((groupKey, roles))
            }
    }
    
    static func rolesOfUserInGroupsChildChanges(userId: String) -> Observable<(String, [Roles])> {
        return RoleDAO.rolesInGroupReference(userId: userId).rx
            .observeEvent(.childChanged)
            .flatMap { (snapshot : DataSnapshot) -> Observable<(String, [Roles])> in
                let groupKey = snapshot.key
                let roles = RoleDAO.snapshotToRoles(snapshot: snapshot)
                return Observable.just((groupKey, roles))
        }
    }
    
    static func rolesOfUserInGroupsChildValue(userId: String) -> Observable<(String, [Roles])> {
        return RoleDAO.rolesInGroupReference(userId: userId).rx
            .observeEvent(.value)
            .flatMap { (snapshot : DataSnapshot) -> Observable<(String, [Roles])> in
                let groupKey = snapshot.key
                let roles = RoleDAO.snapshotToRoles(snapshot: snapshot)
                return Observable.just((groupKey, roles))
        }
    }
    
    static func rolesOfUserInPlacesChildAdditions(userId: String) -> Observable<(String, [Roles])> {
        return RoleDAO.rolesInPlaceRef(userId: userId).rx
            .observeEvent(.childAdded)
            .flatMap { (snapshot : DataSnapshot) -> Observable<(String, [Roles])> in
                let placeKey = snapshot.key
                let roles = RoleDAO.snapshotToRoles(snapshot: snapshot)
                return Observable.just((placeKey, roles))
        }
    }
    
    static func rolesOfUserInPlacesChildChanges(userId: String) -> Observable<(String, [Roles])> {
        return RoleDAO.rolesInPlaceRef(userId: userId).rx
            .observeEvent(.childChanged)
            .flatMap { (snapshot : DataSnapshot) -> Observable<(String, [Roles])> in
                let placeKey = snapshot.key
                let roles = RoleDAO.snapshotToRoles(snapshot: snapshot)
                return Observable.just((placeKey, roles))
        }
    }
    
    static func rolesOfUserInPlacesChildValue(userId: String) -> Observable<(String, [Roles])> {
        return RoleDAO.rolesInPlaceRef(userId: userId).rx
            .observeEvent(.value)
            .flatMap { (snapshot : DataSnapshot) -> Observable<(String, [Roles])> in
                let placeKey = snapshot.key
                let roles = RoleDAO.snapshotToRoles(snapshot: snapshot)
                return Observable.just((placeKey, roles))
        }
    }
    
    static func rolesOfUserInPlaces(userId: String, requiredRole: Roles? = nil) -> Single<[String : [Roles]]> {
        return RoleDAO.rolesInPlaceRef(userId: userId).rx
            .observeSingleEvent(.value)
            .map { (snapshot: DataSnapshot) -> [String : [Roles]] in
                var map = [String : [Roles]]()
                
                for case let snapshot2 as DataSnapshot in snapshot.children {
                    let placeKey = snapshot2.key
                    map[placeKey] = snapshotToRoles(snapshot: snapshot2)
                }
                
                if let role = requiredRole {
                    map = map.filter { (key: String, roles: [Roles]) in
                        return roles.contains(role)
                    }
                }
                
                return map
            }
    }
    
    static func rolesOfUserInPlace(userId: String, placeId: String) -> Single<(String, [Roles])> {
        return RoleDAO.rolesInPlaceRef(userId: userId, placeId: placeId).rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> (String, [Roles]) in
                let placeKey = snapshot.key
                let roles = RoleDAO.snapshotToRoles(snapshot: snapshot)
                return (placeKey, roles)
            }
    }
    
    static func allRolesInGroup(groupKey: String) -> Single<[String : [Roles]]> {
        return rolesInUserRef(groupId: groupKey).rx
            .observeSingleEvent(.value)
            .map({ (snapshot: DataSnapshot) -> [String : [Roles]] in
                var map = [String : [Roles]]()
                for case let snapshot2 as DataSnapshot in snapshot.children {
                    map[snapshot2.key] = snapshotToRoles(snapshot: snapshot2)
                }
                return map
            })
    }
    
    static func allRolesInChildChangesGroup(groupKey: String) -> Observable<(String , [Roles])> {
        return rolesInUserRef(groupId: groupKey).rx
            .observeEvent(.childChanged)
            .map({ (snapshot: DataSnapshot) -> (String, [Roles]) in
                let userKey = snapshot.key
                let roles = snapshotToRoles(snapshot: snapshot)
                return (userKey, roles)
            })
    }
    
    private static func snapshotToRoles(snapshot: DataSnapshot) -> [Roles] {
        var roles = [Roles]()
        
        for case let data as DataSnapshot in snapshot.children {
            if data.key == "serverTimestamp" {
                
            }
            else if
                let value = data.value as? Bool,
                let rawValue = Int(data.key),
                let role = Roles(rawValue: rawValue), value {
                roles.append(role)
            }
        }
        
        return roles
    }
   
}
