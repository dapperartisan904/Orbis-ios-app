//
//  UIViewExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
    
    func anchorToSuperview() {
        guard let sp = superview else {
            return
        }
        anchorToView(view: sp, makeChild: false)
    }
    
    func anchorToView(view: UIView, makeChild: Bool, constant: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        
        if makeChild && superview == nil {
            view.addSubview(self)
        }
        
        topAnchor.constraint(equalTo: view.topAnchor, constant: constant).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -constant).isActive = true
        leftAnchor.constraint(equalTo: view.leftAnchor, constant: constant).isActive = true
        rightAnchor.constraint(equalTo: view.rightAnchor, constant: -constant).isActive = true
    }

    func findConstraint(layoutAttribute: NSLayoutConstraint.Attribute, relatedTo view: UIView? = nil) -> NSLayoutConstraint? {
        let constraints: [NSLayoutConstraint]?
        
        switch layoutAttribute {
        case .height, .width:
            constraints = self.constraints
        default:
            constraints = superview?.constraints
        }
        
        guard let cs = constraints else {
            return nil
        }
        
        for constraint in cs where itemMatch(constraint: constraint, layoutAttribute: layoutAttribute, relatedTo: view) {
            return constraint
        }

        return nil
    }
    
    private func itemMatch(constraint: NSLayoutConstraint, layoutAttribute: NSLayoutConstraint.Attribute, relatedTo view: UIView? = nil) -> Bool {
        switch layoutAttribute {
        case .width, .height:
            if let firstItem = constraint.firstItem as? UIView, firstItem == self, constraint.firstAttribute == layoutAttribute {
                return true
            }
        
        default:
            guard
                let firstItem = constraint.firstItem as? UIView,
                let secondItem = constraint.secondItem as? UIView
            else {
                return false
            }

            var firstItemMatch = firstItem == self && constraint.firstAttribute == layoutAttribute
            var secondItemMatch = secondItem == self && constraint.secondAttribute == layoutAttribute
            
            if let v = view {
                firstItemMatch = firstItemMatch && secondItem == v
                secondItemMatch = secondItemMatch && firstItem == v
            }
            
            return firstItemMatch || secondItemMatch
        }
        
        return false
    }
    
}
