//
//  MapButtonsView.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

protocol MapButtonsDelegate : class {
    func myLocationClick()
    func zoomInClick()
    func zoomOutClick()
    func fullscreenClick(isMaximized: Bool)
    func onSetup(view: MapButtonsView)
}

extension MapButtonsDelegate {
    func onSetup(view: MapButtonsView) {
        // Do nothing
    }
}

class MapButtonsView : UIView {
    
    var myLocationButton: RoundedButton!
    var zoomInButton: RoundedButton!
    var zoomOutButton: RoundedButton!
    var fullscreenButton: RoundedButton!
    
    weak var delegate: MapButtonsDelegate?
    private let bag = DisposeBag()
    private var initialized = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !initialized {
            initialized = true
            delay(ms: 500, block: { [weak self] in
                self?.setup()
            })
        }
    }
    
    private func setup() {
        let bigButtonSize: CGFloat = 48
        let smallButtonSize: CGFloat = 36
        let midSpace: CGFloat = 22
        let totalHeight = frame.height
        let bottomMargin = totalHeight * 0.3
        let topMargin: CGFloat = 25
        let locationTop = bottomMargin + bigButtonSize
        let maximizeBottom = totalHeight - topMargin - smallButtonSize
        let imageInset = UIEdgeInsets.init(inset: 10)
        let imageInset2 = UIEdgeInsets.init(inset: 7)
        let center = locationTop + ((maximizeBottom - locationTop) / 2)
        
        print2("totalHeight: \(totalHeight) locationTop: \(locationTop) maximizeBottom: \(maximizeBottom) center: \(center)")
        
        clipsToBounds = false
        
        myLocationButton = RoundedButton()
        myLocationButton.translatesAutoresizingMaskIntoConstraints = false
        myLocationButton.imageForNormal = UIImage(named: "baseline_my_location_black_48pt")
        myLocationButton.imageView?.contentMode = .scaleAspectFit
        myLocationButton.tintColor = UIColor.darkGray
        myLocationButton.backgroundColor = UIColor.white
        myLocationButton.imageEdgeInsets = imageInset
        
        zoomInButton = RoundedButton()
        zoomInButton.translatesAutoresizingMaskIntoConstraints = false
        zoomInButton.imageForNormal = UIImage(named: "baseline_add_black_48pt")
        zoomInButton.imageView?.contentMode = .scaleAspectFit
        zoomInButton.tintColor = UIColor.darkGray
        zoomInButton.backgroundColor = UIColor.white
        zoomInButton.imageEdgeInsets = imageInset2
        
        zoomOutButton = RoundedButton()
        zoomOutButton.translatesAutoresizingMaskIntoConstraints = false
        zoomOutButton.imageForNormal = UIImage(named: "baseline_remove_black_48pt")
        zoomOutButton.imageView?.contentMode = .scaleAspectFit
        zoomOutButton.tintColor = UIColor.darkGray
        zoomOutButton.backgroundColor = UIColor.white
        zoomOutButton.imageEdgeInsets = imageInset2
        
        fullscreenButton = RoundedButton()
        fullscreenButton.translatesAutoresizingMaskIntoConstraints = false
        fullscreenButton.imageForNormal = UIImage(named: "baseline_fullscreen_black_48pt")
        fullscreenButton.imageForSelected = UIImage(named: "baseline_fullscreen_exit_black_48pt")
        fullscreenButton.imageView?.contentMode = .scaleAspectFit
        fullscreenButton.tintColor = UIColor.darkGray
        fullscreenButton.backgroundColor = UIColor.white
        fullscreenButton.imageEdgeInsets = imageInset2
        
        [myLocationButton, zoomInButton, zoomOutButton, fullscreenButton].forEach { button in
            button?.clipsToBounds = false
            button?.shadowColor = UIColor.darkGray
            button?.shadowOffset = CGSize(width: 0, height: 2)
            button?.shadowRadius = 3.0
            button?.shadowOpacity = 0.7
        }
        
        addSubview(myLocationButton)
        myLocationButton.widthAnchor.constraint(equalToConstant: bigButtonSize).isActive = true
        myLocationButton.heightAnchor.constraint(equalToConstant: bigButtonSize).isActive = true
        myLocationButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        myLocationButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomMargin).isActive = true
        
        addSubview(zoomInButton)
        zoomInButton.widthAnchor.constraint(equalToConstant: smallButtonSize).isActive = true
        zoomInButton.heightAnchor.constraint(equalToConstant: smallButtonSize).isActive = true
        zoomInButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
        zoomInButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(center - midSpace)).isActive = true
        
        addSubview(zoomOutButton)
        zoomOutButton.widthAnchor.constraint(equalToConstant: smallButtonSize).isActive = true
        zoomOutButton.heightAnchor.constraint(equalToConstant: smallButtonSize).isActive = true
        zoomOutButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
        zoomOutButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(center + midSpace)).isActive = true
        
        addSubview(fullscreenButton)
        fullscreenButton.widthAnchor.constraint(equalToConstant: smallButtonSize).isActive = true
        fullscreenButton.heightAnchor.constraint(equalToConstant: smallButtonSize).isActive = true
        fullscreenButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
        fullscreenButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -maximizeBottom).isActive = true
        
        myLocationButton.rx.tap
            .bind { [weak self] in self?.delegate?.myLocationClick() }
            .disposed(by: bag)
        
        zoomInButton.rx.tap
            .bind { [weak self] in self?.delegate?.zoomInClick() }
            .disposed(by: bag)
        
        zoomOutButton.rx.tap
            .bind { [weak self] in self?.delegate?.zoomOutClick() }
            .disposed(by: bag)
        
        fullscreenButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.fullscreenButton.isSelected = !this.fullscreenButton.isSelected
                
                if this.fullscreenButton.isSelected {
                    this.fullscreenButton.backgroundColor = UIColor.darkGray
                    this.fullscreenButton.tintColor = UIColor.white
                }
                else {
                    this.fullscreenButton.backgroundColor = UIColor.white
                    this.fullscreenButton.tintColor = UIColor.darkGray
                }
                
                self?.delegate?.fullscreenClick(isMaximized: this.fullscreenButton.isSelected)
            }
            .disposed(by: bag)
        
        delegate?.onSetup(view: self)
    }
    
}
