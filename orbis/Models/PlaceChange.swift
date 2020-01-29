//
//  PlaceChange.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 02/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class PlaceChange : Codable {
    
    var dominantGroupKey: String?
    var prevSize: Float? = 0
    var currentSize: Float = 0
    var serverTimestamp: Int64 = -1
    
    // Transient - present only on iOS
    var placeKey: String?
    
    // Transient
    var shouldSpin: Bool?
    
    func debug() -> String {
        return "placeKey: \(String(describing: placeKey)) " +
        "dominantGroupKey: \(String(describing: dominantGroupKey)) " +
        "prevSize: \(String(describing: prevSize))  " +
        "currentSize: \(currentSize)  " +
        "serverTimestamp: \(serverTimestamp) " +
        "shouldSpin: \(String(describing: shouldSpin))"
    }
    
}
