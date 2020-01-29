//
//  Group.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 18/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation

class Group : Codable, Equatable {
    static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.key == rhs.key
    }
    
    var name: String!
    var description: String!
    var solidColorHex: String!
    var strokeColorHex: String!
    var imageName: String!
    var location: Coordinates!
    var geohash: String!
    var timestamp: Int64 = 0
    var os: String?

    var key: String?
    var colorIndex: Int?
    var deleted = false

    func textShouldBeDark() -> Bool {
        return colorIndex == 2 || colorIndex == 9
    }
}
