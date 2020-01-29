//
//  CheckInViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxGesture

class CheckInViewController : OrbisViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var linearProgressBar: LinearProgressBar!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var toolbar: DefaultToolbar!
    @IBOutlet weak var createPlaceButton: BottomButton!
    
    private let placesViewModel = PlacesViewModel()
    private let presenceEventViewModel = PresenceEventViewModel.instance()
    private let rolesViewModel = RolesViewModel.instance()
    private var didLayoutSubviews = false
    
    private lazy var createTemporaryPlaceViewModel: CreateTemporaryPlaceViewModel = { [unowned self] in
        return CreateTemporaryPlaceViewModel()
    }()
    
    private var activeGroup: Group?

    override func viewDidLoad() {
        super.viewDidLoad()

        toolbar.delegate = self

        tableView.rowHeight = 100
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.allowsSelection = false
        tableView.hideUndesiredSeparators()
        tableView.register(cell: Cells.place)
        tableView.dataSource = self
        tableView.delegate = self
        
        createPlaceButton.setTitle(Words.createPlace.localized, for: .normal)

        if placesViewModel.queryIsReady {
            onTaskFinished()
        }
        else {
            onTaskStarted()
        }
        
        placesViewModel.tableOperationsSubject
            .subscribe(
                onNext: { [weak self] (tableOperation: TableOperation) in
                    self?.handleTableOperation(operation: tableOperation, tableView: self?.tableView)
                }
            )
            .disposed(by: bag)
        
        presenceEventViewModel.tableOperationSubject
            .subscribe(
                onNext: { [weak self] (tableOperation: TableOperation) in
                    guard let this = self else { return }
                    
                    if let op = tableOperation as? TableOperation.UpdateOperation {
                        this.reloadRows(placeKeys: op.allKeys())
                    }
                }
            )
            .disposed(by: bag)
       
        rolesViewModel.roleByPlaceChangedSubject
            .subscribe(onNext: { [weak self] (placeKey: String) in
                guard
                    let this = self,
                    let indexPath = this.placesViewModel.indexPathOf(placeKey: placeKey)
                else {
                    return
                }
                
                this.tableView.beginUpdates()
                this.tableView.reloadRows(at: [indexPath], with: .none)
                this.tableView.endUpdates()
            })
            .disposed(by: bag)
        
        createPlaceButton.rx.tap
            .bind { [weak self] in
                guard let _ = UserDefaultsRepository.instance().getMyUser() else {
                    self?.handleNavigation(navigation: .register())
                    return
                }
                
                self?.showViewController(withInfo: ViewControllerInfo.createPlaceStepOne)
            }
            .disposed(by: bag)
        
        observeDefaultSubject(subject: placesViewModel.defaultSubject)
        observeDefaultSubject(subject: presenceEventViewModel.defaultSubject)
        observeCreateTmpPlaceSubject()
        configSearchField(searchField: searchTextField, delegate: placesViewModel, searchString: Words.searchPlace)
        
        print2("[CheckIn VC] processingCheckIn: \(presenceEventViewModel.processingCheckInOfPlaceKey ?? "")")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didLayoutSubviews {
            linearProgressBar.heightForLinearBar = 5.0
            linearProgressBar.widthForLinearBar = cardView.bounds.width
        
            didLayoutSubviews = true
            refreshProgressBar()
        }
    }
    
    override func onActiveGroupChanged(prevGroup: Group?, newGroup: Group?) {
        super.onActiveGroupChanged(prevGroup: prevGroup, newGroup: newGroup)
        activeGroup = newGroup
        tableView.reloadData()
    }
    
    // Refers to load places
    override func onTaskStarted() {
        refreshProgressBar()
    }
    
    // Refers to load places
    override func onTaskFinished() {
        refreshProgressBar()
    }
    
    override func onTaskStatusChanged(status: TaskStatus) {
        refreshProgressBar()
    }
    
    private func refreshProgressBar() {
        if !didLayoutSubviews {
            return
        }
        
        if placesViewModel.isLoading() {
            linearProgressBar.startAnimation()
        }
        else {
            linearProgressBar.stopAnimation()
        }
    }
    
    func reloadRows(placeKeys: [String]) {
        if placeKeys.isEmpty {
            return
        }
        
        var paths = [IndexPath]()
        
        placeKeys.forEach { key in
            if let indexPath = placesViewModel.indexPathOf(placeKey: key) {
                paths.append(indexPath)
            }
        }
        
        if !paths.isEmpty {
            tableView.beginUpdates()
            tableView.reloadRows(at: paths, with: .none)
            tableView.endUpdates()
        }
    }
    
    private func observeCreateTmpPlaceSubject() {
        createTemporaryPlaceViewModel.mainSubject
            .subscribe({ [weak self] tableOperation in
                self?.tableView.reloadRows(indexes: 0)
            })
            .disposed(by: bag)
        
        createTemporaryPlaceViewModel.errorSubject
            .subscribe(onNext: { [weak self] error in
                self?.tableView.reloadRows(indexes: 0)
                self?.handleAny(value: error)
            })
            .disposed(by: bag)
    }
}

