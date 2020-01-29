//
//  PlaceDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import FirebaseDatabase
import RxSwift
import RxFirebaseDatabase
import CodableFirebase

class PlaceDAO {
    
    private static var reference = database().reference(withPath: "places")

    private static func placeRef(placeKey: String) -> DatabaseReference {
        return reference.child(placeKey)
    }
    
    static func newKey() -> String? {
        return reference.childByAutoId().key
    }
    
    static func allPlaces() -> Single<[String : Place?]> {
        return reference.rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> [String : Place?] in
                var places = [String : Place?]()
                
                for case let snapshot2 as DataSnapshot in snapshot.children {
                    let place = snapshot2.valueToType(type: Place.self)
                    places[snapshot2.key] = place
                }
            
                return places
            }
    }
    
    static func load(placeKey: String?) -> Single<Place?> {
        guard let placeKey = placeKey else {
            return Single.just(nil)
        }
        
        return placeRef(placeKey: placeKey).rx
            .observeSingleEvent(.value)
            .map { (snapshot: DataSnapshot) -> Place? in
                let place = snapshot.valueToType(type: Place.self)
                //print2("[Places] try to load [1.5] placeKey: \(placeKey) \(String(describing: place?.key))")
                return place
            }
    }
    
    static func loadPlaceByKeys(placeKeys: [String]) -> Single<[String : Place]> {
        return Observable
            .from(placeKeys)
            .flatMap { (placeKey : String) -> Single<Place?> in
                return load(placeKey: placeKey)
            }
            .toArray()
            .map { (places : [Place?]) -> [String : Place] in
                let filteredPlaces = places.filter { place in return place != nil }
                var result = [String : Place]()
                filteredPlaces.forEach { place in result[place!.key] = place! }
                return result
            }
    }
    
    static func loadPlacesDominated(by group: Group, myLocation: Coordinates?) -> Single<[Place]> {
        return reference
            .queryOrdered(byChild: "dominantGroupKey")
            .queryEqual(toValue: group.key!).rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> [Place] in
                var places = [Place]()
                
                for case let snapshot2 as DataSnapshot in snapshot.children {
                    if let place = snapshot2.valueToType(type: Place.self) {
                        places.append(place)
                    }
                }
                
                if let myLocation = myLocation {
                    places.sort(by: { p0, p1 in
                        return p0.coordinates.distanceInMeters(toOther: myLocation) < p1.coordinates.distanceInMeters(toOther: myLocation)
                    })
                }
                
                return places
            }
    }
 
    static func loadPlaces(followedBy userId: String) -> Single<[String : Place]> {
        return RoleDAO.rolesOfUserInPlaces(userId: userId, requiredRole: Roles.follower)
            .flatMap { (roles : [String : [Roles]]) -> Single<[String : Place]> in
                let keys = Array(roles.keys)
                return loadPlaceByKeys(placeKeys: keys)
            }
    }
    
    static func loadPlaces(term: String) -> Single<[Place]> {
        return reference
            .queryOrdered(byChild: "lowercaseName")
            .queryStarting(atValue: term)
            .queryEnding(atValue: term + "z").rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> [Place] in
                var places = [Place]()
                
                for case let snapshot2 as DataSnapshot in snapshot.children {
                    if let place = snapshot2.valueToType(type: Place.self) {
                        places.append(place)
                    }
                }
                
                return places
            }
    }
    
    static func createPlace(place: Place) -> Single<HandlePresenceEventResponse?> {
        let data = try! FirebaseEncoder().encode(place)
        return GeoFireDAO.savePlaceLocation(place: place).asObservable().asSingle()
            .flatMap { (result : Bool) -> Single<DatabaseReference> in
                if result {
                    return PlaceDAO.placeRef(placeKey: place.key).rx.setValue(data)
                }
                else {
                    return Single.never()
                }
            }
            .flatMap { (result : DatabaseReference) -> Single<Bool> in
                return RoleDAO.saveRoleInPlace(userId: place.userCreatedKey!, placeId: place.key!, role: Roles.follower, add: true)
            }
            .flatMap { (result : Bool) -> Single<HandlePresenceEventResponse?> in
                if let groupKey = place.groupCreatedKey {
                    return CloudFunctionsDAO.handlePresenceEvent(
                        placeKey: place.key,
                        groupKey: groupKey,
                        userKey: place.userCreatedKey,
                        eventType: PresenceEventType.checkIn)
                    .asObservable()
                    .asSingle()
                }
                else {
                    return Single.just(nil)
                }
            }
            .map { (checkInResponse : HandlePresenceEventResponse?) -> HandlePresenceEventResponse? in
                var response = checkInResponse
                place.dominantGroupKey = place.groupCreatedKey
                response?.place = place
                return response
            }
    }

    static func savePlace(data: NearbySearchItem) -> Completable {
        guard let place = Place.build(item: data) else {
            return Completable.empty()
        }
    
        return reference.queryOrdered(byChild: "googlePlaceId")
            .queryEqual(toValue: place.googlePlaceId!)
            .queryLimited(toFirst: 1).rx
            .observeSingleEvent(.value)
            .flatMapCompletable { (snapshot : DataSnapshot) -> Completable in
                if snapshot.hasChildren() {
                    //let p = snapshot.firstChild(type: Place.self)
                    //print2("savePlace from nearbySearch: skip because place already exists Key: \(snapshot.key) Childreen count: \(snapshot.childrenCount) Place: \(String(describing: p?.key)) \(String(describing: p?.name))")
                    return Completable.empty()
                }
                
                let data = try! FirebaseEncoder().encode(place)
                print2("will save place \(String(describing: place.key)) \(String(describing: place.name))")
                
                return PlaceDAO.placeRef(placeKey: place.key).rx.setValue(data)
                    .asCompletable()
                    .andThen(
                        GeoFireDAO.savePlaceLocation(place: place).asCompletable()
                    )
            }
    }
    
    static func savePlaceDescription(placeKey: String, description: String?) -> Single<DatabaseReference> {
        return placeRef(placeKey: placeKey).child("description").rx
            .setValue(description)
    }
    
    static func savePlaceName(place: Place, name: String) -> Single<Bool> {
        let temporary = place.temporary
        let stepTwo: Single<Bool>
        let placeReference = placeRef(placeKey: place.key)
        
        if temporary {
            stepTwo = placeReference.child("temporary").rx.setValue(false)
                .flatMap { _ in
                    placeReference.child("wasTemporary").rx.setValue(true)
                }
                .map { _ in return true }
        }
        else {
            stepTwo = Single.just(true)
        }
    
        return placeReference.child("name").rx.setValue(name)
            .flatMap { _ in
                return stepTwo
            }
            .do(onSuccess: { _ in
                print2("savePlaceName doOnSuccess temporary: \(temporary)")
                if (temporary) {
                    place.temporary = false
                    place.wasTemporary = true
                }
            })
    }
}
