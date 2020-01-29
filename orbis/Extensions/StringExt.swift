//
//  StringExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit

extension String {
    
    /*
        Overrides SwifterSwift extension
        See HomeViewController.testLocalization()
     */
    public func localized(comment: String = "") -> String {
        let udr = UserDefaultsRepository.instance()
        
        if let bundle = udr.languageBundle {
            var defaultValue = ""
            
            if udr.language != .english {
                if let bundle2 = udr.defaultLanguageBundle {
                    defaultValue = NSLocalizedString(self, tableName: nil, bundle: bundle2, value: defaultValue, comment: "")
                }
            }
            
            return NSLocalizedString(self, tableName: nil, bundle: bundle, value: defaultValue, comment: "")
        }
        
        return NSLocalizedString(self, comment: comment)
    }
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.width)
    }
    
    init(value: Double, decimalPlaces: Int) {
        let decimalFraction = value.truncatingRemainder(dividingBy: 1)
        if decimalFraction == 0.0 {
            self.init(value.int.string)
        }
        else {
            self.init(format: "%.\(decimalPlaces)f", value)
        }
    }
}


extension NSAttributedString {
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        return ceil(boundingBox.width)
    }
}
