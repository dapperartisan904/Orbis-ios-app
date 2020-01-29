//
//  OrbisToolbars.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 28/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

// Default height: 50

protocol ToolbarDelegate : class {
    func backClick()
    func homeClick()
    func settingsClick()
    func toolbarTitleClick()
    func dotsClick()
}

class BaseToolbar : UIView {
    fileprivate var backButton: UIButton!
    fileprivate let bag = DisposeBag()
    fileprivate var setupExecuted = false
    
    weak var delegate: ToolbarDelegate?

    @IBInspectable var drawLineAtBottom: Bool = false {
        didSet {
            drawLineAtBottomIfNeeded()
        }
    }
    
    deinit {
        delegate = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func setup() {
        setupExecuted = true
        findConstraint(layoutAttribute: .height)?.constant = 50
        
        backButton = UIButton(type: .custom)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.imageForNormal = UIImage(named: "baseline_arrow_back_ios_black_24pt")
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.tintColor = UIColor.darkGray
        backButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        addSubview(backButton)
        backButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12).isActive = true
        backButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        backButton.rx.tap
            .bind { [weak self] in
                print2("BaseToolbar::backTap")
                self?.delegate?.backClick()
            }
            .disposed(by: bag)
    }
    
    /*
        Must be call after concrete classes .setup()
        Otherwise some view can be draw on top of line at bottom
     */
    fileprivate func drawLineAtBottomIfNeeded() {
        print2("drawLineAtBottomIfNeeded \(drawLineAtBottom)")

        if !drawLineAtBottom {
            return
        }
        
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = UIColor.black
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        addSubview(line)
        line.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        line.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        line.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
}

class DefaultToolbar : BaseToolbar {
    private var icon: UIButton!
    var settingsButton: UIButton!
    var dotsButton: UIButton!
    
    @IBInspectable var drawSettingsIcon: Bool = true {
        didSet {
            mainAsync {
                self.settingsButton?.isHidden = self.drawSettingsIcon
                
                // Not sure why isHidden = false is not working
                if !self.drawSettingsIcon {
                    self.settingsButton?.removeFromSuperview()
                }
                
                print2("[DefaultToolbar] drawSettingsIcon \(self.drawSettingsIcon)")
            }
        }
    }
    
    @IBInspectable var drawDotsIcon: Bool = false {
        didSet {
            mainAsync {
                self.dotsButton?.isHidden = self.drawDotsIcon
                
                // Not sure why isHidden = false is not working
                if !self.drawDotsIcon {
                    self.dotsButton?.removeFromSuperview()
                }
                
                print2("[DefaultToolbar] drawDotsIcon \(self.drawDotsIcon)")
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print2("drawSettingsIcon [0]: \(drawSettingsIcon) \(hashValue)")
        setup()
    }
    
    override fileprivate func setup() {
        if setupExecuted {
            return
        }
        
        super.setup()
        
        print2("drawSettingsIcon [2]: \(drawSettingsIcon) \(hashValue)")
        
        icon = UIButton(type: .custom)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.imageForNormal = UIImage(named: isProduction() ? "tab_map_active" : "baseline_bug_report_black_48pt")
        icon.tintColor = UIColor.darkGray
        icon.imageView?.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 40).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        settingsButton = UIButton(type: .custom)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.imageForNormal = UIImage(named: "settings")
        settingsButton.imageView?.contentMode = .scaleAspectFit
        settingsButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        settingsButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        dotsButton = UIButton(type: .custom)
        dotsButton.translatesAutoresizingMaskIntoConstraints = false
        dotsButton.imageForNormal = UIImage(named: "baseline_more_vert_black_24pt")
        dotsButton.tintColor = UIColor.black
        dotsButton.imageView?.contentMode = .scaleAspectFit
        dotsButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        dotsButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        addSubview(icon)
        icon.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        icon.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        addSubview(settingsButton)
        settingsButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12).isActive = true
        settingsButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

        addSubview(dotsButton)
        dotsButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12).isActive = true
        dotsButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        icon.rx.tap
            .bind { [weak self] in
                self?.delegate?.homeClick()
            }
            .disposed(by: bag)
        
        settingsButton.rx.tap
            .bind { [weak self] in
                self?.delegate?.settingsClick()
            }
            .disposed(by: bag)
        
        dotsButton.rx.tap
            .bind { [weak self] in
                self?.delegate?.dotsClick()
            }
            .disposed(by: bag)
        
        dotsButton.isHidden = true
    }
    
}

class TitleToolbar : BaseToolbar {
    private(set) var label: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override fileprivate func setup() {
        super.setup()
        
        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 21.0)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 1
        label.textAlignment = NSTextAlignment.center

        addSubview(label)
        label.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: -44).isActive = true
        label.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        sendSubviewToBack(label)
        
        label.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                print2("TitleToolbar::labelTap")
                self?.delegate?.toolbarTitleClick()
            })
            .disposed(by: bag)
    }
}
