//
//  PlaceWrapperDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import RxFirebaseDatabase

class PlaceWrapperDAO {
    
    static func load(placeKey: String?, excludeDeleted: Bool, throwErrorIfNotExists: Bool) -> Single<PlaceWrapper?> {
        guard let placeKey = placeKey else {
            print2("[Places] load error [0]")
            return Single.just(nil)
        }
    
        var loadedPlace: Place? = nil
        //print2("[Places] try to load \(placeKey)")
        
        return PlaceDAO
            .load(placeKey: placeKey)
            .flatMap { (place: Place?) -> Single<Group?> in
                //print2("[Places] try to load \(placeKey) [2]")
                
                guard let place = place else {
                    //print2("[Places] load error [1]")
                    if throwErrorIfNotExists {
                        return Single.error(OrbisErrors.placeNotExist)
                    }
                    else {
                        return Single.just(nil)
                    }
                }
                
                if place.deleted && excludeDeleted {
                    //print2("[Places] load error [2]")
                    if throwErrorIfNotExists {
                        return Single.error(OrbisErrors.placeNotExist)
                    }
                    else {
                        return Single.just(nil)
                    }
                }
                
                loadedPlace = place
                
                guard let groupId = place.dominantGroupKey else {
                    return Single.just(nil)
                }
            
                return GroupDAO.findByKey(groupKey: groupId)
            }
            .map { (group: Group?) -> PlaceWrapper? in
                if let p = loadedPlace {
                    return PlaceWrapper(place: p, group: group)
                }
                else {
                    return nil
                }
            }
    }
    
    static func load(placeKeys: [String], excludeDeleted: Bool = true) -> Single<[PlaceWrapper]> {
        //print2("[Places] to load: \(placeKeys.count)")

        return Observable.from(placeKeys)
            .flatMap { placeKey in
                return PlaceWrapperDAO.load(placeKey: placeKey, excludeDeleted: excludeDeleted, throwErrorIfNotExists: false)
            }
            .toArray()
            .flatMap { (wrappers: [PlaceWrapper?]) -> Single<[PlaceWrapper]> in
                var noOptionals = wrappers.filtered({ (placeWrapper: PlaceWrapper?) -> Bool in
                    return placeWrapper != nil
                }, map: { (placeWrapper: PlaceWrapper?) -> PlaceWrapper in
                    return placeWrapper!
                })

                noOptionals.sort(by: { w0, w1 in
                    let i0 = placeKeys.index(of: w0.place.key)!
                    let i1 = placeKeys.index(of: w1.place.key)!
                    return i0 < i1
                })
                
                //print2("[Places] With nils: \(wrappers.count) Without nils: \(noOptionals.count)")
                
                return Single.just(noOptionals)
            }
    }
    
    static func load(term: String) -> Single<[PlaceWrapper]> {
        var places = [Place]()
        
        return PlaceDAO.loadPlaces(term: term)
            .flatMap { (result : [Place]) -> Single<[String : Group]> in
                places = result
                
                let groupKeys = result.map { $0.dominantGroupKey }
                    .filter { $0 != nil }
                    .map { $0! }
                
                return GroupDAO.loadGrousAsDictionary(groupKeys: groupKeys)
            }
            .map { (groups : [String : Group]) -> [PlaceWrapper] in
                return places.map { p in return PlaceWrapper(place: p, group: groups[p.dominantGroupKey ?? ""]) }
            }
    }
    
}
