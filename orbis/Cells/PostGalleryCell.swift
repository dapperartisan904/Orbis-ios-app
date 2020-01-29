//
//  PostGalleryCell.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 30/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import RxSwift

protocol PostGalleryCellDelegate : class {
    func shareClick(cell: UITableViewCell?)
    func likeClick(cell: UITableViewCell?)
}

class PostGalleryCell : UITableViewCell {
    
    @IBOutlet weak var postImageView: RatioImageView!
    @IBOutlet weak var likeImageView: UIImageView!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var shareButton: UIImageView!
    @IBOutlet weak var imageRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var totalHeightConstraint: NSLayoutConstraint!
 
    weak var delegate: PostGalleryCellDelegate?
    private let bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = UIColor.clear
        backgroundView?.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
        
        likeImageView.image = UIImage(named: "like")?.template
        shareButton.image = UIImage(named: "share")?.template
        
        postImageView.kf.indicatorType = IndicatorType.activity
        (postImageView.kf.indicator?.view as? UIActivityIndicatorView)?.color = UIColor.black
    
        [likeImageView, likeLabel].forEach { v in
            v.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.likeClick(cell: self)
                })
                .disposed(by: bag)
        }
        
        shareButton.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.shareClick(cell: self)
            })
            .disposed(by: bag)
    }
    
}
