//
//  SettingsCells.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 27/02/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol SettingsCellDelegate : class {
    func dotsClick(cell: SettingsPostCell?)
    func groupClick(cell: SettingsCell?)
    func placeClick(cell: SettingsCell?)
    func editClick(cell: SettingsAdminCell?)
    func changeClick(cell: SettingsGroupCell?)
    func leaveClick(cell: SettingsGroupCell?)
    func followClick(cell: SettingsPlaceCell?)
}

class SettingsCell : UITableViewCell {
    
    weak var delegate: SettingsCellDelegate?
    var section: Int!
    let bag = DisposeBag()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: settingsSocialRowSpace, left: 0, bottom: settingsSocialRowSpace, right: 0))
    }
 
    func setupGroupClick(views: [UIView]) {
        views.forEach { view in
            view.rx.tapGesture()
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.groupClick(cell: self)
                })
                .disposed(by: bag)
        }
    }
    
    func setupPlaceClick(views: [UIView]) {
        views.forEach { view in
            view.rx.tapGesture()
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.placeClick(cell: self)
                })
                .disposed(by: bag)
        }
    }
}

class SettingsGroupCell : SettingsCell {
    
    @IBOutlet weak var groupImageView: RoundedImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var changeButton: GroupButton!
    @IBOutlet weak var leaveButton: GroupButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupGroupClick(views: [groupImageView, groupNameLabel])
        
        changeButton.rx.tap
            .bind { [weak self] in
                self?.delegate?.changeClick(cell: self)
            }
            .disposed(by: bag)
        
        leaveButton.rx.tap
            .bind { [weak self] in
                self?.delegate?.leaveClick(cell: self)
            }
            .disposed(by: bag)
    }

}

class SettingsAdminCell : SettingsCell {

    @IBOutlet weak var groupImageView: RoundedImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupGroupClick(views: [groupImageView, groupNameLabel])
        
        editButton.rx.tap
            .bind { [weak self] in
                self?.delegate?.editClick(cell: self)
            }
            .disposed(by: bag)
    }
}

class SettingsPlaceCell : SettingsCell {
    
    @IBOutlet weak var groupImageView: RoundedImageView!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var followButton: FollowPlaceButton!
    @IBOutlet weak var followIndicatorView: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupGroupClick(views: [groupImageView])
        setupPlaceClick(views: [placeLabel])
        
        followButton.rx.tap
            .bind { [weak self] in
                self?.delegate?.followClick(cell: self)
            }
            .disposed(by: bag)
    }
}

class SettingsPostCell : SettingsCell {
    
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var descLabel2: UILabel!
    @IBOutlet weak var dotsButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        dotsButton.rx.tap
            .bind { [weak self] in
                self?.delegate?.dotsClick(cell: self)
            }
            .disposed(by: bag)
    }
    
}
