//
//  MapViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 02/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import GeoFire
import RxFirebaseDatabase
import RxSwift

class MapViewModel : OrbisViewModel {
    
    override fileprivate init() { }
    
    private static var shared: MapViewModel = {
        return MapViewModel()
    }()
    
    // Workaround used when application is reload due language change
    static func recreate() {
        shared = MapViewModel()
    }

    static func instance() -> MapViewModel {
        return MapViewModel.shared
    }
    
    private var query: GFCircleQuery?
    private var placesBeingLoaded = Set<String>()
    private var loadCircleDisposables = [String : Disposable]()
    private var circles = [String : OrbisCircle]()
    private var pendingPlaceChanges = [String : PlaceChange]()
    private var blockedPlaceChanges = Set<String>() // Values: place keys
    private var pendingCircleDraws = [(OrbisCircle, CircleAnimation)]()
    
    private var firstQuery = true
    
    let drawCircleSubject = PublishSubject<Bool>()
    let applyPlaceChangesSubject = PublishSubject<Bool>()
    
    deinit {
        query?.removeAllObservers()
    }
    
    func onMapCenterChanged(center: Coordinates) {
        print2("[MapDebug] onMapCenterChanged \(center.latitude!) \(center.longitude!)")
        
        if query == nil {
            createQuery(center: center)
        }
        else {
            query?.center = center.toCLLocation()
        }
    }
    
    private func createQuery(center: Coordinates) {
        print2("[MapDebug] create query")
        
        query = GeoFireDAO.mapGeoFire.query(at: center.toCLLocation(), withRadius: 20.0)

        query!.observeReady { [weak self] in
            guard let this = self else {
                return
            }
            
            print2("[MapDebug] query ready")
            
            if this.firstQuery {
                this.firstQuery = false
                this.observePlaceChanges()
            }
        }

        query!.observe(.keyEntered, with: { [weak self] (key: String, loc: CLLocation) in
            guard let this = self else {
                return
            }
            
            //print2("[MapDebug] query key entered \(key)")
            this.loadCircle(placeKey: key)
        })
        
        query!.observe(.keyExited) { [weak self] (key: String, loc: CLLocation) in
            guard let this = self else {
                return
            }
        
            //print2("[MapDebug] query key exited \(key)")
            
            this.removeCircle(placeKey: key)
        }
    }
    
    private func loadCircle(placeKey: String) {
        if isLoading(placeKey: placeKey) {
            return
        }
        
        /*
        if placeKey != "-LWW7uCKZqIKVu9GQLAl" && placeKey != "4f7ef104bf346961448229c34956ca3e" {
            return
        }
        */
        
        let isPlaceBeingProcessed = PresenceEventViewModel.instance().isPlaceBeingProcessed(placeKey: placeKey)
        loadCircleDisposables[placeKey]?.dispose()
        addPlaceBeingLoaded(placeKey: placeKey)
        
        loadCircleDisposables[placeKey] = CircleDAO.loadCircle(placeKey: placeKey)
            .observeOn(MainScheduler.asyncInstance)
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] (circle: OrbisCircle) in
                guard let this = self else {
                    return
                }

                this.removePlaceBeingLoaded(placeKey: placeKey)
                
                if circle.place.deleted {
                    return
                }

                //circle.debug()
                //print2("[MapDebug] loadCircle finished: \(placeKey) \(circle.place.name ?? "") Circles count: \(this.circles.count)")
                
