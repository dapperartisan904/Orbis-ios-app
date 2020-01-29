//
//  UIActivityIndicatorViewExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

extension UIActivityIndicatorView {

    func bindStatus(status: RoleStatus) {
        switch status {
        case .active, .inactive:
            stopAnimating()
            isHidden = true
        case .undetermined:
            isHidden = false
            startAnimating()
        }
    }
    
    func bindNextEvent(event: PresenceEventType) {
        switch event {
        case .checkIn, .checkOut:
            stopAnimating()
            isHidden = true
        case .undetermined:
            isHidden = false
            startAnimating()
        }
    }
    
}
