//
//  DominatedPlaceCell.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 25/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

protocol DominatedPlaceCellDelegate : class {
    func placeClick(cell: UITableViewCell)
    func followClick(cell: UITableViewCell)
}

class DominatedPlaceCell : UITableViewCell {
    
    @IBOutlet weak var placeImageView: UIImageView!
    @IBOutlet weak var placeStrokeImageView: RoundedImageView!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var followButton: FollowPlaceButton!
    @IBOutlet weak var followActivityIndicatorView: UIActivityIndicatorView!
    
    weak var delegate: DominatedPlaceCellDelegate?
    let bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        followButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.delegate?.followClick(cell: this)
            }
            .disposed(by: bag)
        
        [placeLabel, placeImageView].forEach { view in
            guard let view = view else { return }
            view.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    guard let this = self else { return }
                    this.delegate?.placeClick(cell: this)
                })
                .disposed(by: bag)
        }
    }
    
}
