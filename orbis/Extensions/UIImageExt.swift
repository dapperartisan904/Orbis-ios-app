//
//  UIImageExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    class func loadPlaceImage(place: Place?, activeGroup: Group?, inset: CGFloat = -12.0, colorHex: String? = nil) -> UIImage? {
        guard let place = place, let type = place.placeType() else {
            return UIImage(named: "orbis_logo")
        }

        var color: UIColor
        if let colorHex = colorHex {
            color = UIColor(rgba: colorHex)
        }
        else {
            color = activeGroup == nil ? groupSolidColor(index: 2) : groupSolidColor(group: activeGroup!)
        }
        
        let image = UIImage(named: type.rawValue)?
            .withRenderingMode(.alwaysTemplate)
            .withAlignmentRectInsets(UIEdgeInsets(inset: inset))
            .filled(withColor: color)
        
        return image
    }
    
    class func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {
        let cgimage = image.cgImage!
        let contextImage: UIImage = UIImage(cgImage: cgimage)
        let contextSize: CGSize = contextImage.size
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = cgimage.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
}
