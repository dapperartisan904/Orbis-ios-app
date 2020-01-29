//
//  CreatePostButtons.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 23/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import SwifterSwift

protocol CreatePostButtonsDelegate : class {
    func createPostButtonClick(postType: PostType)
    func createPostAlert(word: Words)
}

class CreatePostButtons : UIView {
    
    private let bag = DisposeBag()
    private var initialized = false
    private var buttons = [PostType : RoundedButton]()
    private var mainButton: RoundedButton!
    private var mainImageView: UIImageView!
    private var maximized = false
    private var animating = false
    private let duration: TimeInterval = 0.3
    
    weak var delegate: CreatePostButtonsDelegate?
    var origin: ViewControllerInfo!
    
    var activeGroup: Group? {
        didSet {
            paint()
        }
    }
    
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
        let bigSize: CGFloat = 60
        let smallSize: CGFloat = 40
        let sizeDiff = (bigSize - smallSize) / 2
        let inset = UIEdgeInsets(inset: 8)

        clipsToBounds = false
        
        mainButton = RoundedButton()
        mainButton.translatesAutoresizingMaskIntoConstraints = false
        mainButton.clipsToBounds = false
        mainButton.shadowColor = UIColor.black
        mainButton.shadowRadius = 2.0
        mainButton.shadowOpacity = 0.7
        mainButton.shadowOffset = CGSize(width: 0, height: 2)
        mainButton.setImage(nil, for: .normal)
        mainButton.backgroundColor = UIColor.red
        
        mainImageView = UIImageView()
        mainImageView.translatesAutoresizingMaskIntoConstraints = false
        mainImageView.contentMode = .scaleAspectFit
        mainImageView.image = UIImage(named: "baseline_add_black_48pt")?.template
            .withAlignmentRectInsets(UIEdgeInsets(inset: -12))
        
        let image0 = UIImage(named: "baseline_create_black_48pt")?.template
        let image1 = UIImage(named: "baseline_photo_camera_white_48pt")?.template
        let image2 = UIImage(named: "baseline_videocam_black_48pt")?.template
        
        let textButton = RoundedButton()
        textButton.translatesAutoresizingMaskIntoConstraints = false
        textButton.clipsToBounds = false
        textButton.shadowColor = UIColor.black
        textButton.shadowRadius = 2.0
        textButton.shadowOpacity = 0.7
        textButton.shadowOffset = CGSize(width: 0, height: 2)
        textButton.backgroundColor = UIColor.red
        textButton.setImage(image0, for: .normal)
        textButton.imageView?.contentMode = .scaleAspectFit
        textButton.alpha = 0.0
        textButton.isHidden = true
        textButton.imageEdgeInsets = inset
        
        let imageButton = RoundedButton()
        imageButton.translatesAutoresizingMaskIntoConstraints = false
        imageButton.clipsToBounds = false
        imageButton.shadowColor = UIColor.black
        imageButton.shadowRadius = 2.0
        imageButton.shadowOpacity = 0.7
        imageButton.shadowOffset = CGSize(width: 0, height: 2)
        imageButton.backgroundColor = UIColor.red
        imageButton.setImage(image1, for: .normal)
        imageButton.imageView?.contentMode = .scaleAspectFit
        imageButton.alpha = 0.0
        imageButton.isHidden = true
        imageButton.imageEdgeInsets = inset
        
        let videoButton = RoundedButton()
        videoButton.translatesAutoresizingMaskIntoConstraints = false
        videoButton.clipsToBounds = false
        videoButton.shadowColor = UIColor.black
        videoButton.shadowRadius = 2.0
        videoButton.shadowOpacity = 0.7
        videoButton.shadowOffset = CGSize(width: 0, height: 2)
        videoButton.backgroundColor = UIColor.red
        videoButton.setImage(image2, for: .normal)
        videoButton.imageView?.contentMode = .scaleAspectFit
        videoButton.alpha = 0.0
        videoButton.isHidden = true
        videoButton.imageEdgeInsets = inset
    
