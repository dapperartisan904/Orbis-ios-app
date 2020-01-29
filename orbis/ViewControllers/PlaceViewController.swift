//
//  PlaceViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 09/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

enum PlaceTab : Int {
    case
        description,
        feeds,
        events,
        members
}

protocol PlaceChildController {
    var placeViewModel: PlaceViewModel! { get set }
}

class PlaceViewController : OrbisViewController {
    
    @IBOutlet weak var topCardView: CardView!
    @IBOutlet weak var bottomCardView: CardView!
    @IBOutlet weak var toolbar: DefaultToolbar!
    @IBOutlet weak var descriptionButton: UIButton!
    @IBOutlet weak var feedsButton: UIButton!
    @IBOutlet weak var eventsButton: UIButton!
    @IBOutlet weak var membersButton: UIButton!
    @IBOutlet weak var flagContainer: UIView!
    @IBOutlet weak var followButton: FollowPlaceButton!
    @IBOutlet weak var followIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var mainActionButton: GroupButton!
    @IBOutlet weak var mainActionIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var topCardIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    
    weak var flagView: FlagView!
    private weak var renameAlert: UIAlertController?
    private weak var reportAlert: UIAlertController?
    
    private let rolesViewModel = RolesViewModel.instance()
    private let presenceEventViewModel = PresenceEventViewModel.instance()
    var placeViewModel: PlaceViewModel!
    
    private lazy var reportViewModel: ReportViewModel = { [unowned self] in
        return ReportViewModel()
    }()
    
