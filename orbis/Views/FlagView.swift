//
//  FlagView.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class FlagView : UIView {
    
    class func createAndAttachToContainer(container: UIView) -> FlagView {
        let fv = UIView.loadFromNib(named: "FlagView") as! FlagView
        fv.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(fv)
        fv.anchorToSuperview()
        return fv
    }
    
    @IBOutlet weak var poleImageView: UIImageView!
    @IBOutlet weak var flagImageView: UIImageView!
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var placeImageView: UIImageView!

    func paint(group: Group?, place: Place?) {
        let strokeColor: UIColor
        let solidColor: UIColor

        if let g = group {
            solidColor = groupSolidColor(group: g)
            strokeColor = groupStrokeColor(group: g)
        }
        else {
            solidColor = UIColor(rgba: tabInactiveColor)
            strokeColor = UIColor(rgba: tabActiveColor)
        }

        poleImageView.image = UIImage(named: "pole")?.filled(withColor: strokeColor)
        flagImageView.image = UIImage(named: "flag")?.filled(withColor: solidColor)
        groupImageView.loadGroupImage(group: group)
        placeImageView.loadPlaceImage(place: place, activeGroup: group, inset: 0.0)
        
        if let g = group {
            placeImageView.tintColor = groupStrokeColor(group: g)
        }
    }
    
}