        addSubview(mainButton)
        mainButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        mainButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        mainButton.widthAnchor.constraint(equalToConstant: bigSize).isActive = true
        mainButton.heightAnchor.constraint(equalToConstant: bigSize).isActive = true
        
        addSubview(mainImageView)
        mainImageView.centerXAnchor.constraint(equalTo: mainButton.centerXAnchor).isActive = true
        mainImageView.centerYAnchor.constraint(equalTo: mainButton.centerYAnchor).isActive = true
        mainImageView.widthAnchor.constraint(equalToConstant: bigSize).isActive = true
        mainImageView.heightAnchor.constraint(equalToConstant: bigSize).isActive = true
        
        addSubview(textButton)
        textButton.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        textButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -sizeDiff).isActive = true
        textButton.widthAnchor.constraint(equalToConstant: smallSize).isActive = true
        textButton.heightAnchor.constraint(equalToConstant: smallSize).isActive = true
        
        addSubview(imageButton)
        imageButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 36).isActive = true
        imageButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -18).isActive = true
        imageButton.widthAnchor.constraint(equalToConstant: smallSize).isActive = true
        imageButton.heightAnchor.constraint(equalToConstant: smallSize).isActive = true
        
        addSubview(videoButton)
        videoButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        videoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -sizeDiff).isActive = true
        videoButton.widthAnchor.constraint(equalToConstant: smallSize).isActive = true
        videoButton.heightAnchor.constraint(equalToConstant: smallSize).isActive = true
        
        buttons[PostType.text] = textButton
        buttons[PostType.images] = imageButton
        buttons[PostType.video] = videoButton
        
        mainButton.rx.tap
            .bind { [weak self] in
                self?.toggle()
            }
            .disposed(by: bag)
        
        textButton.rx.tap
            .bind { [weak self] in
                self?.buttonClick(postType: .text)
            }
            .disposed(by: bag)
        
        imageButton.rx.tap
            .bind { [weak self] in
                self?.buttonClick(postType: .images)
            }
            .disposed(by: bag)
        
        videoButton.rx.tap
            .bind { [weak self] in
                self?.buttonClick(postType: .video)
            }
            .disposed(by: bag)
        
        paint()
    }
    
    private func buttonClick(postType: PostType) {
        guard let _ = UserDefaultsRepository.instance().getMyUser() else {
            delegate?.createPostAlert(word: Words.errorNoUserGroupPost)
            return
        }

        guard let g = activeGroup else {
            delegate?.createPostAlert(word: Words.errorNoActiveGroupPost)
            return
        }
        
        if origin == ViewControllerInfo.group {
            if !RolesViewModel.instance().isMemberOrAdministrator(groupKey: g.key!) {
                delegate?.createPostAlert(word: Words.errorNoMemberGroupPost)
                return
            }
        }
        
        toggle()
        delegate?.createPostButtonClick(postType: postType)
    }
    
    private func paint() {
        if buttons.isEmpty {
            return
        }

        let group = activeGroup
        let darkImage = group == nil || textColorShouldBeDark(colorIndex: group!.colorIndex!)
        let tintColor = darkImage ? UIColor.black : UIColor.white

        var allButtons = [mainButton]
        allButtons.append(contentsOf: Array(buttons.values))

        allButtons.forEach { button in
            button?.backgroundColor = groupSolidColor(group: group, defaultColor: UIColor.white)
            button?.imageView?.tintColor = tintColor
        }
        
        mainImageView.tintColor = tintColor
    }
    
    private func toggle() {
        if animating {
            return
        }
    
        animating = true
        maximized = !maximized
        
        buttons.forEach { entry in
            let button = entry.value
            button.isHidden = false
            
            if maximized {
                button.fadeIn(duration: duration, completion: { _ in })
            }
            else {
                button.fadeOut(duration: duration, completion: { _ in
                    button.isHidden = true
                })
            }
        }
        
        let angle: CGFloat = maximized ? 45.0 : -45.0
        mainImageView!.rotate(byAngle: angle, ofType: UIView.AngleUnit.degrees, animated: true, duration: duration, completion: { _ in
            self.animating = false
        })
    }

}
