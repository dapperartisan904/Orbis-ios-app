//
//  MapViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import RxSwift

class MapViewController : OrbisViewController {
    
    @IBOutlet weak var mapView: OrbisMapView!
    @IBOutlet weak var checkInButton: RoundedButton!
    @IBOutlet weak var mapButtonsView: MapButtonsView!
    @IBOutlet weak var linearProgressBar: LinearProgressBar!
    
    private let mapViewModel = MapViewModel.instance()
    private let homeViewModel = HomeViewModel.instance()
    
    private var mapViewCenter: CLLocationCoordinate2D?
    private var locationDisposable: Disposable?
    private var locationListened = false
    
    private var drawCircleDisposables = [String : Disposable]()
    
    // Key: placeKey Value: hashValue
    private var overlaysToBeFadeOutAndRemoved = [String : Int]()
    
    private var drawCirclesCounter = AtomicInteger<Int>(0)
    private var drawVisibleCirclesCounter = AtomicInteger<Int>(0)
    private var drawInvisibleCirclesCounter = AtomicInteger<Int>(0)
    
    private var prevZoomLevel: Int?
    private var circlesCount = 0
    
    private let minAltitude = 5000.0
    private var constrainingAltitude = false
    
    deinit {
        locationDisposable?.dispose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.gray
        
        mapView.isPitchEnabled = true
        mapView.isZoomEnabled = true
        mapView.delegate = self
        mapView.startReorderTimer()
        mapView.clickDelegate = self
        mapButtonsView.delegate = self

        refreshCheckInButton(activeGroup: UserDefaultsRepository.instance().getActiveGroup())
        
        checkInButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.showViewController(withInfo: ViewControllerInfo.checkIn)
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
                
                this.locationDisposable?.dispose()
                this.locationDisposable = nil
                
                if !this.locationListened {
                    this.locationListened = true
                    this.centerMapOnLocation(location: location.toCLLocation(), distance: mapInitialDistance)
                }
            })
        
        mapViewModel.drawCircleSubject
            .observeOn(MainScheduler.asyncInstance)
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                //print2("[MapDebug] observed drawCircleSubject")
                
                guard let this = self else { return }
                let items = this.mapViewModel.consumePendingCircleDraws()
                
                for item in items {
                    let (circle, animation) = item
                    let visible = item.0.finalSize > 0.0
                    let delay: Double
                    
                    if visible {
                        delay = this.drawVisibleCirclesCounter.get().double * 0.15
                    }
                    else {
                        delay = this.drawInvisibleCirclesCounter.get().double * 0.5
                    }
                    
                    this.incrementDrawCirclesCounter(visible: visible)
                    this.drawCircle(circle: circle, initialAnimation: animation, delaySeconds: delay)
                }
            })
            .disposed(by: bag)

        mapViewModel.applyPlaceChangesSubject
            .subscribe(onNext: { [weak self] (value: Bool) in
                if value {
                    self?.applyPlaceChanges()
                }
            })
            .disposed(by: bag)
        
        //Place.debugOpacities()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapView.startReorderTimer()
        
        guard
            let checkInResponse = PresenceEventViewModel.instance().consumeCheckInResponse(),
            let place = checkInResponse.place
        else {
            return
        }
    
        applyCheckIn(checkInResponse: checkInResponse, place: place)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mapView.stopReorderTimer()
    }
    
    override func onActiveGroupChanged(prevGroup: Group?, newGroup: Group?) {
        refreshCheckInButton(activeGroup: newGroup)
    }

    private func refreshCheckInButton(activeGroup: Group?) {
        let buttonColor = activeGroup == nil ? UIColor.white : groupSolidColor(group: activeGroup!)
        checkInButton.backgroundColor = buttonColor
        
        let color = groupColorIsLight(group: activeGroup) ? UIColor.darkGray : UIColor.white
        checkInButton.setImage(UIImage(named: "baseline_location_on_white_48pt")?.filled(withColor: color), for: .normal)
    }
    
    private func onMapCenterChanged(center: CLLocationCoordinate2D) {
        if locationListened {
            mapViewCenter = center
            mapViewModel.onMapCenterChanged(center: Coordinates(coordinate2D: center))
            
            let currentZoomLevel = mapView.currentZoomLevel
            if prevZoomLevel != currentZoomLevel {
                print2("Zoom level changed: Prev - \(prevZoomLevel ?? 0) Current - \(currentZoomLevel)")
                prevZoomLevel = currentZoomLevel
                mapView.updateOpacity(zoomIndex: zoomIndex())
            }
        }
    }
    
    private func centerMapOnLocation(location: CLLocation, distance: CLLocationDistance) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: distance, longitudinalMeters: distance)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    private func getOverlay(placeKey: String?) -> CircleOverlay? {
        return mapView.overlays.first(where: { (overlay: MKOverlay) -> Bool in
            guard let co = overlay as? CircleOverlay else {
                return false
            }
            return co.circle.place.key == placeKey
        }) as? CircleOverlay
    }
    
    private func getOverlayToBeFadeOutAndRemoved(placeKey: String?, removeFromDictionary: Bool) -> CircleOverlay? {
        guard let placeKey = placeKey else {
            return nil
        }
        
        let hashValue = overlaysToBeFadeOutAndRemoved[placeKey]
        let overlay =  mapView.overlays.first(where: { (overlay: MKOverlay) -> Bool in
            guard let co = overlay as? CircleOverlay else {
                return false
            }
            return co.hashValue == hashValue
        }) as? CircleOverlay
        
        if removeFromDictionary {
            overlaysToBeFadeOutAndRemoved.removeValue(forKey: placeKey)
        }
        
        return overlay
    }
    
    private func drawCircle(circle: OrbisCircle, initialAnimation: CircleAnimation, delaySeconds: Double? = nil) {
        if circle.finalSize == 0.0 {
            print2("[MapDebug] Warning: drawing a circle with size of zero")
        }
        
        //print2("[MapDebug] drawCircle delay: \(delaySeconds ?? 0) \(circle.place.key ?? "") \(circle.place.name ?? "") size: \(circle.finalSize)")
        
        circlesCount += 1
        let overlay = CircleOverlay(circle: circle, initialAnimation: initialAnimation, indexOnMapView: circlesCount)
        
        if let delaySeconds = delaySeconds {
            let visible = circle.finalSize > 0.0
            
            Single.just(0)
                .observeOn(MainScheduler.asyncInstance)
                .delaySubscription(delaySeconds, scheduler: MainScheduler.asyncInstance)
                .subscribe(onSuccess: { [weak self] _ in
                    self?.addOverlay(overlay: overlay)
                    self?.decrementDrawCirclesCounter(visible: visible)
                    //print2("[MapDebug] drawCircle after delay \(circle.place.key ?? "") \(circle.place.name ?? "")")
                }, onError: { [weak self] error in
                    print2("[MapDebug] drawCircle \(circle.place.key ?? "") error \(error)")
                    self?.decrementDrawCirclesCounter(visible: visible)
                })
                .disposed(by: bag)
        }
        else {
            addOverlay(overlay: overlay)
        }
    }
    
    private func addOverlay(overlay: CircleOverlay) {
        mapView.addOverlay(overlay)
    }
    
    private func applyPlaceChanges() {
        let changes = mapViewModel.getAndClearPendingPlaceChanges()
        changes.forEach { applyPlaceChange(change: $0.value) }
    }
    
    private func applyPlaceChange(change: PlaceChange) {
        print2("[MapDebug] applyPlaceChange begin \(change.debug())")
        
        guard let placeKey = change.placeKey else {
            print2("[MapDebug] applyPlaceChange early return. Missing placeKey")
            return
        }
        
        let overlay = getOverlay(placeKey: placeKey)
        
        if overlay == nil {
            guard let circle = mapViewModel.getCircle(placeKey: placeKey) else {
                print2("[MapDebug] applyPlaceChange early return [2]. Circle not founded")
                onApplyPlaceChangeFailed(placeKey: placeKey)
                return
            }
            
            print2("[MapDebug] applyPlaceChange early return [3]. Will draw circle")
            circle.finalSize = change.currentSize
            drawCircle(circle: circle, initialAnimation: (change.shouldSpin == true) ? .spin : .growAndfadeIn)
            return
        }
        
        guard let renderer = mapView.renderer(for: overlay!) as? CircleOverlayRenderer else {
            print2("[MapDebug] applyPlaceChange early return [4]. Renderer not found")
            onApplyPlaceChangeFailed(placeKey: placeKey)
            return
        }
        
        if renderer.animating {
            print2("[MapDebug] applyPlaceChange early return [5]. Renderer is animating")
            return
        }
        
        let groupChanged = change.dominantGroupKey != renderer.groupKey
        print2("[MapDebug] applyPlaceChange \(placeKey) groupChanged: \(groupChanged) [\(renderer.groupKey) ---> \(change.dominantGroupKey ?? "nil")]")
        
        if groupChanged {
            guard let circle = mapViewModel.getCircle(placeKey: placeKey) else {
                print2("[MapDebug] applyPlaceChange early return [5]. Circle not founded")
                onApplyPlaceChangeFailed(placeKey: placeKey)
                return
            }
            
            circle.finalSize = change.currentSize
            overlaysToBeFadeOutAndRemoved[placeKey] = overlay.hashValue
            
            print2("[MapDebug] applyPlaceChange. Will draw group change. Size: \(circle.currentSize) \(circle.finalSize)")
            drawCircle(circle: circle, initialAnimation: (change.shouldSpin == true) ? .spin : .growAndfadeIn)
        }
        else {
            let circle = renderer.circleOverlay().circle
            let alpha = Place.getOpacity(touchesCount: circle.touchesCount(), size: change.currentSize.double, zoomIndex: zoomIndex(), placeName: circle.place.name)
            print2("[MapDebug] applyPlaceChange. Will draw size change \(circle.place.name ?? "") Alpha: \(alpha)")
            renderer.animate(type: .changeSize, placeChange: change, targetAlpha: alpha)
        }
    }
    
    private func applyCheckIn(checkInResponse: HandlePresenceEventResponse, place: Place) {
        //print2("[MapDebug] applyCheckIn \(String(describing: place.key))")
        centerMapOnLocation(location: place.coordinates.toCLLocation(), distance: 3000)
        mapViewModel.updateCircle(placeKey: place.key, checkInResponse: checkInResponse)
        
        // TODO KINE: a delay will be required (or detection when center on place did finished)
        delay(ms: 1000, block: { [weak self] in
            self?.applyPlaceChange(change: checkInResponse.toPlaceChange())
        })
    }
    
    private func onApplyPlaceChangeFailed(placeKey: String) {
        let vm = PresenceEventViewModel.instance()
        if placeKey == vm.processingCheckInOfPlaceKey {
            vm.clearPlaceBeingProcessed()
        }
    }
    
    private func incrementDrawCirclesCounter(visible: Bool) {
        if visible {
            drawVisibleCirclesCounter += 1
        }
        else {
            drawInvisibleCirclesCounter += 1
        }

        drawCirclesCounter += 1
        refreshProgressBar()
    }
    
    private func decrementDrawCirclesCounter(visible: Bool) {
        if visible {
            drawVisibleCirclesCounter -= 1
        }
        else {
            drawInvisibleCirclesCounter -= 1
        }
        
        drawCirclesCounter -= 1
        refreshProgressBar()
    }
    
    private func refreshProgressBar() {
        let counter = drawVisibleCirclesCounter.get()
        if counter > 0 && linearProgressBar.isHidden {
            linearProgressBar.isHidden = false
            linearProgressBar.startAnimation()
        }
        else if counter <= 0 && !linearProgressBar.isHidden {
            linearProgressBar.isHidden = true
            linearProgressBar.stopAnimation()
        }
    }
}

