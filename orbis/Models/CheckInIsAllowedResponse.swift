//
//  CheckInIsAllowedResponse.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 28/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class CheckInIsAllowedResponse : Decodable {
    
    var success: Bool?
    var error: String?

}
