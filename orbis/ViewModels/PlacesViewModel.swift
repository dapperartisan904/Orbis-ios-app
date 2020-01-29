//
//  PlacesViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import GeoFire
import RxSwift

class PlacesViewModel : OrbisViewModel {
    
    private var location: Coordinates?
    private var query: GFCircleQuery?
    private var currentPageSize = 0
    private var term: String?
    private var filterDisposable: Disposable?
    private var setupDisposable: Disposable?
    
    private var currentNearbySearchRadius = 0
    
    private var wrappers = [PlaceWrapper]()
    private(set) var filteredWrappers = [PlaceWrapper]()
    private var placesLocationChunk = [String : CLLocation]()
    private var placesBeingLoaded = Set<String>()
    
    private(set) var queryIsReady = false {
        didSet {
            defaultSubject.onNext(queryIsReady ? OrbisAction.taskFinished : OrbisAction.taskStarted)
        }
    }
    
    private var executingNearbySearch = false {
        didSet {
            defaultSubject.onNext(isLoading() ? TaskStatus.loading : TaskStatus.finished)
        }
    }
    
    let tableOperationsSubject = PublishSubject<TableOperation>()
    let defaultSubject = PublishSubject<Any>()
    
    override init() {
        super.init()
        loadNextChunk(incrementCounter: true)
        observeGPSLocation()
        observePlaceChanges()
    }
    
    deinit {
        query?.removeAllObservers()
    }
    
    func isLoading() -> Bool {
        return !queryIsReady || executingNearbySearch
    }
    
    private func createQuery() {
        setupDisposable = HelperRepository.instance()
            .locationSubject
            .filter { location in return location != nil }
            .subscribe(
                onNext: { [weak self] (location : Coordinates?) in
                    guard let location = location else {
                        return
                    }
                    
                    self?.setupDisposable?.dispose()
                    self?.setupDisposable = nil
                    self?.location = location
                    
                    //Fetching Places
                    let query = GeoFireDAO.placesGeoFire.query(at: location.toCLLocation(), withRadius: 1.0)
                    
                    query.observe(.keyEntered, with: { [weak self] (key: String, loc: CLLocation) in
                        //print2("key entered: \(key)")
                        
                        guard let this = self else {
                            return
                        }
                        
                        if this.queryIsReady {
                            this.loadWrapper(placeKey: key)
                        }
                        else {
                            this.placesLocationChunk[key] = loc
                        }
                    })
                    
                    query.observeReady { [weak self] in
                        guard let this = self else {
                            return
                        }
                        
                        let newLocationsCount = this.placesLocationChunk.count
                        this.loadWrappers(placeKeys: this.sortChunkAndGetKeys())
                        this.currentPageSize += newLocationsCount
                        this.placesLocationChunk.removeAll()
                        
                        print2("[Places] onQueryReady wasReady: \(this.queryIsReady) currentPageSize: \(this.currentPageSize)")
                        
                        // Load new chunk without scroll event
                        if (this.currentPageSize < paginationCount) {
                            this.loadNextChunk(incrementCounter: false)
                        }
                        else {
                            this.queryIsReady = true
                        }
                    }
                    
                    self?.query = query
                    
                }, onError: { (error: Error) in
                    print2(error)
                }
        )
        
        bag.insert(setupDisposable!)
    }
    
    private func loadNextChunk(incrementCounter: Bool) {
        if query == nil {
            createQuery()
        }
        else {
            var radius = query!.radius
            if radius < geoFireMaxRadiusInKm {
                if (incrementCounter) {
                    incrementLoadingCounter()
                }
                
                queryIsReady = false
                radius = min(geoFireMaxRadiusInKm, radius + 5.0)
                print2("[Places] loadNextChunk radius: \(radius)")
                query!.radius = radius
            }
            else {
                onQueryLimitReached()
            }
        }
    }
    
    private func onQueryLimitReached() {
        print2("[Places] onQueryLimitReached")
        decrementLoadingCounter(notify: false)
        queryIsReady = true
        loadWrappers(placeKeys: sortChunkAndGetKeys())
    }

