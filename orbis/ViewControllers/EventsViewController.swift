//
//  EventsViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 16/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class EventsViewController : OrbisViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    private var addButton: RoundedButton!
    private var addImageView: UIImageView!
    
    var viewModel: EventsViewModel!
    var placeViewModel: PlaceViewModel?
    
    private var monthFormatter: DateFormatter!
    private var dateFormatter: DateFormatter!
    private var timeFormatter: DateFormatter!
    
    private var expandedEvents = Set<String>()
    
    private let activeGroup = UserDefaultsRepository.instance().getActiveGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.none
        
        timeFormatter = DateFormatter()
        timeFormatter.dateStyle = DateFormatter.Style.none
        timeFormatter.timeStyle = DateFormatter.Style.short
        
        tableView.hideUndesiredSeparators()
        tableView.register(cell: Cells.event)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.delegate = self
        tableView.dataSource = self
        
        indicatorView.isHidden = true
        
        if placeViewModel != nil {
            createAddButton()
        }
        
        observeDefaultSubject(subject: viewModel.defaulSubject)
        observeTableOperation()
        observePointsData()
    }
    
    override func onTaskStarted() {
        print2("EVC: onTaskStarted")
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    
    override func onTaskFinished() {
        print2("EVC: onTaskFinished")
        indicatorView.stopAnimating()
        indicatorView.isHidden = true
        tableView.reloadData()
    }
    
    override func onTaskFailed() {
        print2("EVC: onTaskSFailed")
        indicatorView.stopAnimating()
        indicatorView.isHidden = true
    }
    
    private func observeTableOperation() {
        viewModel.tableOperationSubject
            .subscribe(onNext: { [weak self] operation in
                self?.handleTableOperation(operation: operation, tableView: self?.tableView)
            })
            .disposed(by: bag)
    }
    
    private func observePointsData() {
        placeViewModel?.pointsLoadedSubject
            .subscribe(onNext: { [weak self] _ in
                self?.paintAddButton(group: self?.placeViewModel?.getDominatingGroup())
            })
            .disposed(by: bag)
    }
    
    private func createAddButton() {
        let bigSize: CGFloat = 60
        
        addButton = RoundedButton()
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.clipsToBounds = false
        addButton.shadowColor = UIColor.black
        addButton.shadowRadius = 2.0
        addButton.shadowOpacity = 0.7
        addButton.shadowOffset = CGSize(width: 0, height: 2)
        addButton.setImage(nil, for: .normal)
        addButton.backgroundColor = UIColor.red
        
        addImageView = UIImageView()
        addImageView.translatesAutoresizingMaskIntoConstraints = false
        addImageView.contentMode = .scaleAspectFit
        addImageView.image = UIImage(named: "baseline_add_black_48pt")?.template
            .withAlignmentRectInsets(UIEdgeInsets(inset: -12))
        
        view.addSubview(addButton)
        addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16).isActive = true
        addButton.widthAnchor.constraint(equalToConstant: bigSize).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: bigSize).isActive = true
        
        view.addSubview(addImageView)
        addImageView.centerXAnchor.constraint(equalTo: addButton.centerXAnchor).isActive = true
        addImageView.centerYAnchor.constraint(equalTo: addButton.centerYAnchor).isActive = true
        addImageView.widthAnchor.constraint(equalToConstant: bigSize).isActive = true
        addImageView.heightAnchor.constraint(equalToConstant: bigSize).isActive = true
        
        paintAddButton(group: placeViewModel?.getDominatingGroup())
        
        addButton.rx.tap
            .bind { [weak self] in
                guard let place = self?.viewModel.place else { return }
                self?.handleNavigation(navigation: Navigation.createEvent(viewModel: CreateEventViewModel(place: place, event: nil)))
            }
            .disposed(by: bag)
    }
    
    private func paintAddButton(group: Group?) {
        let darkImage = group == nil || textColorShouldBeDark(colorIndex: group!.colorIndex!)
        let tintColor = darkImage ? UIColor.black : UIColor.white
        addButton.backgroundColor = groupSolidColor(group: group, defaultColor: UIColor.white)
        addImageView.tintColor = tintColor
    }
}