extension CheckInViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return OrbisGPSLocation.instance().coordinates == nil ? 0 : 1
        }
        else {
            return placesViewModel.filteredWrappers.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return indexPath.section == 0 ? gpsLocationCell(indexPath: indexPath) : placeCell(indexPath: indexPath)
    }
    
    private func gpsLocationCell(indexPath: IndexPath) -> PlaceCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.place.rawValue, for: indexPath) as! PlaceCell
        let gpsLocation = OrbisGPSLocation.instance()
        let status = gpsLocation.status

        cell.delegate = self
        cell.placeImageView.image = UIImage(named: "gps_location")
        cell.placeImageView.isHidden = false
        cell.placeStrokeImageView.isHidden = true
        cell.followButton.isHidden = true
        cell.groupImageView.isHidden = true
        cell.nameLabel.text = gpsLocation.name
        cell.followActivityIndicatorView.isHidden = true
        
        switch status {        
        case .processing:
            cell.mainActionButton.isHidden = true
            cell.mainActionIndicatorView.isHidden = false
            cell.mainActionIndicatorView.startAnimating()
        
        default:
            cell.mainActionButton.isHidden = false
            cell.mainActionButton.bindPresenceEvent(nextEvent: .checkIn, group: nil)
            cell.mainActionIndicatorView.isHidden = true
        }
        
        return cell
    }
    
    private func placeCell(indexPath: IndexPath) -> PlaceCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.place.rawValue, for: indexPath) as! PlaceCell
        let wrapper = placesViewModel.filteredWrappers[indexPath.row]
        let nextEvent = presenceEventViewModel.nextPresenceEventType(place: wrapper.place)
        let followStatus = rolesViewModel.followStatus(placeKey: wrapper.place.key)
        
        cell.delegate = self
        cell.nameLabel.text = wrapper.place.name
        cell.mainActionButton.bindPresenceEvent(nextEvent: nextEvent, group: activeGroup, indicatorView: cell.mainActionIndicatorView)
        cell.followButton.paint(group: activeGroup)
        cell.followButton.bindStatus(status: followStatus, indicator: cell.followActivityIndicatorView)
        
        if let group = wrapper.group {
            cell.groupImageView.loadGroupImage(group: group)
            cell.groupImageView.isHidden = false
            cell.placeImageView.isHidden = true
            cell.placeStrokeImageView.isHidden = true
        }
        else {
            cell.placeImageView.loadPlaceImage(place: wrapper.place, activeGroup: activeGroup)
            cell.placeStrokeImageView.groupStroke(group: activeGroup)
            cell.groupImageView.isHidden = true
            cell.placeImageView.isHidden = false
            cell.placeStrokeImageView.isHidden = false
        }
        
        if indexPath.row == self.tableView(tableView, numberOfRowsInSection: 1) - 1 {
            placesViewModel.consumerNeedsMoreData()
        }
        
        cell.followButton.isHidden = true
        
        return cell
    }
}

extension CheckInViewController : UITableViewDelegate {

}

extension CheckInViewController : PlaceCellDelegate {
    func followClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let indexPath = tableView.indexPath(for: cell)
        else {
            return
        }

        let wrapper = placesViewModel.filteredWrappers[indexPath.row]
        rolesViewModel.toggleFollowRole(placeKey: wrapper.place.key)
    }   
    
    func mainActionClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let indexPath = tableView.indexPath(for: cell)
        else {
            return
        }
        
        if indexPath.section == 0 {
            createTemporaryPlaceViewModel.create()
        }
        else {
            let wrapper = placesViewModel.filteredWrappers[indexPath.row]
            presenceEventViewModel.savePresenceEvent(place: wrapper.place)
        }
    }
    
    func placeClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let indexPath = tableView.indexPath(for: cell)
        else {
            return
        }
        
        let wrapper = placesViewModel.filteredWrappers[indexPath.row]
        handleNavigation(navigation: Navigation.place(placeWrapper: wrapper))
    }
    
    func groupClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let indexPath = tableView.indexPath(for: cell)
        else {
            return
        }

        if let group = placesViewModel.filteredWrappers[indexPath.row].group {
            handleNavigation(navigation: Navigation.group(group: group))
        }
        else {
            placeClick(cell: cell)
        }
    }
}

