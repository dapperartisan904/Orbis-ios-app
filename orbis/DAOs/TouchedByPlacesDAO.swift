//
//  TouchedByPlacesDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 02/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import RxFirebaseDatabase
import RxSwift

class TouchedByPlacesDAO {
    
    private static let reference = database().reference(withPath: "touchedByPlaces")
 
    private static func placeRef(placeKey: String) -> DatabaseReference {
        return reference.child(placeKey)
    }
    
    /*
        Returns places touching given place
     */
    static func getTouchedByPlacesOfPlace(placeKey: String, onlyValid: Bool) -> Single<[TouchesCount]?> {
        return TouchedByPlacesDAO.placeRef(placeKey: placeKey).rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> [TouchesCount]? in
                var result = [TouchesCount]()
                
                for case let snapshot2 as DataSnapshot in snapshot.children {
                    if let item = snapshot2.valueToType(type: TouchesCount.self) {
                        result.append(item)
                    }
                }
                
                if onlyValid {
                    result = result.filter { $0.valid }
                }
                
                return result
            }
    }
}