extension EventsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withCellType: Cells.event, for: indexPath) as! EventCell
        let (event, group, place, attendancesCount) = viewModel.getData(index: indexPath.row)
        let attendanceStatus = viewModel.myAttendanceStatus(event: event)
        
        cell.delegate = self
        cell.eventNameLabel.text = event.title
        cell.placeNameLabel.text = place?.name
        
        if let dateTimestamp = event.dateTimestamp {
            let date = Date(timeIntervalSince1970: Double(dateTimestamp / 1000))
            cell.dayLabel.text = date.day.string
            cell.monthLabel.text = date.monthName()
            
            var dateStr = ""
            if let timeTimestamp = event.timeTimestamp {
                let timeDate = Date(timeIntervalSince1970: Double(timeTimestamp / 1000))
                dateStr = timeFormatter.string(from: timeDate) + " - "
            }
            
            dateStr += dateFormatter.string(from: date)
            cell.dateLabel.text = dateStr
        }
        
        cell.groupImageView.loadGroupImage(group: group)
        cell.groupNameLabel.text = group?.name
        cell.placeNameLabel2.text = place?.name
        cell.descLabel.text = event.details
        cell.linkLabel.text = event.link
        cell.addressLabel.text = place?.address ?? place?.name
        cell.presentLabel.text = Words.present.localized
        cell.confirmedLabel.text = "\(Words.confirmed.localized) \(attendancesCount)"
        cell.usersConfirmedLabel.text = Words.usersConfirmed.localized
        cell.attendButton.bind(status: attendanceStatus, group: activeGroup, indicatorView: cell.attendIndicatorView)
        
        if attendanceStatus == .attending {
            cell.bgView.backgroundColor = lightBlueColor()
        }
        else {
            cell.bgView.backgroundColor = UIColor.white
        }
        
        if expandedEvents.contains(event.postKey) {
            cell.expandButton.setImage(UIImage(named: "minus"), for: .normal)
        }
        else {
            cell.expandButton.setImage(UIImage(named: "plus"), for: .normal)
        }
        
        if let timeTimestamp = event.timeTimestamp {
            let timeDate = Date(timeIntervalSince1970: Double(timeTimestamp / 1000))
            cell.timeLabel.text = timeFormatter.string(from: timeDate)
        }
        else {
            cell.timeLabel.text = nil
        }
        
        if let dateTimestamp = event.dateTimestamp {
            let date = Date(timeIntervalSince1970: Double(dateTimestamp / 1000))
            cell.dateLabel2.text = dateFormatter.string(from: date)
        }
        else {
            cell.dateLabel2.text = nil
        }
        
        cell.noUsersView.text = Words.noUsersConfirmed.localized
        
        switch viewModel.additionalDataStatus(event: event) {
        case .taskStarted:
            cell.usersIndicatorView.isHidden = false
            cell.usersIndicatorView.startAnimating()
            cell.usersErrorView.isHidden = true
            cell.noUsersView.isHidden = true
            cell.usersStackView.isHidden = true
        
        case .taskFinished:
            cell.usersIndicatorView.stopAnimating()
            cell.usersIndicatorView.isHidden = true
            cell.usersErrorView.isHidden = true
            if attendancesCount == 0 {
                cell.usersStackView.isHidden = true
                cell.noUsersView.isHidden = false
            }
            else {
                cell.usersStackView.isHidden = false
                cell.noUsersView.isHidden = true
            }
        
        case .taskFailed:
            cell.usersIndicatorView.stopAnimating()
            cell.usersIndicatorView.isHidden = true
            cell.usersErrorView.isHidden = false
            cell.noUsersView.isHidden = true
            cell.usersStackView.isHidden = true
        
        default:
            break
        }

        cell.seeMoreButton.setTitle(Words.seeMore.localized, for: .normal)
        cell.editButton.setTitle(Words.editEvent.localized, for: .normal)
        
        let usersData = viewModel.getUsersOfAttendances(event: event)
        for i in 0...usersData.endIndex - 1 {
            showUser(cell: cell, index: i, user: usersData[i]?.0, group: usersData[i]?.1)
        }
        
        cell.editButton.isHidden = !viewModel.canEdit(event: event)
        cell.seeMoreButton.isHidden = viewModel.attendancesCount(event: event) <= 3
        
        return cell
    }
    
    private func showUser(cell: EventCell, index: Int, user: OrbisUser?, group: Group?) {
        let (imageView, label) = cell.getUserViews(index: index)
        
        guard let user = user else {
            imageView.isHidden = true
            label.isHidden = true
            return
        }
    
        label.isHidden = false
        label.text = user.username
        imageView.isHidden = false
        imageView.loadUserImage(user: user, activeGroup: group)
    }
}

