//
//  LineView.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 19/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit

class LineView : UIView {
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard let superview = superview else {
            return
        }
        
        leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
        heightAnchor.constraint(equalToConstant: 1.0).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor(rgba: "#A5A5A5")
    }
    
}