    private func loadWrappers(placeKeys: [String], shouldSort: Bool = false) {
        guard let radius = query?.radius else {
            return
        }
        
        print2("[Places] loadWrappers shouldSort: \(shouldSort)")
        
        PlaceWrapperDAO
            .load(placeKeys: placeKeys)
            .subscribe(
                onSuccess: { [weak self] (wrappers: [PlaceWrapper]) in
                    guard let this = self else {
                        return
                    }
                
                    print2("[Places] loaded \(wrappers.count) wrappers")
                    
                    if !wrappers.isEmpty {
                        this.wrappers += wrappers.filter { !$0.place.temporary }
                        
                        if shouldSort {
                            this.sortWrappers()
                        }
                        
                        this.filter(term: self?.term, newChunk: true)
                        this.decrementLoadingCounter()
                    }
                    
                    this.executeNearbySearchIfNeeded(currentRadius: radius)
                }, onError: { (error: Error) in
                    print2("[Places] loadWrappers error")
                    print2(error)
                }
            )
            .disposed(by: bag)
    }
    
    private func loadWrapper(placeKey: String) {
        loadWrappers(placeKeys: [placeKey], shouldSort: true)
    }
    
    private func sortChunkAndGetKeys() -> [String] {
        guard let origin = location?.toCLLocation() else {
            print2("[Places] sortChunkAndGetKeys early return [1]")
            return []
        }
        
        if placesLocationChunk.isEmpty {
            print2("[Places] sortChunkAndGetKeys early return [2]")
            return []
        }

        print2("[Places] sortChunkAndGetKeys origin: \(origin)")
        
        return placesLocationChunk.sorted(by: { (arg0, arg1) -> Bool in
            let (_, location) = arg1
            let (_, location2) = arg0
            let dst = location.distance(from: origin)
            let dst2 = location2.distance(from: origin)
            return dst > dst2
        }).map({ (arg0) -> String in
            let (key, _) = arg0
            return key
        })
    }
    
    private func sortWrappers() {
        guard let origin = location else {
            print2("[Places] sortWrappers early return")
            return
        }
        
        print2("[Places] sortWrappers early origin: \(origin)")
        
        wrappers.sort(by: { (w0, w1) -> Bool in
            let dst = w0.place.coordinates.distanceInMeters(toOther: origin)
            let dst2 = w1.place.coordinates.distanceInMeters(toOther: origin)
            return dst > dst2
        })
    }
    
    func consumerNeedsMoreData() {
        if queryIsReady && !isInSearchMode() {
            print2("[Places] consumerNeedsMoreData")
            currentPageSize = 0
            loadNextChunk(incrementCounter: true)
        }
    }
    
    private func filter(term: String?, newChunk: Bool) {
        self.term = term
        
        if isInSearchMode() {
            guard let term = term else {
                return
            }
            
            filterDisposable?.dispose()

            filterDisposable = PlaceWrapperDAO.load(term: term)
                .subscribe(onSuccess: { [weak self] (fPlaces : [PlaceWrapper]) in
                    print2("Founded \(fPlaces.count) for term \(term)")
                    self?.filteredWrappers = fPlaces.filter { !$0.place.temporary }
                    self?.tableOperationsSubject.onNext(TableOperation.ReloadOperation())
                }, onError: { (error: Error) in
                    print2(error)
                })
            
            bag.insert(filterDisposable!)
        }
        else {
            filteredWrappers = wrappers
            tableOperationsSubject.onNext(TableOperation.ReloadOperation())
        }
    }
    
    private func isInSearchMode() -> Bool {
        guard let t = term else {
            return false
        }
        return !t.isEmpty
    }
    
    func indexPathOf(placeKey: String) -> IndexPath? {
        guard let row = filteredWrappers.firstIndex(where: { $0.place.key == placeKey }) else {
            return nil
        }
        
        return IndexPath(row: row, section: 1)
    }
    
    private func incrementLoadingCounter() { }
    private func decrementLoadingCounter(notify: Bool = true) { }
    
    private func observeGPSLocation() {
        HelperRepository.instance()
            .locationSubject
            .filter { location in return location != nil }
            .subscribe(onNext: { [weak self] location in
                guard let this = self else { return }
                OrbisGPSLocation.instance().coordinates = location
                this.tableOperationsSubject.onNext(TableOperation.UpdateOperation(index: 0))
            })
            .disposed(by: bag)
    }
    
