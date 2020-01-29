//
//  BannedUsersDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/05/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import Firebase
import RxSwift
import RxFirebaseDatabase
import CodableFirebase
import FirebaseDatabase

/*
    Example: bannedUsers / user-id-that-banned / user-id-that-was-banned
 */
class BannedUsersDAO {
    
    private static let reference = database().reference(withPath: "bannedUsers")
    
    private static func ref(userId: String) -> DatabaseReference {
        return reference.child(userId)
    }
    
    private static func ref(userId: String, userId2: String) -> DatabaseReference {
        return ref(userId: userId).child(userId2)
    }

    static func save(userId: String, userId2: String, blocked: Bool) -> Single<DatabaseReference> {
        if blocked {
            return ref(userId: userId, userId2: userId2).rx
                .setValue(true)
        }
        else {
            return ref(userId: userId, userId2: userId2).rx
                .setValue(nil)
        }
    }
    
    static func load(userId: String) -> Single<Set<String>> {
        return ref(userId: userId).rx
            .observeSingleEvent(.value)
            .map { snapshot -> Set<String> in
                var bannedUsers = Set<String>()
                for case let snapshot2 as DataSnapshot in snapshot.children {
                    bannedUsers.insert(snapshot2.key)
                }
                return bannedUsers
            }
    }
    
}
