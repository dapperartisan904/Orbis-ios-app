//
//  ChatImageSelectorViewModel.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 31/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class ChatImageSelectorViewModel : CreatePostViewModel {
    
    private var chatViewModel: ChatViewModel!
    
    init(chatViewModel: ChatViewModel) {
        super.init()
        self.chatViewModel = chatViewModel
        self.allowMultipleSelection = false
        self.hasAssets = true
        self.hasCameraItem = true
        self.origin = ViewControllerInfo.chat
        self.group = chatViewModel.group()
    }

    override func stepTwo() {
        guard let asset = selectedAssets.first?.value else {
            defaultSubject.onNext(Words.errorSelectOneImageOrVideo)
            return
        }
        
        if chatViewModel.saveMessage(text: nil, asset: asset) {
            defaultSubject.onNext(PopToViewController(type: UserViewController.self))
        }
    }
    
}
