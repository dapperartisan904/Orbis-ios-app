
//
//  NSLayoutConstraintExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit


extension NSLayoutConstraint {
    
    func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {
        
        isActive = false
        
        let newConstraint = NSLayoutConstraint(
            item: firstItem as Any,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        
        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier
        newConstraint.isActive = true
        
        return newConstraint
    }
    
}
