//
//  UserCell.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 25/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

protocol UserCellDelegate : class {
    func userClick(cell: UICollectionViewCell)
    func userLongClick(cell: UICollectionViewCell, view: UIView)
}

class UserCell : UICollectionViewCell {
    
    @IBOutlet weak var crownImageView: UIImageView!
    @IBOutlet weak var userImageView: RoundedImageView!
    @IBOutlet weak var userLabel: UILabel!
 
    let bag = DisposeBag()
    weak var delegate: UserCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        [userImageView, userLabel].forEach { v in
            v?.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    guard let this = self else { return }
                    this.delegate?.userClick(cell: this)
                })
                .disposed(by: bag)
        }
        
        userImageView.rx.longPressGesture(configuration: { (recognizer, delegate) in
                recognizer.minimumPressDuration = 0.5
                recognizer.delaysTouchesBegan = true
            })
            .when(.recognized)
            .subscribe(onNext: { [weak self] recognizer in
                guard
                    let this = self,
                    let view = recognizer.view
                else {
                    return
                }
                
                this.delegate?.userLongClick(cell: this, view: view)
            })
            .disposed(by: bag)
    }
    
    func fill(user: OrbisUser, group: Group?, isAdministrator: Bool) {
        userImageView.loadUserImage(user: user, activeGroup: group)
        crownImageView.isHidden = !isAdministrator
    }
    
}
