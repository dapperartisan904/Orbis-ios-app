//
//  UserWrapper.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 26/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class UserWrapper {
    
    var user: OrbisUser
    var group: Group?
    
    init(user: OrbisUser, group: Group?) {
        self.user = user
        self.group = group
    }
}
