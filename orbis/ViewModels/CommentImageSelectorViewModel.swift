//
//  CommentImageSelectorViewModel.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 02/04/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class CommentImageSelectorViewModel : CreatePostViewModel {
    
    private var commentsViewModel: CommentsViewModel!
    
    init(commentsViewModel: CommentsViewModel) {
        super.init()
        self.commentsViewModel = commentsViewModel
        self.allowMultipleSelection = false
        self.hasAssets = true
        self.hasCameraItem = true
        self.origin = ViewControllerInfo.comments
        self.group = UserDefaultsRepository.instance().getActiveGroup()
    }
    
    override func stepTwo() {
        guard let asset = selectedAssets.first?.value else {
            defaultSubject.onNext(Words.errorSelectOneImageOrVideo)
            return
        }
        
        if commentsViewModel.saveComment(text: nil, asset: asset) {
            defaultSubject.onNext(PopToViewController(type: CommentsViewController.self))
        }
    }
    
}
