//
//  CommentImageSelectorViewController.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 31/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class CommentImageSelectorViewController : CreatePostStepOneViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toolbar.label.text = PostType.images.createPostTitle()?.localized
        bottomButton.setTitleUppercased(PostType.images.selectButtonTitle()?.localized, for: .normal)
    }

}
