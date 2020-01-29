//
//  UIApplicationExt.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 15/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {

    func topViewController() -> UIViewController? {
        return self.keyWindow?.rootViewController?.topViewController()
    }

}
