//
//  PlaybackView.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 24/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class PlaybackView : UIView {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var playButton: UIImageView!
    @IBOutlet weak var pauseButton: UIImageView!
    @IBOutlet weak var refreshButton: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("PlaybackView", owner: self, options: nil)
        addSubview(containerView)
        containerView.fillToSuperview()
    }
    
}
