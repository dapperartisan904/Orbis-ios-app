//
//  PresenceEvent.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 18/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation

class PresenceEvent : Codable {
    
    var key: String!
    var placeKey: String!
    var userKey: String!
    var groupKey: String?
    var duplicated = false
    
    /*
        For now unique possible event here is CHECK_IN.
        CHECK_OUT will not be saved here
     */
    var eventType: String!
    
    /*
        A check-in will mark valid = true
        A check-in followed by a check-out will mark valid = false
     */
    var valid: Bool = false
    
    /*
        Time where the event becomes invalid
        Needs to be filled manually with estimated server time
        Different from Android
     */
    var validTimestamp: Int64?
    
    /*
        Time where the event becomes invalid
        Needs to be filled manually with estimated server time
        Different from Android
     */
    var invalidTimestamp: Int64?
    
}
