//
//  CollectionExt.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 24/06/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

extension Collection {
    
    func safeGet(index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
}
