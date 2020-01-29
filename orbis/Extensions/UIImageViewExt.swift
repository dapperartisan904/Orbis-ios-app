//
//  UIImageViewExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 28/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import Photos
import Kingfisher

extension ImageView {
    
    func loadChatImage(url: String?) {
        guard let url = url else {
            image = nil
            return
        }
        
        let cloudUrl = S3Folder.chats.downloadURL(cloudKey: url)
        kf.setImage(with: cloudUrl, options: [.transition(.fade(0.2))])
        
        //print2("loadChatImage: \(url)")
        //print2("loadChatImage: \(cloudUr ?? "")")
    }
    
    func loadGroupImage(group: Group?) {
        guard let group = group else {
            image = UIImage(named: "orbis_logo")
            return
        }
        
        borderColor = groupSolidColor(group: group)
        kf.setImage(with: S3Folder.groups.downloadURL(cloudKey: group.imageName))
    }
    
    func loadPlaceImage(place: Place?, activeGroup: Group?, inset: CGFloat = -12.0, colorHex: String? = nil, stroke: Bool = false) {
        guard let place = place, let type = place.placeType() else {
            image = UIImage(named: "orbis_logo")
            return
        }
    
        image = UIImage(named: type.rawValue)?
            .withRenderingMode(.alwaysTemplate)
            .withAlignmentRectInsets(UIEdgeInsets(inset: inset))
        
        var color: UIColor
        if let colorHex = colorHex {
            color = UIColor(rgba: colorHex)
        }
        else {
            color = activeGroup == nil ? groupSolidColor(index: 2) : groupSolidColor(group: activeGroup!)
        }

        tintColor = color
        
        if stroke {
            groupStroke(group: activeGroup)
        }
    }
    
    func loadUserImage(image: UIImage? = nil, user: OrbisUser?, activeGroup: Group?, width: CGFloat? = nil) {
        groupStroke(group: activeGroup, width: width)
        
        if let image = image {
            self.image = image
            return
        }
        
        guard let user = user else {
            self.image = UIImage(named: "orbis_logo")
            return
        }
    
        if let img = user.imageName {
            kf.setImage(with: S3Folder.users.downloadURL(cloudKey: img))
        }
        else if let img = user.providerImageUrl {
            kf.setImage(with: URL(string: img))
        }
        else if let img = activeGroup?.imageName {
            kf.setImage(with: S3Folder.groups.downloadURL(cloudKey: img))
        }
        else {
            self.image = UIImage(named: "orbis_logo")
        }
    }
    
    func groupStroke(group: Group?, width: CGFloat? = nil) {
        if let width = width {
            borderWidth = width
        }
        borderColor = group == nil ? groupSolidColor(index: 2) : groupStrokeColor(group: group!)
    }
    
    func tint(activeGroup: Group?, isSelected: Bool) {
        if isSelected {
            if let g = activeGroup {
                tintColor = groupSolidColor(group: g)
            }
            else {
                tintColor = UIColor(rgba: "#777777")
            }
        }
        else {
            tintColor = UIColor(rgba: "#CCCCCC")
        }
    }
    
    func tintStroke(activeGroup: Group?, isSelected: Bool) {
        if isSelected {
            if let g = activeGroup {
                tintColor = groupStrokeColor(group: g)
            }
            else {
                tintColor = UIColor(rgba: "#777777")
            }
        }
        else {
            tintColor = UIColor(rgba: "#CCCCCC")
        }
    }
    
}
