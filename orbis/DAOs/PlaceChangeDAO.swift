//
//  PlaceChangeDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 02/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import Firebase
import RxSwift
import RxFirebaseDatabase
import FirebaseDatabase

class PlaceChangeDAO {
    
    private static let reference = database().reference(withPath: "placeChanges")
 
    static func placeRef(placeKey: String) -> DatabaseReference {
        return PlaceChangeDAO.reference.child(placeKey)
    }

    // If snapshot does not exist, will return nil
    static func loadPlaceChange(placeKey: String) -> Single<PlaceChange?> {
        return PlaceChangeDAO.placeRef(placeKey: placeKey).rx
            .observeSingleEvent(.value)
            .map { snapshot in
                return snapshot.valueToType(type: PlaceChange.self)
            }
    }
    
    static func observePlaceChanges(fromTimestamp timestamp: Int64, eventType: DataEventType) -> Observable<PlaceChange?> {
        return reference
            .queryOrdered(byChild: "serverTimestamp")
            .queryStarting(atValue: timestamp).rx
            .observeEvent(eventType)
            .map { (snapshot : DataSnapshot) -> PlaceChange? in
                //print2("[MapDebug] observePlaceChanges [\(eventType.rawValue)]")
                let change = snapshot.valueToType(type: PlaceChange.self)
                change?.placeKey = snapshot.key
                return change
            }
    }
    
    static func loadMaxTimestamp() -> Single<Int64> {
        return reference
            .queryOrdered(byChild: "serverTimestamp")
            .queryLimited(toLast: 1).rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> Int64 in
                if !snapshot.exists() || snapshot.childrenCount == 0 {
                    return 0
                }
                
                guard let lastChange = snapshot.firstChild(type: PlaceChange.self) else {
                    return 0
                }
            
                return lastChange.serverTimestamp
            }
    }
    
}
