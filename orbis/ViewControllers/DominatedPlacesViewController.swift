//
//  DominatedPlacesViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 25/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class DominatedPlacesViewController : OrbisViewController, GroupChildController {
    
    private let rolesViewModel = RolesViewModel.instance()
    private var dominatedPlacesViewModel: DominatedPlacesViewModel!
    
    var groupViewModel: GroupViewModel! {
        didSet {
            dominatedPlacesViewModel = DominatedPlacesViewModel(group: groupViewModel.group)
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.hideUndesiredSeparators()
        tableView.register(cell: Cells.dominatedPlace)
        tableView.rowHeight = 80.0
        tableView.allowsSelection = false
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.dataSource = self
        
        rolesViewModel.roleByPlaceChangedSubject
            .subscribe(onNext: { [weak self] (placeKey: String) in
                guard
                    let this = self,
                    let index = this.dominatedPlacesViewModel.index(of: placeKey)
                else {
                    return
                }
                
                this.tableView.beginUpdates()
                this.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                this.tableView.endUpdates()
            })
            .disposed(by: bag)
        
        observeDefaultSubject(subject: dominatedPlacesViewModel.defaulSubject)
    }

    override func onTaskStarted() {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    
    override func onTaskFinished() {
        indicatorView.stopAnimating()
        tableView.reloadData()
    }
    
    override func onTaskFailed() {
        indicatorView.stopAnimating()
    }

}

extension DominatedPlacesViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dominatedPlacesViewModel.places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withCellType: Cells.dominatedPlace, for: indexPath) as! DominatedPlaceCell
        let place = dominatedPlacesViewModel.places[indexPath.row]
        let followStatus = rolesViewModel.followStatus(placeKey: place.key)
        
        cell.delegate = self
        cell.placeLabel.text = place.name
        cell.placeImageView.loadPlaceImage(place: place, activeGroup: groupViewModel.group, inset: -12.0)
        cell.placeStrokeImageView.groupStroke(group: groupViewModel.group, width: 2.0)
        cell.followButton.paint(group: groupViewModel.group)
        cell.followButton.bindStatus(status: followStatus, indicator: cell.followActivityIndicatorView)
        
        return cell
    }

}

extension DominatedPlacesViewController : DominatedPlaceCellDelegate {
    func followClick(cell: UITableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }

        rolesViewModel.toggleFollowRole(placeKey: dominatedPlacesViewModel.places[indexPath.row].key)
    }
    
    func placeClick(cell: UITableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        let wrapper = PlaceWrapper(place: dominatedPlacesViewModel.places[indexPath.row], group: groupViewModel.group)
        handleNavigation(navigation: Navigation.place(placeWrapper: wrapper))
    }
}
