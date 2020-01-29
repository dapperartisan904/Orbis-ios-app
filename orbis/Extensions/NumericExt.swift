//
//  NumericExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 02/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

extension Int {
    
    func toIndexPath(section: Int = 0) -> IndexPath {
        return IndexPath(row: self, section: section)
    }
    
}

extension Int64 {
    
    func makeCompatibleWithAndroid() -> Int64 {
        return (self + 1) * 1000
    }
    
}

extension Double {
    
    func makeCompatibleWithAndroid() -> Int64 {
        return Int64(self).makeCompatibleWithAndroid()
    }

}
