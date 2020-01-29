//
//  CommentCell.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol CommentCellDelegate : PostCellDelegate {
    func replyClick(cell: UITableViewCell?)
}

class CommentCell : UITableViewCell {
    
    @IBOutlet weak var groupImageView: RoundedImageView!
    @IBOutlet weak var dotsButton: UIImageView!
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var likeImageView: UIImageView!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var replyButton: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var commentImageView: CacheImageView!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    
    private let bag = DisposeBag()
    weak var delegate: CommentCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        replyButton.tintColorDidChange()
        likeImageView.tintColorDidChange()
        dotsButton.tintColorDidChange()
        commentImageView.kf.indicatorType = .activity
        
        replyButton.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.replyClick(cell: self)
            })
            .disposed(by: bag)
        
        userLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.userClick(cell: self)
            })
            .disposed(by: bag)
        
        [likesLabel, likeImageView].forEach { v in
            v?.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.likeClick(cell: self)
                })
                .disposed(by: bag)
        }
        
        [groupLabel, groupImageView].forEach { v in
            v?.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.mainGroupClick(cell: self)
                })
                .disposed(by: bag)
        }
    }
}
