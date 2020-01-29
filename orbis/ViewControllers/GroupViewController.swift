//
//  GroupViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 09/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

enum GroupTab : Int {
    case dominatedPlaces, feeds, events, members
}

protocol GroupChildController {
    var groupViewModel: GroupViewModel! { get set }
}

class GroupViewController : OrbisViewController {
    
    @IBOutlet weak var topCardView: CardView!
    @IBOutlet weak var bottomCardView: CardView!
    @IBOutlet weak var toolbar: DefaultToolbar!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var groupImageView: RoundedImageView!
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var mainActionButton: GroupButton!
    @IBOutlet weak var followButton: StarButton!
    @IBOutlet weak var mainActionIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var followIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var dominatedPlacesButton: UIButton!
    @IBOutlet weak var feedsButton: UIButton!
    @IBOutlet weak var eventsButton: UIButton!
    @IBOutlet weak var membersButton: UIButton!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var groupViewModel: GroupViewModel!
    
    private lazy var rolesViewModel = {
        return RolesViewModel.instance()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.delegate = self

        groupImageView.loadGroupImage(group: groupViewModel.group)
        groupLabel.text = groupViewModel.group.name
        descriptionLabel.text = groupViewModel.group.description
        dominatedPlacesButton.setImage(UIImage(named: "tab_place_inactive"), for: .normal)
        dominatedPlacesButton.setImage(UIImage(named: "tab_place_active"), for: .selected)
        feedsButton.setImage(UIImage(named: "tab_feeds_inactive"), for: .normal)
        feedsButton.setImage(UIImage(named: "tab_feeds_active"), for: .selected)
        eventsButton.setImage(UIImage(named: "tab_events_inactive"), for: .normal)
        eventsButton.setImage(UIImage(named: "tab_events_active"), for: .selected)
        membersButton.setImage(UIImage(named: "tab_members_inactive"), for: .normal)
        membersButton.setImage(UIImage(named: "tab_members_active"), for: .selected)
        dominatedPlacesButton.imageView?.contentMode = .scaleAspectFit
        feedsButton.imageView?.contentMode = .scaleAspectFit
        eventsButton.imageView?.contentMode = .scaleAspectFit
        membersButton.imageView?.contentMode = .scaleAspectFit
        
        stackView.tabsStackView()
        refreshButtons()
        paintBackground(group: groupViewModel.group)
        observeDefaultSubject(subject: rolesViewModel.defaultSubject, onlyIfVisible: true)
        
        mainActionButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.rolesViewModel.toggleMemberRole(group: this.groupViewModel.group)
            }
            .disposed(by: bag)
        
        followButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.rolesViewModel.toggleFollowRole(groupKey: this.groupViewModel.group.key!)
            }
            .disposed(by: bag)
        
        dominatedPlacesButton.rx.tap
            .bind { [weak self] in
                self?.selectTab(tab: .dominatedPlaces)
            }
            .disposed(by: bag)
        
        feedsButton.rx.tap
            .bind { [weak self] in
                self?.selectTab(tab: .feeds)
            }
            .disposed(by: bag)
        
        eventsButton.rx.tap
            .bind { [weak self] in
                self?.selectTab(tab: .events)
            }
            .disposed(by: bag)
        
        membersButton.rx.tap
            .bind { [weak self] in
                self?.selectTab(tab: .members)
            }
            .disposed(by: bag)
        
        groupImageView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.descriptionLabel.isHidden = false
                self?.containerView.isHidden = true
                self?.dominatedPlacesButton.isSelected = false
                self?.feedsButton.isSelected = false
                self?.eventsButton.isSelected = false
                self?.membersButton.isSelected = false
            })
            .disposed(by: bag)
        
        rolesViewModel.roleByGroupChangedSubject
            .subscribe(onNext: { [weak self] groupKey in
                guard
                    let this = self,
                    this.groupViewModel.group.key == groupKey
                else {
                    return
                }
                
                this.refreshButtons()
            })
            .disposed(by: bag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? GroupPageViewController {
            vc.groupViewModel = groupViewModel
        }
        super.prepare(for: segue, sender: sender)
    }

    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
    
    private func refreshButtons() {
        let memberStatus = rolesViewModel.memberStatus(groupKey: groupViewModel.group.key!).0
        let followStatus = rolesViewModel.followStatus(groupKey: groupViewModel.group.key!)
        mainActionButton.bind(memberStatus: memberStatus, group: groupViewModel.group, indicatorView: mainActionIndicatorView)
        followButton.bindStatus(status: followStatus, indicator: followIndicatorView)
    }
    
    private func selectTab(tab: GroupTab) {
        descriptionLabel.isHidden = true
        containerView.isHidden = false
        
        switch tab {
        case .dominatedPlaces:
            dominatedPlacesButton.isSelected = true
            feedsButton.isSelected = false
            eventsButton.isSelected = false
            membersButton.isSelected = false
        case .feeds:
            dominatedPlacesButton.isSelected = false
            feedsButton.isSelected = true
            eventsButton.isSelected = false
            membersButton.isSelected = false
        case .events:
            dominatedPlacesButton.isSelected = false
            feedsButton.isSelected = false
            eventsButton.isSelected = true
            membersButton.isSelected = false
        case .members:
            dominatedPlacesButton.isSelected = false
            feedsButton.isSelected = false
            eventsButton.isSelected = false
            membersButton.isSelected = true
        }
        
        groupViewModel.tabSelected(tab: tab)
    }
}
