//
//  TutorialOvalView.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 24/05/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class TutorialOvalView : UIView {
    
    override func draw(_ rect: CGRect) {
        let desiredLineWidth:CGFloat = 4
        let hw:CGFloat = desiredLineWidth/2
        let circlePath = UIBezierPath(ovalIn: rect.insetBy(dx: hw, dy: hw))
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.strokeColor = UIColor.darkGray.cgColor
        shapeLayer.lineWidth = desiredLineWidth
        layer.addSublayer(shapeLayer)
    }
    
}