extension MapViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        //print2("[MapDebug] renderer for overlay")
        
        if let co = overlay as? CircleOverlay {
            return CircleOverlayRenderer(overlay: co, delegate: self, zoomIndex: zoomIndex())
        }
        
        return MKOverlayRenderer()
    }

    /*
        This function is called when finger is released.
     */
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.camera.centerCoordinate
        let altitude = mapView.camera.altitude
        onMapCenterChanged(center: center)
        print2("[MapDebug] regionDidChangeAnimated \(center.latitude) \(center.longitude) altitude: \(altitude)")
        
        if altitude < minAltitude && !constrainingAltitude {
            constrainingAltitude = true
            mapView.camera.altitude = minAltitude
            constrainingAltitude = false
        }
    }
    
    /*
        This function is called when navigating throught map.
     */
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        //let center = mapView.camera.centerCoordinate
        //let altitude = mapView.camera.altitude
        //print2("[MapDebug] mapViewDidChangeVisibleRegion \(center.latitude) \(center.longitude) altitude: \(altitude)")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //print2("[MapDebug] didSelect MKAnnotationView")
        //view.annotation?.
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print2("[MapDebug] didUpdate")
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        print2("[MapDebug] regionWillChangeAnimated")
    }

    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        print2("[MapDebug] mapViewWillStartLoadingMap")
    }
    
    func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
        print2("[MapDebug] mapViewWillStartRenderingMap")
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        print2("[MapDebug] didChange")
    }
}

