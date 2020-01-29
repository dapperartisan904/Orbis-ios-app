//
//  PlayerView.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 24/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class PlayerView: UIView {
    
    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    private(set) var url: URL?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print2("[VIDEO] playerView layoutSubviews bounds: \(bounds) frame: \(frame)")
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        //playerLayer.frame = bounds
        playerLayer.frame = frame
        CATransaction.commit()
    }
 
    func replacePlayerIfNeeded(url: URL, row: Int) {
        if url.absoluteString == self.url?.absoluteString {
            return
        }
    
        print2("[VIDEO] replacePlayerIfNeeded Row: \(row) \(url.absoluteString) \(String(describing: self.url?.absoluteString))")
        
        self.url = url
        player?.pause()
        //player?.cancelPendingPrerolls()
        player = nil
        
        player = AVPlayer(url: url)
        player?.play()
        //player?.pause()
    }
}
