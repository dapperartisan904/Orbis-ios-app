//
//  OrbisButtons.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit

class BottomButton : UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel?.font = UIFont.systemFont(ofSize: 17.0)
        backgroundColor = UIColor(rgba: "#d9d9d9")
        setTitleColor(UIColor(rgba: "#4B4B4B"), for: .normal)
        heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        roundCorners([.bottomLeft, .bottomRight], radius: 6.0)
        
        let lineView = LineView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lineView)
    }

    private func setup() {
        makeFontSizeAdjustable()
    }
    
}

class DarkGrayButton : UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    private func initialSetup() {
        makeFontSizeAdjustable()
        findConstraint(layoutAttribute: .height)?.constant = 40.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor(rgba: "#4B4B4B")
        setTitleColor(UIColor.white, for: .normal)
        layer.cornerRadius = 4.0
    }
    
}

class GroupButton : UIButton {
    
    @IBInspectable public var isPresenceEventButton: Bool = false {
        didSet {
            typeSetup()
        }
    }

    @IBInspectable public var isMembershipButton: Bool = false {
        didSet {
            typeSetup()
        }
    }

    @IBInspectable public var isAttendanceButton: Bool = false {
        didSet {
            typeSetup()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 4.0
    }

    private func initialSetup() {
        makeFontSizeAdjustable()
        findConstraint(layoutAttribute: .height)?.constant = 36.5
        titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .light)
    }
    
    private func typeSetup() {
        if isPresenceEventButton {
            titleForNormal = Words.checkIn.localized
            titleForSelected = Words.checkOut.localized
        }
        else if isMembershipButton {
            titleForNormal = Words.joinGroup.localized
            titleForSelected = Words.leaveGroup.localized
        }
        else if isAttendanceButton {
            titleForNormal = Words.attend.localized
            titleForSelected = Words.attending.localized
        }
    }
    
    func paint(group: Group?) {
        if group == nil {
            setTitleColor(UIColor.darkGray, for: .normal)
            backgroundColor = UIColor.white
            layer.borderColor = UIColor.darkGray.cgColor
            layer.borderWidth = 1.0
        }
        else {
            guard let index = group?.colorIndex else {
                return
            }
            paint(colorIndex: index)
        }
    }
    
    func paint(colorIndex: Int) {
        backgroundColor = groupSolidColor(index: colorIndex)
        layer.borderWidth = 0.0
        
        if textColorShouldBeDark(colorIndex: colorIndex) {
            setTitleColor(UIColor.darkGray, for: .normal)
        }
        else {
            setTitleColor(UIColor.white, for: .normal)
        }
    }

    func bindPresenceEvent(nextEvent: PresenceEventType, group: Group?, indicatorView: UIActivityIndicatorView? = nil) {
        switch nextEvent {
        case .checkIn:
            isHidden = false
            isSelected = false
            indicatorView?.stopAnimating()
            indicatorView?.isHidden = true
            paint(group: nil)
        case .checkOut:
            isHidden = false
            isSelected = true
            indicatorView?.stopAnimating()
            indicatorView?.isHidden = true
            paint(group: group)
        case .undetermined:
            isHidden = true
            indicatorView?.isHidden = false
            indicatorView?.startAnimating()
        }
    }
    
    func bind(memberStatus: RoleStatus, group: Group?, indicatorView: UIActivityIndicatorView? = nil) {
        switch memberStatus {
        case .inactive:
            isHidden = false
            isSelected = false
            isHighlighted = false
            indicatorView?.stopAnimating()
            indicatorView?.isHidden = true
            paint(group: nil)
            
        case .active:
            isHidden = false
            isHighlighted = false
            isSelected = true
            indicatorView?.stopAnimating()
            indicatorView?.isHidden = true
            paint(group: group)
            
        case .undetermined:
            isHidden = true
            indicatorView?.isHidden = false
            indicatorView?.startAnimating()
        }
    }
    
    func bind(status: AttendanceStatus, group: Group?, indicatorView: UIActivityIndicatorView? = nil) {
        switch status {
        case .notAttending:
            isHidden = false
            isSelected = false
            isHighlighted = false
            indicatorView?.stopAnimating()
            indicatorView?.isHidden = true
            paint(group: nil)
            
        case .attending:
            isHidden = false
            isHighlighted = false
            isSelected = true
            indicatorView?.stopAnimating()
            indicatorView?.isHidden = true
            paint(group: group)
            
        case .undetermined:
            isHidden = true
            indicatorView?.isHidden = false
            indicatorView?.startAnimating()
        }
    }
}

class FollowPlaceButton : UIButton {
    
    // Used only to avoid unecessary paints
    private var groupKey: String?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    private func initialSetup() {
        imageView?.contentMode = .scaleAspectFit
        imageForNormal = UIImage(named: "follow_unselected")
        imageForSelected = UIImage(named: "follow")
        findConstraint(layoutAttribute: .width)?.constant = 32
        findConstraint(layoutAttribute: .height)?.constant = 32
    }
    
    func paint(group: Group?) {
        if groupKey == group?.key {
            return
        }
        
        groupKey = group?.key
        
        if let group = group {
            imageForSelected = UIImage(named: "follow_\(group.colorIndex!)")
        }
        else {
            imageForSelected = UIImage(named: "follow")
        }
    }
    
    func bindStatus(status: RoleStatus, indicator: UIActivityIndicatorView? = nil) {
        switch status {
        case .active:
            isHidden = false
            isSelected = true
            indicator?.stopAnimating()
            indicator?.isHidden = true
        case .inactive:
            isHidden = false
            isSelected = false
            indicator?.stopAnimating()
            indicator?.isHidden = true
        case .undetermined:
            isHidden = true
            indicator?.isHidden = false
            indicator?.startAnimating()
        }
    }
}

class StarButton : UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    private func initialSetup() {
        setImage(UIImage(named: "ic_star_gray_2"), for: .normal)
        setImage(UIImage(named: "ic_star_yellow_2"), for: .selected)
        imageView?.contentMode = .scaleAspectFit
    }
    
    func bindStatus(status: RoleStatus, indicator: UIActivityIndicatorView? = nil) {
        switch status {
        case .active:
            isHidden = false
            isSelected = true
            indicator?.stopAnimating()
            indicator?.isHidden = true
        case .inactive:
            isHidden = false
            isSelected = false
            indicator?.stopAnimating()
            indicator?.isHidden = true
        case .undetermined:
            isHidden = true
            indicator?.isHidden = false
            indicator?.startAnimating()
        }
    }
}

class RoundedButton : UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //clipsToBounds = true --> with this shadow dont works
        layer.cornerRadius = max(frame.width, frame.height)/2.0
    }
    
}

class OutlineButton : UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        makeFontSizeAdjustable()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        makeFontSizeAdjustable()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setTitleColor(UIColor.darkGray, for: .normal)
        layer.cornerRadius = 4.0
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.darkGray.cgColor
    }
    
}

