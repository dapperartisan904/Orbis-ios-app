//
//  PostWrapper.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 14/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class PostWrapper {
    
    var post: OrbisPost
    var winnerGroup: Group?
    var loserGroup: Group?
    var activeGroup: Group?
    var user: OrbisUser?
    var place: Place?
    var counter: PostCounter?
    var isLiking: Bool
    var indexPath: IndexPath?
    var cellDelegate: PostCellDelegate?

    init(
        post: OrbisPost,
        winnerGroup: Group?,
        loserGroup: Group?,
        activeGroup: Group?,
        user: OrbisUser?,
        place: Place?,
        counter: PostCounter?,
        isLiking: Bool,
        indexPath: IndexPath? = nil,
        cellDelegate: PostCellDelegate? = nil) {
        
        self.post = post
        self.winnerGroup = winnerGroup
        self.loserGroup = loserGroup
        self.activeGroup = activeGroup
        self.user = user
        self.place = place
        self.counter = counter
        self.isLiking = isLiking
        self.indexPath = indexPath
        self.cellDelegate = cellDelegate
    }
    
    
}
