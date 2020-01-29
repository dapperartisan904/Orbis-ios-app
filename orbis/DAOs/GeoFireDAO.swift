//
//  GeoFireDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 20/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import GeoFire
import FirebaseDatabase
import RxSwift

class GeoFireDAO {
    
    static let groupsGeoFire = GeoFire(firebaseRef: database().reference(withPath: "groupsLocation"))
    static let mapGeoFire = GeoFire(firebaseRef: database().reference(withPath: "mapLocations"))
    static let nearbySearchesGeoFire = GeoFire(firebaseRef: database().reference(withPath: "nearbySearchesLocation"))
    static let placesGeoFire = GeoFire(firebaseRef: database().reference(withPath: "placesLocation"))
    static let postsGeoFire = GeoFire(firebaseRef: database().reference(withPath: "postsLocation"))
    
    static func saveGroupLocation(group: Group) -> Single<Bool> {
        return groupsGeoFire.setLocationCompletable(key: group.key!, location: group.location)
    }

    static func savePlaceLocation(place: Place) -> Single<Bool> {
        return placesGeoFire.setLocationCompletable(key: place.key, location: place.coordinates)
    }
    
    static func savePostLocation(post: OrbisPost) -> Single<Bool> {
        return postsGeoFire.setLocationCompletable(key: post.postKey, location: post.coordinates!)
    }
    
    static func deletePostLocation(post: OrbisPost) -> Single<Bool> {
        return postsGeoFire.removeLocationCompletable(key: post.postKey)
    }
    
    static func saveNearbySearchLocation(query: GFCircleQuery) -> Single<Bool> {
        guard let key = nearbySearchesGeoFire.firebaseRef.childByAutoId().key else {
            return Single.just(false)
        }
        
        return nearbySearchesGeoFire
            .setLocationCompletable(key: key, location: Coordinates.init(clLocation: query.center))
    }

    static func searchExists(query: GFCircleQuery) -> Single<Bool> {
        return searchExists(location: query.center)
    }
    
    static func searchExists(location: CLLocation) -> Single<Bool> {
        return Single.create { single in
            let query = GeoFireDAO.nearbySearchesGeoFire.query(at: location, withRadius: 0.5)
            var exists = false
            
            query.observe(.keyEntered) { (key: String, location: CLLocation) in
                exists = true
            }
            
            query.observeReady {
                query.removeAllObservers()
                single(.success(exists))
            }
            
            return Disposables.create {
                query.removeAllObservers()
            }
        }
    }
    
    static func allPlaceLocations() -> Single<[String]> {
        return placesGeoFire.firebaseRef.rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> [String] in
                var keys = [String]()
                for case let snapshot2 as DataSnapshot in snapshot.children {
                    keys.append(snapshot2.key)
                }
                return keys
            }
    }
}
