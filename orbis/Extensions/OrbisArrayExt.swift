//
//  OrbisArrayExt.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 24/04/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

extension Array {
    public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key:Element] {
        var dict = [Key:Element]()
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }
}
