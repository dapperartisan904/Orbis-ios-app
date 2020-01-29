//
//  GroupsViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import SwifterSwift
import RxSwift

class GroupsViewController : OrbisViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var linearProgressBar: LinearProgressBar!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var createButton: BottomButton!
    
    private let groupsViewModel = GroupsViewModel()
    private let rolesViewModel = RolesViewModel.instance()
    private var activeGroup: Group?
    
    private var rolesVMDisposable: Disposable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelection = false
        tableView.rowHeight = 94.0
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.hideUndesiredSeparators()
        tableView.register(cell: Cells.group)
        tableView.dataSource = self
        
        createButton.setTitle(Words.createNewGroup.localized.uppercased(), for: .normal)
        searchTextField.delegate = self
        
        if groupsViewModel.queryIsReady {
            onTaskFinished()
        }
        else {
            onTaskStarted()
        }
        
        createButton.rx.tap
            .bind { [weak self] in
                guard let _ = UserDefaultsRepository.instance().getMyUser() else {
                    self?.handleNavigation(navigation: .register())
                    return
                }
                
                self?.handleNavigation(navigation: .createGroup())
            }
            .disposed(by: bag)
        
        groupsViewModel.tableOperationsSubject
            .subscribe(onNext: { [weak self] (operation: TableOperation) in
                self?.handleTableOperation(operation: operation, tableView: self?.tableView)
            })
            .disposed(by: bag)
        
        rolesViewModel.roleByGroupChangedSubject
            .subscribe(onNext: { [weak self] (groupKey: String) in
                guard
                    let this = self,
                    let index = this.groupsViewModel.indexOf(groupKey: groupKey)
                else {
                    return
                }
                
                this.tableView.beginUpdates()
                this.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                this.tableView.endUpdates()
            })
            .disposed(by: bag)
        
        observeDefaultSubject(subject: groupsViewModel.defaultSubject)
        configSearchField(searchField: searchTextField, delegate: groupsViewModel, searchString: Words.searchGroup)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        rolesVMDisposable = observeDefaultSubjectWithoutBag(subject: rolesViewModel.defaultSubject)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        rolesVMDisposable?.dispose()
        rolesVMDisposable = nil
    }
    
    override func onActiveGroupChanged(prevGroup: Group?, newGroup: Group?) {
        activeGroup = newGroup

        if !groupsViewModel.filteredGroups.isEmpty {
            var paths = [IndexPath]()
            for i in 0...groupsViewModel.filteredGroups.count - 1 {
                paths.append(IndexPath(row: i, section: 0))
            }
            
            tableView.beginUpdates()
            tableView.reloadRows(at: paths, with: .none)
            tableView.endUpdates()
        }
    }
    
    override func onTaskStarted() {
        //print2("[Groups] onTaskStarted")
        linearProgressBar.startAnimation()
        linearProgressBar.isHidden = false
    }
    
    override func onTaskFinished() {
        //print2("[Groups] onTaskFinished")
        linearProgressBar.stopAnimation()
        linearProgressBar.isHidden = true
    }
}

extension GroupsViewController : UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupsViewModel.filteredGroups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.group.rawValue, for: indexPath) as! GroupCell
        let group = groupsViewModel.filteredGroups[indexPath.row]
        let followStatus = rolesViewModel.followStatus(groupKey: group.key!)
        let (memberStatus, isActiveGroup) = rolesViewModel.memberStatus(groupKey: group.key!)
        
        cell.delegate = self
        cell.groupNameLabel.text = group.name
        cell.groupImageView.loadGroupImage(group: group)
        
        switch followStatus {
        case .active:
            cell.followActivityIndicatorView.stopAnimating()
            cell.followActivityIndicatorView.isHidden = true
            cell.followButton.isHidden = false
            cell.followButton.isSelected = true
        case .inactive:
            cell.followActivityIndicatorView.stopAnimating()
            cell.followActivityIndicatorView.isHidden = true
            cell.followButton.isHidden = false
            cell.followButton.isSelected = false
        case .undetermined:
            cell.followActivityIndicatorView.isHidden = false
            cell.followActivityIndicatorView.startAnimating()
            cell.followButton.isHidden = true
        }
        
        switch memberStatus {
        case .active:
            cell.mainActionIndicatorView.stopAnimating()
            cell.mainActionIndicatorView.isHidden = true
            cell.mainActionButton.isHidden = false
            cell.mainActionButton.isSelected = true
            cell.mainActionButton.paint(group: activeGroup)
            cell.mainActionButton.setTitle(isActiveGroup ? Words.leaveGroup.localized : Words.changeGroup.localized, for: .normal)
        case .inactive:
            cell.mainActionIndicatorView.stopAnimating()
            cell.mainActionIndicatorView.isHidden = true
            cell.mainActionButton.isHidden = false
            cell.mainActionButton.isSelected = false
            cell.mainActionButton.paint(group: nil)
            cell.mainActionButton.setTitle(Words.joinGroup.localized, for: .normal)
        case .undetermined:
            cell.mainActionIndicatorView.isHidden = false
            cell.mainActionIndicatorView.startAnimating()
            cell.mainActionButton.isHidden = true
        }
        
        if indexPath.row == self.tableView(tableView, numberOfRowsInSection: 0) - 1 {
            groupsViewModel.consumerNeedsMoreData()
        }
        
        return cell
    }
    
}

extension GroupsViewController : GroupCellDelegate {
    func followClick(cell: GroupCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
    
        let group = groupsViewModel.filteredGroups[indexPath.row]
        rolesViewModel.toggleFollowRole(groupKey: group.key!)
    }
    
    func mainActionClick(cell: GroupCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        let group = groupsViewModel.filteredGroups[indexPath.row]
        rolesViewModel.toggleMemberRole(group: group)
    }
    
    func groupClick(cell: GroupCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        let group = groupsViewModel.filteredGroups[indexPath.row]
        handleNavigation(navigation: Navigation.group(group: group))
    }
}

extension GroupsViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
}