    private func observePlaceChanges() {
        HelperRepository.instance().placeChangedObservable
            .subscribe(onNext: { [weak self] place in
                guard
                    let this = self,
                    let indexPath = this.indexPathOf(placeKey: place.key)
                else {
                    return
                }
            
                if indexPath.section == 1 {
                    this.wrappers[indexPath.row].place = place
                    this.tableOperationsSubject.onNext(TableOperation.UpdateOperation(indexPaths: [indexPath]))
                }
            })
            .disposed(by: bag)
    }
}

extension PlacesViewModel : SearchDelegate {
    
    func search(term: String?) {
        self.filter(term: term, newChunk: false)
    }
    
}

/*
    MARK: Nearby Search methods
*/
extension PlacesViewModel {
    
    private func executeNearbySearchIfNeeded(currentRadius: Double) {
        if !HelperRepository.instance().admin.nearbySearchEnabled {
            print2("executeNearbySearchIfNeeded early return [1]")
            return
        }
    
        if currentRadius != 6.0 || executingNearbySearch || wrappers.count > 500000 {
            print2("executeNearbySearchIfNeeded early return [2]")
            return
        }
        
        guard let query = query else {
            print2("executeNearbySearchIfNeeded early return [3]")
            return
        }
    
        print2("executeNearbySearchIfNeeded proceed")
        
        GeoFireDAO.searchExists(query: query)
            .subscribe(onSuccess: { [weak self] exists in
                guard let this = self else { return }
                
                if exists {
                    print2("executeNearbySearchIfNeeded query already exists")
                    this.executingNearbySearch = false
                }
                else {
                    print2("executeNearbySearchIfNeeded proceed [2]")
                    this.nearbySearchNextStep()
                }
                
            }, onError: { error in
                print2("executeNearbySearchIfNeeded error [4] \(error)")
            })
            .disposed(by: bag)
    }
    
    private func nearbySearchNextStep() {
        currentNearbySearchRadius += 1000
        
        if currentNearbySearchRadius > maxNearbySearchRadiusInMeters {
            executingNearbySearch = false
            return
        }
        
        guard let location = HelperRepository.instance().getLocation() else {
            return
        }
        
        print2("executeNearbySearchIfNeeded nextStep radius: \(currentNearbySearchRadius)")
        
        GooglePlaceService.instance()
            .nearbySearch(location: location.toCLLocation(), radiusInMeters: currentNearbySearchRadius)
            .flatMapCompletable { [weak self] (response : NearbySearchResponse?) -> Completable in
                print2("nearbySearchNextStep nearbySerch request finished")
                guard let this = self else {
                    return Completable.empty()
                }
                return this.handleNearbySearchResponse(response: response, saveLocation: this.currentNearbySearchRadius == 1000)
            }
            .delaySubscription(2, scheduler: ConcurrentMainScheduler.instance)
            .subscribe(onCompleted: {
                print2("nearbySearchNextStep handleNearbySearchResponse finished")
            }, onError: { error in
                print2("nearbySearchNextStep error \(error)")
            })
            .disposed(by: bag)
    }
    
    private func handleNearbySearchResponse(response: NearbySearchResponse?, saveLocation: Bool) -> Completable {
        guard
            let response = response,
            let items = response.results
        else {
            return Completable.error(OrbisErrors.generic)
        }
        
        if response.status != "OK" {
            return Completable.error(OrbisErrors.generic)
        }

        print2("handleNearbySearchResponse items count: \(items.count)")
        
        if items.isEmpty {
            nearbySearchNextStep()
            return Completable.error(OrbisErrors.emptyResult)
        }
        
        let completables = items.map { item in
            return PlaceDAO.savePlace(data: item)
        }
        
        let saveLocationCompletable = saveLocation ?
            GeoFireDAO.saveNearbySearchLocation(query: query!).asCompletable() :
            Completable.empty()
        
        return Completable.concat(completables)
            .do(onCompleted: { [weak self] in
                self?.nearbySearchNextStep()
            })
            .andThen(saveLocationCompletable)
    }
}
