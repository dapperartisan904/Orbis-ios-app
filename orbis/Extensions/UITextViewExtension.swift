//
//  UITextViewExtension.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 29/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

extension UITextView {
    
    var isBlank: Bool {
        return text == nil || text.isEmpty || text.isWhitespace
    }
    
}
