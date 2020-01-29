//
//  PresenceEventDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 29/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import RxFirebaseDatabase
import FirebaseDatabase
import CodableFirebase

class PresenceEventDAO {
    
    private static let presenceEventsByGroupReference = database().reference(withPath: "presenceEventsByGroup")
    private static let presenceEventsByPlaceReference = database().reference(withPath: "presenceEventsByPlace")
    private static let presenceEventsByUserReference = database().reference(withPath: "presenceEventsByUser")

    private static func peUserRef(userId: String) -> DatabaseReference {
        return presenceEventsByUserReference.child(userId)
    }
    
    private static func pePlaceRef(placeKey: String) -> DatabaseReference {
        return presenceEventsByPlaceReference.child(placeKey)
    }
    
    public static func loadPresenceEvents(userId: String) -> Single<[PresenceEvent]> {
        return peUserRef(userId: userId).rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> [PresenceEvent] in
                return toEvents(rootSnapshoot: snapshot)
            }
    }
    
    public static func loadPresenceEvents(placeKey: String) -> Single<[PresenceEvent]> {
        return pePlaceRef(placeKey: placeKey).rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> [PresenceEvent] in
                return toEvents(rootSnapshoot: snapshot)
        }
    }
    
    private static func toEvents(rootSnapshoot: DataSnapshot) -> [PresenceEvent] {
        var list = [PresenceEvent]()
        for case let snapshot2 as DataSnapshot in rootSnapshoot.children {
            if let ev = snapshot2.valueToType(type: PresenceEvent.self) {
                list.append(ev)
            }
            else {
                for case let snapshot3 as DataSnapshot in snapshot2.children {
                    if let ev = snapshot3.valueToType(type: PresenceEvent.self) {
                        list.append(ev)
                    }
                }
            }
        }
        return list
    }
    
}
