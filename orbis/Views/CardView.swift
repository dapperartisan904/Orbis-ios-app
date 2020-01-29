//
//  CardView.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 07/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class CardView: UIView {
    
    @IBInspectable var cardCornerRadius: CGFloat = 2
    @IBInspectable var cardBorderColor: UIColor? = UIColor.gray
    @IBInspectable var drawShadrow = false
    @IBInspectable var cardShadowOffsetWidth: Int = 0
    @IBInspectable var cardShadowOffsetHeight: Int = 0
    @IBInspectable var cardShadowColor: UIColor? = nil
    @IBInspectable var cardShadowOpacity: Float = 0.5
    
    @IBInspectable var isTopCard: Bool = false {
        didSet {
            findConstraint(layoutAttribute: .height)?.constant = 220
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    private func initialSetup() {

    }
    
    override func layoutSubviews() {
        layer.cornerRadius = cardCornerRadius
        layer.borderColor = cardBorderColor?.cgColor
        layer.borderWidth = 1.0
        
        if (drawShadrow) {
            let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cardCornerRadius)
            layer.masksToBounds = false
            layer.shadowColor = cardShadowColor?.cgColor
            layer.shadowOffset = CGSize(width: cardShadowOffsetWidth, height: cardShadowOffsetHeight)
            layer.shadowOpacity = cardShadowOpacity
            layer.shadowPath = shadowPath.cgPath
        }
    }

}
