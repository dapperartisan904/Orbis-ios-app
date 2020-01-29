//
//  OrbisLabels.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 22/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class SectionLabel : UILabel {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.addBorder(edge: UIRectEdge.bottom, thickness: 1.0)
    }
    
}
