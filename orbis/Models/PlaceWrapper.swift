//
//  PlaceWrapper.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation

class PlaceWrapper : Equatable {
    static func == (lhs: PlaceWrapper, rhs: PlaceWrapper) -> Bool {
        return lhs.place.key == rhs.place.key
    }
        
    var place: Place
    var group: Group?
    
    init(place: Place, group: Group?) {
        self.place = place
        self.group = group
    }

}