    override func performSegue(withIdentifier identifier: String, sender: Any?) {
        super.performSegue(withIdentifier: identifier, sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PlacePageViewController {
            vc.placeViewModel = placeViewModel
        }
        super.prepare(for: segue, sender: sender)
    }
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print2("PlaceViewController viewDidLoad")
        
        toolbar.delegate = self
        mainActionIndicatorView.isHidden = true
        followIndicatorView.isHidden = true
        updateVisibility(hide: true)
        flagView = FlagView.createAndAttachToContainer(container: flagContainer)
        placeNameLabel.text = placeViewModel.place.name
        stackView.tabsStackView()
        
        descriptionButton.setImage(UIImage.loadPlaceImage(place: placeViewModel.place, activeGroup: nil, colorHex: tabInactiveColor), for: .normal)
        descriptionButton.setImage(UIImage.loadPlaceImage(place: placeViewModel.place, activeGroup: nil, colorHex: tabActiveColor), for: .selected)
        feedsButton.setImage(UIImage(named: "tab_feeds_inactive"), for: .normal)
        feedsButton.setImage(UIImage(named: "tab_feeds_active"), for: .selected)
        eventsButton.setImage(UIImage(named: "tab_events_inactive"), for: .normal)
        eventsButton.setImage(UIImage(named: "tab_events_active"), for: .selected)
        membersButton.setImage(UIImage(named: "tab_members_inactive"), for: .normal)
        membersButton.setImage(UIImage(named: "tab_members_active"), for: .selected)
        descriptionButton.imageView?.contentMode = .scaleAspectFit
        feedsButton.imageView?.contentMode = .scaleAspectFit
        eventsButton.imageView?.contentMode = .scaleAspectFit
        membersButton.imageView?.contentMode = .scaleAspectFit
        
        placeNameLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.showMenu()
            })
            .disposed(by: bag)
        
        descriptionButton.rx.tap
            .bind { [weak self] in
                self?.selectTab(tab: .description)
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
        
        followButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                self?.rolesViewModel.toggleFollowRole(placeKey: this.placeViewModel.place.key)
            }
            .disposed(by: bag)
        
        mainActionButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.presenceEventViewModel.savePresenceEvent(place: this.placeViewModel.place, proceedToMap: false)
            }
            .disposed(by: bag)
        
        flagView.groupImageView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard
                    let this = self,
                    let group = this.placeViewModel.getDominatingGroup()
                else {
                    return
                }
                
                this.handleNavigation(navigation: Navigation.group(group: group))
            })
            .disposed(by: bag)
        
        rolesViewModel
            .roleByPlaceChangedSubject
            .subscribe(onNext: { [weak self] placeKey in
                guard let this = self else { return }
                if placeKey == this.placeViewModel.place.key {
                    self?.bindFollowButton()
                }
            })
            .disposed(by: bag)
        
        presenceEventViewModel
            .tableOperationSubject
            .subscribe(onNext: { [weak self] operation in
                guard
                    let this = self,
                    let op = operation as? TableOperation.UpdateOperation,
                    op.allKeys().contains(this.placeViewModel.place.key)
                else {
                    return
                }
                this.bindMainButton()
            })
            .disposed(by: bag)
        
        placeViewModel.pointsLoadedSubject
            .subscribe(onNext: { [weak self] loaded in
                if loaded {
                    self?.onPointsLoaded()
                }
            })
            .disposed(by: bag)
        
        observeDefaultSubject(subject: rolesViewModel.defaultSubject)
        observeDefaultSubject(subject: presenceEventViewModel.defaultSubject)
        
        selectTab(tab: .description)
    }
    
    private func updateVisibility(hide: Bool) {
        if hide {
            topCardIndicatorView.isHidden = false
            topCardIndicatorView.startAnimating()
        }
        else {
            topCardIndicatorView.stopAnimating()
            topCardIndicatorView.isHidden = true
        }
    
        [flagContainer, placeNameLabel, mainActionButton, followButton, stackView].forEach { v in
            v?.isHidden = hide
        }
    }
    
    private func onPointsLoaded() {
        let group = placeViewModel.getDominatingGroup()
        paintBackground(group: group)
        flagView.paint(group: group, place: placeViewModel.place)
        mainActionButton.paint(group: group)
        followButton.paint(group: group)
        bindFollowButton()
        bindMainButton()
        updateVisibility(hide: false)
    }
    
    private func bindFollowButton() {
        let status = rolesViewModel.followStatus(placeKey: placeViewModel.place.key)
        followButton.bindStatus(status: status)
        followIndicatorView.bindStatus(status: status)
    }
    
    private func bindMainButton() {
        var event = presenceEventViewModel.nextPresenceEventType(place: placeViewModel.place, ignoreProcessingPlaceKey: false)
        
        if event == .undetermined {
            let event2 = presenceEventViewModel.nextPresenceEventType(place: placeViewModel.place, ignoreProcessingPlaceKey: true)
            if event2 == .checkOut {
                event = .checkOut
            }
        }
        
        print2("bindMainButton \(event)")
        mainActionButton.bindPresenceEvent(nextEvent: event, group: placeViewModel.getDominatingGroup())
        mainActionIndicatorView.bindNextEvent(event: event)
    }
    
    private func selectTab(tab: PlaceTab) {
        switch tab {
        case .description:
            descriptionButton.isSelected = true
            feedsButton.isSelected = false
            eventsButton.isSelected = false
            membersButton.isSelected = false

        case .feeds:
            descriptionButton.isSelected = false
            feedsButton.isSelected = true
            eventsButton.isSelected = false
            membersButton.isSelected = false

        case .events:
            descriptionButton.isSelected = false
            feedsButton.isSelected = false
            eventsButton.isSelected = true
            membersButton.isSelected = false

        case .members:
            descriptionButton.isSelected = false
            feedsButton.isSelected = false
            eventsButton.isSelected = false
            membersButton.isSelected = true
        }
        
        placeViewModel.tabSelected(tab: tab)
    }
    
    private func showMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for option in PlaceMenuOptions.allCases {
            if option == .rename && !placeViewModel.canEdit() {
                continue
            }
            
            if option == .copyAddress && (placeViewModel.place.address ?? "").isEmpty {
                continue
            }
            
            alert.addAction(UIAlertAction(title: option.getWord().localized, style: .default, handler: { [weak self] _ in
                guard let this = self else { return }
                let place = this.placeViewModel.place
                
                switch option {
                case .report:
                    this.showReportAlert()
                    
                case .rename:
                    this.showRenameAlert()
                    
                case .copyAddress:
                    UIPasteboard.general.string = place.address
                    
                case .directions:
                    this.openMapsWithDirections(name: place.name, coordinates: place.coordinates.toCLLocationCoordinate2D())
                }
            }))
        }
        
        alert.addAction(UIAlertAction.init(title: Words.cancel.localized, style: .cancel, handler: nil))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            alert.popoverPresentationController?.permittedArrowDirections = []
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    private func showRenameAlert() {
        renameAlert = showAlertWithTextField(
            title: Words.enterPlaceName.localized,
            placeholder: Words.typeHere.localized,
            leftButtonTitle: Words.cancel.localized,
            rightButtonTitle: Words.ok.localized,
            rightActionEnabled: true,
            textFieldDelegate: nil,
            rightBlock: { [weak self] text in
                self?.placeViewModel.savePlaceName(text: text)
                self?.placeNameLabel.text = text
            }
        )
    }
    
    private func showReportAlert() {
        reportAlert = showAlertWithTextField(
            title: Words.enterReportMessage.localized,
            placeholder: Words.typeHere.localized,
            leftButtonTitle: Words.cancel.localized,
            rightButtonTitle: Words.ok.localized,
            rightActionEnabled: true,
            textFieldDelegate: nil,
            rightBlock: { [weak self] text in
                guard let this = self else { return }
                this.reportViewModel.saveReport(place: this.placeViewModel.place, message: text)
            }
        )
    }
}
