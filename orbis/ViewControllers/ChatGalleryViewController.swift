//
//  ChatGalleryViewController.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 31/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

class ChatGalleryViewController : OrbisViewController {
    
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var imageView: UIImageView!
    
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.delegate = self
        navItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneClick))
        
        imageView.kf.setImage(with: url)
    }
        
    @objc func doneClick() {
        dismiss(animated: true, completion: nil)
    }
}

extension ChatGalleryViewController : UINavigationBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
}
