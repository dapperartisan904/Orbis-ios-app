//
//  CALayerExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 22/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

extension CALayer {
    func addBorder(color: UIColor = UIColor.black, edge: UIRectEdge, thickness: CGFloat) {
        
        let border = CALayer()
        
        switch edge {
        case UIRectEdge.top:
            border.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: thickness)
            
        case UIRectEdge.bottom:
            border.frame = CGRect(x: 0, y: self.bounds.height - thickness,  width: UIScreen.main.bounds.width, height: thickness)
            
        case UIRectEdge.left:
            border.frame = CGRect(x: 0, y: 0,  width: thickness, height: self.bounds.height)
            
        case UIRectEdge.right:
            border.frame = CGRect(x: self.bounds.width - thickness, y: 0,  width: thickness, height: self.bounds.height)
            
        default:
            break
        }
        
        border.backgroundColor = color.cgColor
        self.addSublayer(border)
    }
}
