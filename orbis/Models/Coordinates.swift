//
//  Coordinates.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 18/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import CoreLocation

class Coordinates : Codable {
    var latitude: Double!
    var longitude: Double!
    
    init() { }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(clLocation: CLLocation) {
        latitude = clLocation.coordinate.latitude
        longitude = clLocation.coordinate.longitude
    }
    
    init(coordinate2D: CLLocationCoordinate2D) {
        latitude = coordinate2D.latitude
        longitude = coordinate2D.longitude
    }
    
    func toCLLocation() -> CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func distanceInMeters(toOther other: Coordinates) -> Double {
        return toCLLocation().distance(from: other.toCLLocation())
    }
    
    func debugStr() -> String {
        return "latitude: \(String(describing: latitude)) longitude: \(String(describing: longitude))"
    }
    
    func toDegreesString() -> String {
        var str = String(value: latitude, decimalPlaces: 2)
        str += "°"
        str += latitude < 0 ? "S" : "N"
        str += " / "
        str += String(value: longitude, decimalPlaces: 2)
        str += longitude < 0 ? "W" : "E"
        return str
    }
}
