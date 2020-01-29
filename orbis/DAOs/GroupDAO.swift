//
//  GroupDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 19/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import Firebase
import RxSwift
import RxFirebaseDatabase
import CodableFirebase
import FirebaseDatabase

class GroupDAO {

    private static let reference = database().reference(withPath: "groups")

    static func findByKey(groupKey: String?) -> Single<Group?> {
        guard let groupKey = groupKey, !groupKey.isEmpty else {
            return Single.just(nil)
        }
        
        return reference.child(groupKey).rx
            .observeSingleEvent(.value)
            .map({ (snapshot: DataSnapshot) -> Group? in
                return snapshot.valueToType(type: Group.self)
            })
    }
    
    static func newKey() -> String? {
        return reference.childByAutoId().key
    }
    
    static func saveGroup(group: Group) -> Single<Bool> {
        let data = try! FirebaseEncoder().encode(group)
        return reference.child(group.key!).rx
            .setValue(data)
            .flatMap { _ in return Single.just(true) }
    }
    
    static func createGroup(group: Group) -> Single<Bool> {
        let data = try! FirebaseEncoder().encode(group)
        return reference.child(group.key!).rx
            .setValue(data)
            .flatMap { databaseReference in
                GeoFireDAO.saveGroupLocation(group: group)
            }
    }
    
    static func loadGroups(groupKeys: [String]) -> Single<[Group?]> {
        return Observable.from(groupKeys)
            .flatMap { groupKey in return GroupDAO.findByKey(groupKey: groupKey) }
            .toArray()
    }
    
    static func loadGrousAsDictionary(groupKeys: [String]) -> Single<[String : Group]> {
        return Observable
            .from(groupKeys)
            .flatMap { (groupKey : String) -> Single<Group?> in
                return findByKey(groupKey: groupKey)
            }
            .toArray()
            .map { (groups : [Group?]) -> [String : Group] in
                let filteredGroups = groups.filter { group in return group != nil }
                var result = [String : Group]()
                filteredGroups.forEach { group in result[group!.key!] = group! }
                return result
            }
    }
    
    static func loadGroupsOfUser(userId: String, requiredRole: Roles?) -> Single<[Group]> {
        return RoleDAO.getRolesOfUserInGroups(userId: userId, requiredRole: requiredRole)
            .flatMap { (roles : [String : [Roles]]) -> Single<[Group?]> in
                return loadGroups(groupKeys: Array(roles.keys))
            }
            .map { (groups: [Group?]) -> [Group] in
                groups.filtered(
                    { (optGroup: Group?) -> Bool in
                        return optGroup != nil
                    }, map: { (group: Group?) -> Group in
                        return group!
                    })
            }
    }
    
    static func loadGroupsWithTerm(term: String) -> Single<[Group]> {
        return loadAllGroups().flatMap({ (groups: [Group]) -> Single<[Group]> in
            return Single.just(groups.filter({ (group: Group) -> Bool in
                return group.name.contains(term, caseSensitive: false)
            }))
        })
    }
    
    private static func loadAllGroups() -> Single<[Group]> {
        return reference.queryOrdered(byChild: "name").rx.observeSingleEvent(.value)
            .flatMap { (snapshot : DataSnapshot) -> Single<[Group]> in
                var groups = [Group]()
                for case let snapshot2 as DataSnapshot in snapshot.children {
                    if let group = snapshot2.valueToType(type: Group.self) {
                        groups.append(group)
                    }
                }
                return Single.just(groups)
            }
    }
    
}
