//
//  OrbisTextFields.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class FormTextField : UIView {
    
    private(set) var textField: UITextField!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    
        backgroundColor = UIColor.clear
        
        textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textAlignment = .center
        textField.borderStyle = UITextField.BorderStyle.none
        textField.backgroundColor = UIColor.clear
        textField.textColor = UIColor.black
                
        addSubview(textField)
        textField.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        textField.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        textField.topAnchor.constraint(equalTo: topAnchor).isActive = true
        textField.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = UIColor.black
        
        addSubview(lineView)
        lineView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        lineView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        lineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
    }
    
    func setText(text: String?, placeholder: String?) {
        textField.text = text
        
        if let placeholder = placeholder {
            textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
        }
        else {
            textField.attributedPlaceholder = nil
        }
    }
    
    func getText() -> String? {
        return textField.text
    }
    
    func asEmail() {
        textField.keyboardType = UIKeyboardType.emailAddress
        textField.autocapitalizationType = UITextAutocapitalizationType.none
    }
    
    func asPwd() {
        textField.autocapitalizationType = UITextAutocapitalizationType.none
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.isSecureTextEntry = true
    }
    
}
