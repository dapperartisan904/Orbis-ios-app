//
//  UserPlaceCell.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 29/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol UserPlaceCellDelegate : class {
    func placeClick(cell: UITableViewCell?)
    func groupClick(cell: UITableViewCell?)
    func followClick(cell: UITableViewCell?)
}

class UserPlaceCell : UITableViewCell {
    
    @IBOutlet weak var groupImageView: RoundedImageView!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var followButton: FollowPlaceButton!
    @IBOutlet weak var followIndicatorView: UIActivityIndicatorView!
    
    weak var delegate: UserPlaceCellDelegate?
    private let bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        groupImageView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.groupClick(cell: self)
            })
            .disposed(by: bag)
        
        placeLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.placeClick(cell: self)
            })
            .disposed(by: bag)
        
        followButton.rx.tap
            .bind { [weak self] _ in
                self?.delegate?.followClick(cell: self)
            }
            .disposed(by: bag)
    }
}
