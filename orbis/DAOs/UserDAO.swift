//
//  UserDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseFunctions
import RxFirebaseDatabase
import RxSwift
import CodableFirebase


// http://cocoapods.org/pods/RxFirebase
class UserDAO {

    private static let reference = database().reference(withPath: "users")
    
    private static func userRef(userId: String) -> DatabaseReference {
        return reference.child(userId)
    }
    
    private static func checkInRef(userId: String) -> DatabaseReference {
        return userRef(userId: userId).child("checkIn")
    }
    
    private static func activeGroupRef(userId: String) -> DatabaseReference {
        return userRef(userId: userId).child("activeGroupId")
    }
    
    private static func groupsArePublicRef(userId: String) -> DatabaseReference {
        return userRef(userId: userId).child("groupsArePublic")
    }
    
    private static func placesArePublicRef(userId: String) -> DatabaseReference {
        return userRef(userId: userId).child("placesArePublic")
    }

    private static func fcmTokenRef(userId: String) -> DatabaseReference {
        return userRef(userId: userId).child("fcmToken")
    }
    
    private static func notificationsRef(userId: String) -> DatabaseReference {
        return userRef(userId: userId).child("pushNotificationsEnabled")
    }
    
    private static func unitRef(userId: String) -> DatabaseReference {
        return userRef(userId: userId).child("unit")
    }
    
    private static func languageRef(userId: String) -> DatabaseReference {
        return userRef(userId: userId).child("language")
    }
    
    static func findFirstByUsername(username: String) -> Single<OrbisUser?> {
        return reference
            .queryOrdered(byChild: "username")
            .queryEqual(toValue: username)
            .queryLimited(toFirst: 1)
            .rx
            .observeSingleEvent(.value)
            .flatMap({ (snapshot: DataSnapshot) -> Single<OrbisUser?> in
                print("findFirstByUsername [1]")
                return Single.just(snapshot.firstChild(type: OrbisUser.self))
            })
    }
    
    static func load(userId: String?) -> Single<OrbisUser?> {
        guard let userId = userId else {
            return Single.just(nil)
        }
    
        return userRef(userId: userId).rx
            .observeSingleEvent(.value)
            .map { snapshot in return snapshot.valueToType(type: OrbisUser.self) }
    }
    
    static func loadUsersByIds(userIds: [String]) -> Single<[String : OrbisUser]> {
        return Observable
            .from(userIds)
            .flatMap { (userId : String) -> Single<OrbisUser?> in
                return load(userId: userId)
            }
            .toArray()
            .map { (users : [OrbisUser?]) -> [String : OrbisUser] in
                let filteredUsers = users.filter { user in return user != nil }
                var result = [String : OrbisUser]()
                filteredUsers.forEach { user in result[user!.uid] = user! }
                return result
            }
    }
    
    static func loadCheckIn(userId: String) -> Single<PresenceEvent?> {
        return checkInRef(userId: userId).rx
            .observeSingleEvent(.value)
            .map { snapshot -> PresenceEvent? in
                if snapshot.exists() {
                    return snapshot.valueToType(type: PresenceEvent.self)
                }
                else {
                    return nil
                }

            }
    }

    static func clearActiveGroup(userId: String) -> Single<HandlePresenceEventResponse?> {
        return UserDAO.saveActiveGroup(userId: userId, groupId: "")
    }

    /*
        groupKey refers to group that user lost membership
     */
    static func clearActiveGroupIfNecessary(userId: String, groupKey: String) -> Completable {
        return load(userId: userId)
            .flatMap { (user : OrbisUser?) -> Single<HandlePresenceEventResponse?> in
                guard let user = user, user.activeGroupId == userId else {
                    return Single.just(nil)
                }
                return clearActiveGroup(userId: userId)
            }
            .asCompletable()
    }
    
    static func saveActiveGroup(userId: String, groupId: String) -> Single<HandlePresenceEventResponse?> {
        return activeGroupRef(userId: userId).rx
            .setValue(groupId)
            .flatMap { ref -> Single<HandlePresenceEventResponse?> in
                return UserDAO.checkOut(userId: userId)
            }
    }
    