extension EventsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let (event, _, _, attendancesCount) = viewModel.getData(index: indexPath.row)
        if expandedEvents.contains(event.postKey) {
            let hasUsers = attendancesCount > 0
            let hasButtons = viewModel.canEdit(event: event) || attendancesCount > 3
            
            if hasButtons {
                return 534.0
            }
            else if !hasButtons && hasUsers {
                return 470.0
            }
            else {
                return 316.0
            }
        }
        else {
            return 138.0
        }
    }
}

extension EventsViewController : EventCellDelegate {

    func expandClick(cell: EventCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let (event, _, _, _) = viewModel.getData(index: indexPath.row)
        
        if expandedEvents.contains(event.postKey) {
            expandedEvents.remove(event.postKey)
        }
        else {
            expandedEvents.insert(event.postKey)
            viewModel.loadAdditionalDataIfNeeded(event: event)
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func attendClick(cell: EventCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        viewModel.toggleAttendanceStatus(index: indexPath.row)
    }
    
    func seeMoreClick(cell: EventCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let (event, _, _, _) = viewModel.getData(index: indexPath.row)
        handleNavigation(navigation: Navigation.attendances(viewModel: AttendancesViewModel(event: event)))
    }
    
    func editClick(cell: EventCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let (event, _, place, _) = viewModel.getData(index: indexPath.row)
        guard let p = place else { return }
        handleNavigation(navigation: Navigation.createEvent(viewModel: CreateEventViewModel(place: p, event: event)))
    }
    
    func linkClick(cell: EventCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let (event, _, _, _) = viewModel.getData(index: indexPath.row)
        
        guard var link = event.link else { return }
        
        if !link.hasPrefix("http") && !link.hasPrefix("www") {
            link = "http://" + link
        }
        
        guard let url = URL(string: link) else { return }
        UIApplication.shared.open(url, options: [:])
    }
    
    func groupClick(cell: EventCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let (_, group, _, _) = viewModel.getData(index: indexPath.row)
        if let g = group {
            handleNavigation(navigation: Navigation.group(group: g))
        }
    }
    
    func placeClick(cell: EventCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let (_, _, place, _) = viewModel.getData(index: indexPath.row)
        if let p = place {
            handleNavigation(navigation: Navigation.place(placeWrapper: PlaceWrapper(place: p, group: nil)))
        }
    }
    
    func addressClick(cell: EventCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let (_, _, place, _) = viewModel.getData(index: indexPath.row)
        guard let p = place else { return }
        openMapsWithDirections(name: p.name, coordinates: p.coordinates.toCLLocationCoordinate2D())
    }
    
    func userClick(cell: EventCell, index: Int) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let (event, _, _, _) = viewModel.getData(index: indexPath.row)
        guard let user = viewModel.getUsersOfAttendances(event: event)[index] else { return }
        handleNavigation(navigation: Navigation.user(user: user.0))
    }
}
