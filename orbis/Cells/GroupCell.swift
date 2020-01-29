//
//  GroupCell.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 27/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol GroupCellDelegate : class {
    func followClick(cell: GroupCell)
    func mainActionClick(cell: GroupCell)
    func groupClick(cell: GroupCell)
}

class GroupCell : UITableViewCell {
    
    weak var delegate: GroupCellDelegate?
    private let bag = DisposeBag()
    
    @IBOutlet weak var groupImageView: RoundedImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var mainActionButton: GroupButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var followActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var mainActionIndicatorView: UIActivityIndicatorView!
 
    override func awakeFromNib() {
        super.awakeFromNib()
        
        followButton.imageView?.contentMode = .scaleAspectFit
        followButton.setImage(UIImage(named: "ic_star_yellow_2"), for: .selected)
        
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
        
        [groupImageView, groupNameLabel].forEach { view in
            view.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    guard let this = self else { return }
                    this.delegate?.groupClick(cell: this)
                })
                .disposed(by: bag)
        }
    }
    
}
