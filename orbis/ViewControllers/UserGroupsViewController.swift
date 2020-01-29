//
//  UserGroupsViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 26/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class UserGroupsViewController : OrbisViewController, UserChildController {
    
    @IBOutlet weak var switchView: UISwitch!
    @IBOutlet weak var publicLabel: UILabel!
    @IBOutlet weak var privateLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var lockView: UIImageView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    var userViewModel: UserViewModel!
    private var userGroupsViewModel: UserGroupsViewModel!
    private let rolesViewModel = RolesViewModel.instance()
    private var activeGroup: Group?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if !userViewModel.isMyUser {
            topConstraint.constant = 0
        }
        
        activeGroup = UserDefaultsRepository.instance().getActiveGroup()
        userGroupsViewModel = UserGroupsViewModel(userViewModel: userViewModel)
        observeDefaultSubject(subject: userGroupsViewModel.defaultSubject)
        
        tableView.allowsSelection = false
        tableView.rowHeight = 94.0
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.hideUndesiredSeparators()
        tableView.register(cell: Cells.group)
        tableView.dataSource = self
        
        privateLabel.text = Words.privateWord.localized
        publicLabel.text = Words.publicWord.localized
        switchView.isOn = !(userViewModel.user.groupsArePublic ?? true)
        
        switchView.rx.value.bind { [weak self] isOn in
            self?.userViewModel.saveGroupsArePublic(value: !isOn)
        }
        .disposed(by: bag)
        
        userGroupsViewModel.lockSubject
            .subscribe(onNext: { [weak self] locked in
                if locked {
                    self?.lockView.isHidden = false
                    self?.indicatorView.stopAnimating()
                }
            })
            .disposed(by: bag)
        
        rolesViewModel.roleByGroupChangedSubject
            .subscribe(onNext: { [weak self] (groupKey: String) in
                guard
                    let this = self,
                    let index = this.userGroupsViewModel.indexOf(groupKey: groupKey)
                else {
                    return
                }
                
                this.tableView.beginUpdates()
                this.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                this.tableView.endUpdates()
            })
            .disposed(by: bag)
    }
    
    override func onTaskStarted() {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    
    override func onTaskFinished() {
        tableView.reloadData()
        indicatorView.stopAnimating()
    }
    
    override func onTaskFailed() {
        indicatorView.stopAnimating()
    }
    
    override func onActiveGroupChanged(prevGroup: Group?, newGroup: Group?) {
        if newGroup?.key == activeGroup?.key {
            return
        }
        
        if userGroupsViewModel == nil {
            return
        }
        
        activeGroup = newGroup
        
        if !userGroupsViewModel.groups.isEmpty {
            var paths = [IndexPath]()
            for i in 0...userGroupsViewModel.groups.count - 1 {
                paths.append(IndexPath(row: i, section: 0))
            }
            
            tableView.beginUpdates()
            tableView.reloadRows(at: paths, with: .none)
            tableView.endUpdates()
        }
    }
}


extension UserGroupsViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userGroupsViewModel.groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.group.rawValue, for: indexPath) as! GroupCell
        let group = userGroupsViewModel.groups[indexPath.row]
        let followStatus = rolesViewModel.followStatus(groupKey: group.key!)
        let (memberStatus, isActiveGroup) = rolesViewModel.memberStatus(groupKey: group.key!)
        
        cell.delegate = self
        cell.groupNameLabel.text = group.name
        
        cell.followButton.imageView?.contentMode = .scaleAspectFit
        cell.followButton.setImage(UIImage(named: "ic_star_yellow_2"), for: .selected)
        
        cell.groupImageView.loadGroupImage(group: group)
        
        switch followStatus {
        case .active:
            cell.followActivityIndicatorView.isHidden = true
            cell.followButton.isHidden = false
            cell.followButton.isSelected = true
        case .inactive:
            cell.followActivityIndicatorView.isHidden = true
            cell.followButton.isHidden = false
            cell.followButton.isSelected = false
        case .undetermined:
            cell.followActivityIndicatorView.isHidden = false
            cell.followButton.isHidden = false
        }
        
        switch memberStatus {
        case .active:
            cell.mainActionIndicatorView.isHidden = true
            cell.mainActionButton.isHidden = false
            cell.mainActionButton.isSelected = true
            cell.mainActionButton.paint(group: activeGroup)
            cell.mainActionButton.setTitle(isActiveGroup ? Words.leaveGroup.localized : Words.changeGroup.localized, for: .normal)
        case .inactive:
            cell.mainActionIndicatorView.isHidden = true
            cell.mainActionButton.isHidden = false
            cell.mainActionButton.isSelected = false
            cell.mainActionButton.paint(group: nil)
            cell.mainActionButton.setTitle(Words.joinGroup.localized, for: .normal)
        case .undetermined:
            cell.mainActionIndicatorView.isHidden = false
            cell.mainActionButton.isHidden = true
        }
        
        return cell
    }
    
}

extension UserGroupsViewController : GroupCellDelegate {
    func followClick(cell: GroupCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        rolesViewModel.toggleFollowRole(groupKey: userGroupsViewModel.groups[indexPath.row].key!)
    }
    
    func mainActionClick(cell: GroupCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        let group = userGroupsViewModel.groups[indexPath.row]
        rolesViewModel.toggleMemberRole(group: group)
    }
    
    func groupClick(cell: GroupCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        let group = userGroupsViewModel.groups[indexPath.row]
        handleNavigation(navigation: Navigation.group(group: group))
    }
}
