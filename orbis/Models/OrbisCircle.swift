//
//  OrbisCircle.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 02/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class OrbisCircle {
    let place: Place
    var currentSize: Float
    var finalSize: Float
    var dominantGroup: Group
    let touchesList: [TouchesCount]?

    init(place: Place, currentSize: Float, finalSize: Float, dominantGroup: Group, touchesList: [TouchesCount]?) {
        self.place = place
        self.currentSize = currentSize
        self.finalSize = finalSize
        self.dominantGroup = dominantGroup
        self.touchesList = touchesList
    }

    func touchesCount() -> Int {
        guard let list = touchesList else {
            return 0
        }
    
        return list.reduce(0, { currentValue, touches in
            if touches.valid {
                return currentValue + touches.count
            }
            else {
                return currentValue
            }
        })
    }
    
    func toPlaceWrapper() -> PlaceWrapper {
        return PlaceWrapper(place: place, group: dominantGroup)
    }
    
    func debug() {
        print2("Circle: \(place.name ?? "") \(place.key ?? "") currentSize: \(currentSize) finalSize: \(finalSize) touchesCount: \(touchesCount())")
    }
}
