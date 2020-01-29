//
//  UserViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 09/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

enum UserTab : Int {
    case groups, chat, places
}

protocol UserChildController {
    var userViewModel: UserViewModel! { get set }
}

class UserViewController : OrbisViewController {
    
    @IBOutlet weak var topCardView: CardView!
    @IBOutlet weak var bottomCardView: CardView!
    @IBOutlet weak var toolbar: DefaultToolbar!
    @IBOutlet weak var userImageView: RoundedImageView!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var groupsButton: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var placesButton: UIButton!
    
    @IBOutlet weak var topCardHeightConstraint: NSLayoutConstraint!
    private var topCardDefHeight: CGFloat!
    private let topCardMinHeight: CGFloat = 120
    private let topCardHeightAnimDuration = 0.35
    
    var userViewModel: UserViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.delegate = self
        topCardDefHeight = topCardHeightConstraint.constant
        
        groupsButton.setImage(UIImage(named: "tab_star_inactive"), for: .normal)
        groupsButton.setImage(UIImage(named: "tab_star_active"), for: .selected)
        chatButton.setImage(UIImage(named: "tab_chat_inactive"), for: .normal)
        chatButton.setImage(UIImage(named: "tab_chat_active"), for: .selected)
        placesButton.setImage(UIImage(named: "tab_place_inactive"), for: .normal)
        placesButton.setImage(UIImage(named: "tab_place_active"), for: .selected)
        groupsButton.imageView?.contentMode = .scaleAspectFit
        chatButton.imageView?.contentMode = .scaleAspectFit
        placesButton.imageView?.contentMode = .scaleAspectFit
        
        print2("isMyUser: \(userViewModel.isMyUser)")
        
        if userViewModel.isMyUser {
            toolbar.settingsButton.isHidden = false
            toolbar.dotsButton.isHidden = true
        }
        else {
            toolbar.settingsButton.isHidden = true
            toolbar.dotsButton.isHidden = false
        }
        
        groupsButton.rx.tap
            .bind { [weak self] in
                self?.selectTab(tab: .groups)
            }
            .disposed(by: bag)
        
        chatButton.rx.tap
            .bind { [weak self] in
                self?.selectTab(tab: .chat)
            }
            .disposed(by: bag)
        
        placesButton.rx.tap
            .bind { [weak self] in
                self?.selectTab(tab: .places)
            }
            .disposed(by: bag)
        
        userViewModel.groupLoadedSubject
            .filter { value in return value }
            .subscribe(onNext: { [weak self] _ in
                guard let this = self else { return }
                this.paintBackground(group: this.userViewModel.group)
                this.updateTopCard()
            })
            .disposed(by: bag)
        
        userViewModel.showingChatSubject
            .subscribe(onNext: { [weak self] showing in
                // Delay is to avoid issue: Collection <NSConcreteHashTable was mutated while being enumerated.'
                delay(ms: 500, block: {
                    if showing {
                        self?.minimizeTopCard()
                    }
                    else {
                        self?.maximazeTopCard()
                    }
                })
            })
            .disposed(by: bag)
        
        [userImageView, groupLabel].forEach { v in
            v.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    guard
                        let this = self,
                        let group = this.userViewModel.group
                        else {
                            return
                    }
                    
                    this.handleNavigation(navigation: Navigation.group(group: group))
                })
                .disposed(by: bag)
        }

        updateTopCard()
        selectTab(tab: UserTab.chat)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserPageViewController {
            vc.userViewModel = userViewModel
        }
        super.prepare(for: segue, sender: sender)
    }
    
    override func shouldObserveActiveGroup() -> Bool {
        return userViewModel.isMyUser
    }
    
    private func selectTab(tab: UserTab) {
        switch tab {
        case .groups:
            groupsButton.isSelected = true
            chatButton.isSelected = false
            placesButton.isSelected = false
        case .chat:
            groupsButton.isSelected = false
            chatButton.isSelected = true
            placesButton.isSelected = false
        case .places:
            groupsButton.isSelected = false
            chatButton.isSelected = false
            placesButton.isSelected = true
        }
        
        userViewModel.tabSelected(tab: tab)
    }
    
    private func updateTopCard() {
        let user = userViewModel.user
        let group = userViewModel.group
        
        userImageView.loadUserImage(image: nil, user: user, activeGroup: group, width: 2.0)
        userLabel.text = user.username
        groupLabel.text = group?.name
    }
    
    private func maximazeTopCard() {
        UIView.animate(withDuration: topCardHeightAnimDuration, animations: {
            self.topCardHeightConstraint.constant = self.topCardDefHeight
            self.updateTopCardViews(isHidden: false)
            self.view.layoutIfNeeded()
        })
    }
    
    private func minimizeTopCard() {
        UIView.animate(withDuration: topCardHeightAnimDuration, animations: {
            self.topCardHeightConstraint.constant = self.topCardMinHeight
            self.updateTopCardViews(isHidden: true)
            self.view.layoutIfNeeded()
        })
    }
    
    private func updateTopCardViews(isHidden: Bool) {
        [userLabel, userImageView, groupLabel].forEach {
            $0?.alpha = isHidden ? 0.0 : 1.0
        }
    }
    
    override func dotsClick() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: Words.blockUser.localized, style: .default, handler: { [weak self] _ in
            self?.userViewModel.blockUser()
        }))
        
        alert.addAction(UIAlertAction.init(title: Words.cancel.localized, style: .cancel, handler: nil))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            alert.popoverPresentationController?.permittedArrowDirections = []
        }
        
        present(alert, animated: true, completion: nil)
    }
}