                this.circles[placeKey] = circle
                this.pendingCircleDraws.append((circle, isPlaceBeingProcessed ? CircleAnimation.spin : CircleAnimation.none))
                this.drawCircleSubject.onNext(true)
                
            }, onError: { [weak self] (error: Error) in
                print2("[MapDebug] loadCircle error \(placeKey) \(error)")
                self?.removePlaceBeingLoaded(placeKey: placeKey)
            }
        )
    }
    
    private func removeCircle(placeKey: String) {
        
    }
    
    func consumePendingCircleDraws() -> [(OrbisCircle, CircleAnimation)] {
        let items = pendingCircleDraws
        pendingCircleDraws.removeAll()
        return items
    }
    
    // Used on create place flow
    func addCircle(circle: OrbisCircle, createdByMe: Bool) {
        circles[circle.place.key!] = circle
    }
    
    func getCircle(placeKey: String) -> OrbisCircle? {
        return circles[placeKey]
    }
    
    func getPlaceWrapper(placeKey: String) -> PlaceWrapper? {
        return getCircle(placeKey: placeKey)?.toPlaceWrapper()
    }
    
    private func addPlaceBeingLoaded(placeKey: String) {
        placesBeingLoaded.insert(placeKey)
    }

    private func removePlaceBeingLoaded(placeKey: String) {
        placesBeingLoaded.remove(placeKey)
    }
    
    private func isLoading(placeKey: String) -> Bool {
        return placesBeingLoaded.contains(placeKey)
    }
    
    private func circleExists(placeKey: String) -> Bool {
        return circles.has(key: placeKey)
    }
    
    private func observePlaceChanges() {
        PlaceChangeDAO
            .loadMaxTimestamp()
            .subscribe(onSuccess: { [weak self] (timestamp: Int64) in
                print2("[MapDebug] observePlaceChanges from \(timestamp)")
                
                // Not sure if we need both -- TODO KINE: childAdded was commented
                self?.observePlaceChanges(eventType: .childAdded, fromTimestamp: timestamp)
                self?.observePlaceChanges(eventType: .childChanged, fromTimestamp: timestamp)
            }
        )
        .disposed(by: bag)
    }
    
    private func observePlaceChanges(eventType: DataEventType, fromTimestamp timestamp: Int64) {
        PlaceChangeDAO.observePlaceChanges(fromTimestamp: timestamp+1, eventType: eventType)
            //.observeOn(bgScheduler())
            //.subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (change: PlaceChange?) in
                guard
                    let this = self,
                    let change = change,
                    let placeKey = change.placeKey
                else {
                    print2("[MapDebug] place change observed. Early return")
                    return
                }
                
                if this.isLoading(placeKey: placeKey) {
                    print2("[MapDebug] place change observed. Early return because is loading \(placeKey)")
                    for key in this.placesBeingLoaded {
                        print2("[MapDebug] place being loaded: \(key)")
                    }
                    
                    let vm = PresenceEventViewModel.instance()
                    if vm.isPlaceBeingProcessed(placeKey: placeKey) {
                        vm.clearPlaceBeingProcessed()
                    }
                    return
                }
                
                if !this.circleExists(placeKey: placeKey) {
                    print2("[MapDebug] place change observed. Early return because circle was not founded. Will draw it")
                    this.loadCircle(placeKey: placeKey)
                    return
                }
                
                print2("[MapDebug] [\(eventType.rawValue)] place change observed \(change.debug())")
                this.processPlaceChange(change: change)

            }, onError: { (error: Error) in
                print2("[MapDebug] [\(eventType.rawValue)] place change error: \(error)")
            })
            .disposed(by: bag)
    }
    
    private func processPlaceChange(change: PlaceChange) {
        guard let placeKey = change.placeKey else {
            print2("[MapDebug] processPlaceChange early return 1 -- place key is nil")
            return
        }
        
        if isLoading(placeKey: placeKey) {
            print2("[MapDebug] processPlaceChange early return 2 -- is loading")
            return
        }
        
        if blockedPlaceChanges.contains(placeKey) {
            print2("[MapDebug] processPlaceChange early return 3 -- is blocked")
            return
        }
        
        if PresenceEventViewModel.instance().isPlaceBeingProcessed(placeKey: placeKey) {
            print2("[MapDebug] processPlaceChange early return 4 -- is place being processed")
            return
        }
        
        if !circleExists(placeKey: placeKey) {
            print2("[MapDebug] processPlaceChange early return 5 -- circle not exits")
            pendingPlaceChanges[placeKey] = change
            applyPlaceChangesSubject.onNext(true)
            return
        }
        
        let circle = getCircle(placeKey: placeKey)!
        let prevChange = pendingPlaceChanges[placeKey]
        let prevGroupKey = prevChange?.dominantGroupKey ?? circle.dominantGroup.key!
        let actualGroupKey = change.dominantGroupKey ?? ""
        let groupChanged = actualGroupKey != prevGroupKey
        let sizeChanged = change.currentSize != prevChange?.currentSize
        
        print2("[MapDebug] processPlaceChange groupChanged: \(groupChanged) [\(prevGroupKey) ----> \(actualGroupKey)] sizeChanged: \(sizeChanged)")
        
        if groupChanged {
            blockedPlaceChanges.insert(placeKey)
            
            GroupDAO.findByKey(groupKey: change.dominantGroupKey)
                //.observeOn(bgScheduler())
                //.subscribeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] (group: Group?) in
                    guard let group = group, let this = self else {
                        self?.blockedPlaceChanges.remove(placeKey)
                        return
                    }
                    
                    print2("[MapDebug] processPlaceChange groupChanged after group loaded")
                    
                    circle.dominantGroup = group
                    this.blockedPlaceChanges.remove(placeKey)
                    this.pendingPlaceChanges[placeKey] = change
                    this.applyPlaceChangesSubject.onNext(true)
                    
                }, onError: { [weak self] (error: Error) in
                    self?.blockedPlaceChanges.remove(placeKey)
                })
                .disposed(by: bag)
        }
        else if sizeChanged {
            pendingPlaceChanges[placeKey] = change
            applyPlaceChangesSubject.onNext(true)
        }
    }
    
    func getAndClearPendingPlaceChanges() -> [String : PlaceChange] {
        let copy = pendingPlaceChanges
        pendingPlaceChanges.removeAll()
        return copy
    }
    
    func updateCircle(placeKey: String, checkInResponse: HandlePresenceEventResponse) {
        let circle = getCircle(placeKey: placeKey)
        
        if let group = checkInResponse.dominance?.winnerGroup {
            circle?.dominantGroup = group
        }
    
        if let currentSize = checkInResponse.placeSize?.actualPlaceSize {
            circle?.currentSize = currentSize.float
        }
    }
}
