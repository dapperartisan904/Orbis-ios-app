//
//  CreatePostHeader.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 24/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

/*
    Ideal layout (image + label) centered horizontally is not possible.
    Tried with stack view and another approaches.
 */
class CreatePostHeader : UIView {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var groupImageView: RoundedImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("CreatePostHeader", owner: self, options: nil)
        addSubview(containerView)
        containerView.fillToSuperview()
    }
    
    func fill(group: Group, place: Place?) {
        groupImageView.loadGroupImage(group: group)
        groupNameLabel.text = group.name
    }
    
}
