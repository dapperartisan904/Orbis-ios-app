//
//  OtherViewsExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 05/02/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

extension UIStackView {
    
    func tabsStackView() {
        findConstraint(layoutAttribute: .height)?.constant = 40
    }
    
}
