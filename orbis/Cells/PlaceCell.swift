//
//  PlaceCell.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

protocol PlaceCellDelegate : class {
    func followClick(cell: UITableViewCell?)
    func mainActionClick(cell: UITableViewCell?)
    func placeClick(cell: UITableViewCell?)
    func groupClick(cell: UITableViewCell?)
}

class PlaceCell : UITableViewCell {

    weak var delegate: PlaceCellDelegate?
    
    @IBOutlet weak var groupImageView: RoundedImageView!
    @IBOutlet weak var placeImageView: UIImageView!
    @IBOutlet weak var placeStrokeImageView: RoundedImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var mainActionButton: GroupButton!
    @IBOutlet weak var followButton: FollowPlaceButton!
    @IBOutlet weak var followActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var mainActionIndicatorView: UIActivityIndicatorView!
    
    private let bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        followButton.imageView?.contentMode = .scaleAspectFit
        
        followButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.delegate?.followClick(cell: this)
            }
            .disposed(by: bag)
        
        mainActionButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.delegate?.mainActionClick(cell: this)
            }
            .disposed(by: bag)
        
        nameLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let this = self else { return }
                this.delegate?.placeClick(cell: this)
            })
            .disposed(by: bag)
        
        groupImageView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.groupClick(cell: self)
            })
            .disposed(by: bag)
    }
}
