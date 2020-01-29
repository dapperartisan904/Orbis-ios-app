//
//  EventCell.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 24/04/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol EventCellDelegate : class {
    func expandClick(cell: EventCell)
    func attendClick(cell: EventCell)
    func seeMoreClick(cell: EventCell)
    func editClick(cell: EventCell)
    func linkClick(cell: EventCell)
    func groupClick(cell: EventCell)
    func placeClick(cell: EventCell)
    func addressClick(cell: EventCell)
    func userClick(cell: EventCell, index: Int)
}

class EventCell : UITableViewCell {
    
    weak var delegate: EventCellDelegate?
    private var bag = DisposeBag()
    
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var confirmedLabel: UILabel!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var attendButton: GroupButton!
    @IBOutlet weak var attendIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var expandButton: UIButton!
    @IBOutlet weak var bgView: UIView!
    
    @IBOutlet weak var groupImageView: RoundedImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var presentLabel: UILabel!
    @IBOutlet weak var placeNameLabel2: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel2: UILabel!
    @IBOutlet weak var usersConfirmedLabel: UILabel!
    
    @IBOutlet weak var usersStackView: UIStackView!
    @IBOutlet weak var userContainer0: UIView!
    @IBOutlet weak var userContainer1: UIView!
    @IBOutlet weak var userContainer2: UIView!
    
    @IBOutlet weak var usernameLabel0: UILabel!
    @IBOutlet weak var userImageView0: RoundedImageView!
    @IBOutlet weak var usernameLabel1: UILabel!
    @IBOutlet weak var userImageView1: RoundedImageView!
    @IBOutlet weak var usernameLabel2: UILabel!
    @IBOutlet weak var userImageView2: RoundedImageView!
    @IBOutlet weak var usersIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var usersErrorView: UILabel!
    @IBOutlet weak var noUsersView: UILabel!
    
    @IBOutlet weak var bottomButtonsStackView: UIStackView!
    @IBOutlet weak var seeMoreButton: OutlineButton!
    @IBOutlet weak var editButton: OutlineButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        expandButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.delegate?.expandClick(cell: this)
            }
            .disposed(by: bag)
        
        attendButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.delegate?.attendClick(cell: this)
            }
            .disposed(by: bag)
        
        seeMoreButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.delegate?.seeMoreClick(cell: this)
            }
            .disposed(by: bag)
        
        editButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.delegate?.editClick(cell: this)
            }
            .disposed(by: bag)
        
        linkLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let this = self else { return }
                this.delegate?.linkClick(cell: this)
            })
            .disposed(by: bag)
        
        placeNameLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let this = self else { return }
                this.delegate?.placeClick(cell: this)
            })
            .disposed(by: bag)
        
        placeNameLabel2.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let this = self else { return }
                this.delegate?.placeClick(cell: this)
            })
            .disposed(by: bag)
        
        addressLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let this = self else { return }
                this.delegate?.addressClick(cell: this)
            })
            .disposed(by: bag)
        
        groupImageView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let this = self else { return }
                this.delegate?.groupClick(cell: this)
            })
            .disposed(by: bag)
        
        groupNameLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let this = self else { return }
                this.delegate?.groupClick(cell: this)
            })
            .disposed(by: bag)
        
        for i in 0...2 {
            let views = getUserViews(index: i)
            [views.0, views.1].forEach { v in
                v.rx.tapGesture()
                    .when(.recognized)
                    .subscribe(onNext: { [weak self] _ in
                        guard let this = self else { return }
                        this.delegate?.userClick(cell: this, index: i)
                    })
                    .disposed(by: bag)
            }
        }
    }
    
    func getUserViews(index: Int) -> (UIImageView, UILabel) {
        switch index {
        case 0:
            return (userImageView0, usernameLabel0)
        case 1:
            return (userImageView1, usernameLabel1)
        default:
            return (userImageView2, usernameLabel2)
        }
    }
}
