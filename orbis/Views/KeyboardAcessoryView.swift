//
//  KeyboardAcessoryView.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 08/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

enum KeyboardToolbarButton: Int {
    
    case done = 0
    case cancel
    case back, backDisabled
    case forward, forwardDisabled
    
    func createButton(target: Any?, action: Selector?) -> UIBarButtonItem {
        var button: UIBarButtonItem!
        
        switch self {
        case .back:
            button = UIBarButtonItem(title: "back", style: .plain, target: target, action: action)
        case .backDisabled:
            button = UIBarButtonItem(title: "back", style: .plain, target: target, action: action)
            button.isEnabled = false
        case .forward:
            button = UIBarButtonItem(title: "forward", style: .plain, target: target, action: action)
        case .forwardDisabled:
            button = UIBarButtonItem(title: "forward", style: .plain, target: target, action: action)
            button.isEnabled = false
        case .done:
            button = UIBarButtonItem(title: Words.done.localized, style: .plain, target: target, action: action)
        case .cancel:
            button = UIBarButtonItem(title: "cancel", style: .plain, target: target, action: action)
        }
        
        button.tag = rawValue
        return button
    }
    
    static func detectType(barButton: UIBarButtonItem) -> KeyboardToolbarButton? {
        return KeyboardToolbarButton(rawValue: barButton.tag)
    }
}

protocol KeyboardToolbarDelegate: class {
    func keyboardToolbar(button: UIBarButtonItem, type: KeyboardToolbarButton, tappedIn toolbar: KeyboardToolbar)
}

class KeyboardToolbar: UIToolbar {
    
    weak var toolBarDelegate: KeyboardToolbarDelegate?
    
    init() {
        super.init(frame: .zero)
        barStyle = UIBarStyle.default
        isTranslucent = true
        sizeToFit()
        isUserInteractionEnabled = true
    }
    
    func setup(leftButtons: [KeyboardToolbarButton], rightButtons: [KeyboardToolbarButton]) {
        let leftBarButtons = leftButtons.map { (item) -> UIBarButtonItem in
            return item.createButton(target: self, action: #selector(buttonTapped))
        }
        
        let rightBarButtons = rightButtons.map { (item) -> UIBarButtonItem in
            return item.createButton(target: self, action: #selector(buttonTapped(sender:)))
        }
        
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        setItems(leftBarButtons + [spaceButton] + rightBarButtons, animated: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func buttonTapped(sender: UIBarButtonItem) {
        if let type = KeyboardToolbarButton.detectType(barButton: sender) {
            toolBarDelegate?.keyboardToolbar(button: sender, type: type, tappedIn: self)
        }
    }
    
}