extension MapViewController : CircleOverlayRendererDelegate {
    
    func onRendererReady(renderer: CircleOverlayRenderer) {
        let overlay = renderer.circleOverlay()
        //print2("[MapDebug] onRendererReady placeKey: \(String(describing: overlay.circle.place.key)) initialAnimation: \(overlay.initialAnimation)")
        
        if overlay.initialAnimation == .growAndfadeIn {
            guard
                let oldOverlay = getOverlayToBeFadeOutAndRemoved(placeKey: overlay.circle.place.key, removeFromDictionary: true),
                let oldRenderer = mapView.renderer(for: oldOverlay) as? CircleOverlayRenderer
            else {
                //print2("[MapDebug] onRendererReady early return")
                return
            }
        
            oldRenderer.fadeOut()
        }
    }
    
    func onRendererFadedOut(renderer: CircleOverlayRenderer) {
        //print2("[MapDebug] onRendererFadeOut")
        mapView.removeOverlay(renderer.overlay)
    }
    
    func zoomIndex() -> Int {
        if prevZoomLevel == nil {
            prevZoomLevel = mapInitialZoom
        }
        
        mainAsync { [weak self] in
            if let currentZoomLevel = self?.mapView?.currentZoomLevel {
                self?.prevZoomLevel = currentZoomLevel
            }
        }
        
        return Place.zoomIndex(zoomLevel: prevZoomLevel!.double)
    }
}

extension MapViewController : CircleClickDelegate {

    func onClick(placeWrapper: PlaceWrapper) {
        handleNavigation(navigation: Navigation.place(placeWrapper: placeWrapper))
    }
    
}

extension MapViewController : MapButtonsDelegate {
    func myLocationClick() {
        guard let location = HelperRepository.instance().getLocation() else {
            return
        }
        //centerMapOnLocation(location: location.toCLLocation(), distance: mapInitialDistance)
        mapView.setCenterCoordinate(location.toCLLocationCoordinate2D(), withZoomLevel: mapInitialZoom, animated: true)
    }
    
    func zoomInClick() {
        mapView.zoomIn()
    }
    
    func zoomOutClick() {
        mapView.zoomOut()
    }
    
    func fullscreenClick(isMaximized: Bool) {
        print2("fullscreenClick isMaximized: \(isMaximized)")
        
        if isMaximized {
            homeViewModel.minimizeTopCardSubject.onNext(true)
        }
        else {
            homeViewModel.maximizeTopCardSubject.onNext(true)
        }
    }
}
