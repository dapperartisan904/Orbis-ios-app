//
//  UIPageViewControllerExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

extension UIPageViewController {
    
    func disableSwipe(){
        for view in view.subviews {
            if let subView = view as? UIScrollView {
                subView.isScrollEnabled = false
            }
        }
    }
    
}
