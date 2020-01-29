//
//  CreatePlaceStepTwo.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import RxSwift

class CreatePlaceStepTwoViewController : OrbisViewController {

    @IBOutlet weak var toolbar: TitleToolbar!
    @IBOutlet weak var mapView: OrbisMapView!
    @IBOutlet weak var targetView: UIImageView!
    @IBOutlet weak var placeIconView: UIImageView!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var mapButtonsView: MapButtonsView!
    
    var viewModel: CreatePlaceViewModel!
    
    private var locationListened = false
    private var locationDisposable: Disposable?
    private var alert: UIAlertController?
    
    deinit {
        locationDisposable?.dispose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        toolbar.delegate = self
        mapView.delegate = self
        mapButtonsView.delegate = self
        
        toolbar.label.text = Words.exactAddressOptional.localized
        createButton.setTitle(Words.createPlace.localized, for: .normal)
        indicatorView.isHidden = true
        
        targetView.image = UIImage(named: "target")?.template
        placeIconView.image = UIImage(named: viewModel.placeType?.rawValue ?? "")?.template
        
        if let group = viewModel.activeGroup {
            targetView.tintColor = groupStrokeColor(group: group)
            placeIconView.tintColor = groupSolidColor(group: group)
        }
        
        createButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                let location = Coordinates(coordinate2D: this.mapView.centerCoordinate)
                this.viewModel.createPlace(location: location)
            }
            .disposed(by: bag)
        
        locationDisposable = HelperRepository.instance().locationSubject
            .subscribe(onNext: { [weak self] (location: Coordinates?) in
                guard
                    let location = location,
                    let this = self
                else {
                    return
                }
                
                print2("CreatePlaceStepTwoViewController listened location")
                
                this.locationDisposable?.dispose()
                this.locationDisposable = nil
                
                if !this.locationListened {
                    this.locationListened = true
                    this.centerMapOnLocation(location: location.toCLLocation(), distance: mapInitialDistance)
                }
            })
        
        observeDefaultSubject(subject: viewModel.defaultSubject)
    }
    
    private func centerMapOnLocation(location: CLLocation, distance: CLLocationDistance) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: distance, longitudinalMeters: distance)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    private func onMapCenterChanged(center: CLLocationCoordinate2D) {
        if !locationListened {
            return
        }
    }
    
    private func showAddressAlert() {
        alert = showAlertWithTextField(
            title: Words.enterPlaceAddress.localized,
            placeholder: Words.typeHere.localized,
            leftButtonTitle: Words.cancel.localized,
            rightButtonTitle: Words.ok.localized,
            rightActionEnabled: true,
            textFieldDelegate: nil,
            rightBlock: { [weak self] text in
                self?.viewModel?.address = text
            }
        )
        
        alert?.textFields?.first?.text = viewModel?.address
    }
    
    override func toolbarTitleClick() {
        showAddressAlert()
    }
    
    override func onTaskStarted() {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    
    override func onTaskFinished() {
        indicatorView.stopAnimating()
        indicatorView.isHidden = true
        
        if PresenceEventViewModel.instance().hasCheckInResponse() {
            handleNavigation(navigation: Navigation.map())
        }
        else {
            handleNavigation(navigation: PopToViewController(type: CheckInViewController.self))
        }
    }
    
    override func onTaskFailed() {
        indicatorView.stopAnimating()
        indicatorView.isHidden = true
        showOkAlert(title: Words.error.localized, msg: Words.errorGeneric.localized)
    }
}

extension CreatePlaceStepTwoViewController : MKMapViewDelegate {

    /*
        This function is called when navigating throught map.
        Values are not totally updated. Could be a issue only on simulator.
     */
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.camera.centerCoordinate
        onMapCenterChanged(center: center)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print2("didUpdateUserLocation \(userLocation.coordinate)")
    }

}

extension CreatePlaceStepTwoViewController : MapButtonsDelegate {
    func myLocationClick() {
        guard let location = HelperRepository.instance().getLocation() else {
            return
        }
        centerMapOnLocation(location: location.toCLLocation(), distance: 3000)
    }
    
    func zoomInClick() {
        mapView.zoomIn()
    }
    
    func zoomOutClick() {
        mapView.zoomOut()
    }
    
    func fullscreenClick(isMaximized: Bool) {
        // Do nothing
    }
    
    func onSetup(view: MapButtonsView) {
        mapButtonsView.fullscreenButton.isHidden = true
    }
}