    static func save(user: OrbisUser) -> Single<DatabaseReference> {
        let data = try! FirebaseEncoder().encode(user)
        return userRef(userId: user.uid).rx.setValue(data)
    }
    
    static func saveGroupsArePublic(userId: String, value: Bool) -> Single<DatabaseReference> {
        return groupsArePublicRef(userId: userId).rx.setValue(value)
    }
    
    static func savePlacesArePublic(userId: String, value: Bool) -> Single<DatabaseReference> {
        return placesArePublicRef(userId: userId).rx.setValue(value)
    }

    static func savePushNotificationsEnabled(userId: String, value: Bool) -> Single<DatabaseReference> {
        return notificationsRef(userId: userId).rx.setValue(value)
    }
    
    static func saveUnit(userId: String, value: OrbisUnit) -> Single<DatabaseReference> {
        return unitRef(userId: userId).rx.setValue(value.rawValue)
    }
    
    static func saveFcmToken(userId: String, token: String?) -> Completable {
        return load(userId: userId)
            .flatMapCompletable { user in
                if let u = user {
                    return fcmTokenRef(userId: u.uid).rx.setValue(token)
                        .asCompletable()
                }
                else {
                    return Completable.never()
                }
            }
    }
    
    static func changeSubscriptionToItemsBeingFollowed(userId: String?, subscribe: Bool) -> Completable {
        guard let userId = userId else {
            return Completable.never()
        }
        
        var topics = [String]()

        return RoleDAO.getRolesOfUserInGroups(userId: userId, requiredRole: Roles.follower)
            .flatMap { (roles: [String : [Roles]]) -> Single<[String : [Roles]]> in
                let keys = Array(roles.keys)
                topics += keys
                return RoleDAO.rolesOfUserInPlaces(userId: userId, requiredRole: Roles.follower)
            }
            .flatMapCompletable { (roles: [String : [Roles]]) -> Completable in
                let keys = Array(roles.keys)
                topics += keys
                
                for topic in topics {
                    if subscribe {
                        NotificationUtils.subscribeTo(topic: topic)
                    }
                    else {
                        NotificationUtils.unsubscribeFrom(topic: topic)
                    }
                }
                
                return Completable.empty()
            }
    }
    
    /*
        When active group changes, we execute a checkout.
     */
    static func checkOut(userId: String) -> Single<HandlePresenceEventResponse?> {
        return loadCheckIn(userId: userId)
            .flatMap { (checkIn : PresenceEvent?) -> Single<HandlePresenceEventResponse?> in
                guard let ci = checkIn, ci.valid else {
                    return Single.just(nil)
                }
                
                return CloudFunctionsDAO.handlePresenceEvent(
                    placeKey: ci.placeKey,
                    groupKey: ci.groupKey,
                    userKey: ci.userKey,
                    eventType: .checkOut)
            }
    }
    
    static func userChildEventsObservable(user: OrbisUser) -> Observable<OrbisUser?> {
        return userRef(userId: user.uid).rx
            .observeEvent(.value)
            .flatMap { (snapshot: DataSnapshot) -> Observable<OrbisUser?> in
                return Observable.just(snapshot.valueToType(type: OrbisUser.self))
            }
    }
    
    static func loadUsersOfGroup(groupKey: String) -> Single<([String : OrbisUser], [String : [Roles]])> {
        var outerRoles: [String : [Roles]]? = nil
        return RoleDAO.allRolesInGroup(groupKey: groupKey)
            .flatMap { (roles : [String : [Roles]]) -> Single<[String : OrbisUser]> in
                outerRoles = roles
                let userKeys = Array(roles.keys)
                return loadUsersByIds(userIds: userKeys)
            }
            .map { users in
                return (users, outerRoles!)
            }
    }

    static func loadAdminsOfGroup(groupKey: String?) -> Single<[OrbisUser]> {
        guard let groupKey = groupKey else {
            return Single.just([OrbisUser]())
        }
        
        return loadUsersOfGroup(groupKey: groupKey)
            .map { data in
                let users = Array(data.0.values)
                let roles = data.1
                
                return users.filter { user in
                    return roles[user.uid]?.contains(Roles.administrator) ?? false
                }
            }
    }
    
}
