//
//  ChatTextCell.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 28/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import RxSwift

protocol ChatCellDelegate : class {
    func imageClick(cell: UITableViewCell?)
}

class BaseChatCell : UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var userImageView: RoundedImageView!
    @IBOutlet weak var baloonImageView: UIImageView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    weak var delegate: ChatCellDelegate?
    
    fileprivate let bag = DisposeBag()
}

class ChatTextCell : BaseChatCell {
    @IBOutlet weak var msgLabel: UILabel!
}

class ChatImageCell : BaseChatCell {
    @IBOutlet weak var chatImageView: CacheImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        chatImageView.kf.indicatorType = IndicatorType.activity
        
        chatImageView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.imageClick(cell: self)
            })
            .disposed(by: bag)
    }
    
    func loadImage(msg: ChatMessage) {
        chatImageView.loadImage(msg: msg)
    }
}
