//
//  UserPlacesViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 26/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class UserPlacesViewController : OrbisViewController, UserChildController {
    
    @IBOutlet weak var switchView: UISwitch!
    @IBOutlet weak var publicLabel: UILabel!
    @IBOutlet weak var privateLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var lockView: UIImageView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    var userViewModel: UserViewModel!
    private let rolesViewModel = RolesViewModel.instance()
    
    private lazy var upViewModel: UserPlacesViewModel = { [unowned self] in
        return UserPlacesViewModel(userViewModel: userViewModel)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !userViewModel.isMyUser {
            topConstraint.constant = 0
        }
        
        privateLabel.text = Words.privateWord.localized
        publicLabel.text = Words.publicWord.localized
        switchView.isOn = !(userViewModel.user.placesArePublic ?? true)
        
        tableView.allowsSelection = false
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.rowHeight = 100.0
        tableView.hideUndesiredSeparators()
        tableView.register(cell: Cells.userPlace)
        tableView.dataSource = self
        
        switchView.rx.value.bind { [weak self] isOn in
            self?.userViewModel.savePlacesArePublic(value: !isOn)
        }
        .disposed(by: bag)
        
        upViewModel.lockSubject
            .subscribe(onNext: { [weak self] locked in
                if locked {
                    self?.lockView.isHidden = false
                    self?.indicatorView.stopAnimating()
                }
            })
            .disposed(by: bag)
        
        rolesViewModel.roleByPlaceChangedSubject
            .subscribe(onNext: { [weak self] (placeKey: String) in
                guard
                    let this = self,
                    let index = this.upViewModel.index(of: placeKey)
                else {
                    return
                }
                
                this.tableView.beginUpdates()
                this.tableView.reloadRows(at: [index.toIndexPath()], with: .none)
                this.tableView.endUpdates()
            })
            .disposed(by: bag)
        
        observeDefaultSubject(subject: upViewModel.defaultSubject)
    }
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
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
    
}

extension UserPlacesViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return upViewModel.placeWrappers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withCellType: Cells.userPlace, for: indexPath) as! UserPlaceCell
        let (place, group, event) = upViewModel.getData(indexPath: indexPath)
        
        cell.delegate = self
        cell.groupImageView.loadGroupImage(group: group)
        cell.placeLabel.text = place.name
        cell.followButton.paint(group: userViewModel.group)
        cell.followButton.bindStatus(status: rolesViewModel.followStatus(placeKey: place.key), indicator: cell.followIndicatorView)
        
        if let t = event?.validTimestamp {
            let date = Date(timeIntervalSince1970: TimeInterval(t/1000))
            cell.dateLabel.text = date.dateString(ofStyle: .medium) + " | " + date.timeString(ofStyle: .short)
        }
        else {
            cell.dateLabel.text = nil
        }
        
        return cell
    }
}

extension UserPlacesViewController : UserPlaceCellDelegate {
    func placeClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let ip = tableView.indexPath(for: cell)
        else {
            return
        }
        
        handleNavigation(navigation: Navigation.place(placeWrapper: upViewModel.placeWrappers[ip.row]))
    }
    
    func groupClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let ip = tableView.indexPath(for: cell),
            let group = upViewModel.placeWrappers[ip.row].group
        else {
            return
        }
        
        handleNavigation(navigation: Navigation.group(group: group))
    }
    
    func followClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let ip = tableView.indexPath(for: cell)
        else {
            return
        }
        
        rolesViewModel.toggleFollowRole(placeKey: upViewModel.placeWrappers[ip.row].place.key)
    }
}
