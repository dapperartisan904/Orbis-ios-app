//
//  UIButtonExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 27/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    
    func makeFontSizeAdjustable() {
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.5
    }
 
    func setTitleUppercased(_ title: String?, for state: UIControl.State) {
        setTitle(title?.uppercased(), for: state)
    }
}
