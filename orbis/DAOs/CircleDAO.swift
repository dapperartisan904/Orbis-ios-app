//
//  CircleDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 02/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class CircleDAO {
    
    static func loadCircle(placeKey: String) -> Single<OrbisCircle> {
        var placeChangeTmp: PlaceChange?
        var placeTmp: Place?
        var groupTmp: Group?
        
        return PlaceChangeDAO.loadPlaceChange(placeKey: placeKey)
            .flatMap { (placeChange : PlaceChange?) -> Single<Place?> in
                guard let placeChange = placeChange else {
                    return Single.error(OrbisErrors.placeChangeNotExist)
                }
                placeChangeTmp = placeChange
                return PlaceDAO.load(placeKey: placeKey)
            }
            .flatMap { (place: Place?) -> Single<Group?> in
                guard let place = place else {
                    return Single.error(OrbisErrors.placeNotExist)
                }
                placeTmp = place
                return GroupDAO.findByKey(groupKey: place.dominantGroupKey)
            }
            .flatMap { (group: Group?) -> Single<[TouchesCount]?> in
                guard let group = group else {
                    print2("groupNotExist: \(placeTmp?.dominantGroupKey ?? "")")
                    return Single.error(OrbisErrors.groupNotExist)
                }
                groupTmp = group
                return TouchedByPlacesDAO.getTouchedByPlacesOfPlace(placeKey: placeKey, onlyValid: true)
            }
            .map { (touchesList: [TouchesCount]?) -> OrbisCircle in
                return OrbisCircle(
                    place: placeTmp!,
                    currentSize: placeChangeTmp!.currentSize,
                    finalSize: placeChangeTmp!.currentSize,
                    dominantGroup: groupTmp!,
                    touchesList: touchesList)
            }
    }
    
}
