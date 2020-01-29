//
//  OrbisGPSLocation.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 27/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class OrbisGPSLocation {
    
    private static var shared: OrbisGPSLocation = {
        return OrbisGPSLocation()
    }()
    
    static func instance() -> OrbisGPSLocation {
        return OrbisGPSLocation.shared
    }
    
    var coordinates: Coordinates? {
        didSet {
            name = coordinates?.toDegreesString()
        }
    }
    
    var name: String?
    var prevStatus: TemporaryPlaceStatus?
    
    var status: TemporaryPlaceStatus = .notCreated {
        willSet {
            prevStatus = status
        }
    }
    
    /*
        Multiple checkins at temporary places within 24h are not allowed unless distance btw places are > 1000m
     */
    
}
