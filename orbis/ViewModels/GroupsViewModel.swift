//
//  GroupsViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 26/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import GeoFire

class GroupsViewModel : OrbisViewModel {
    
    private var location: Coordinates?
    private var query: GFCircleQuery?
    private var currentPageSize = 0
    private var term: String?
    private var filterDisposable: Disposable?
    private var setupDisposable: Disposable?

    private var groups = [Group]()
    private(set) var filteredGroups = [Group]()
    private var groupsLocationChunk = [String : CLLocation]()
    private var groupsBeingLoaded = Set<String>()

    private(set) var queryIsReady = false {
        didSet {
            defaultSubject.onNext(queryIsReady ? OrbisAction.taskFinished : OrbisAction.taskStarted)
        }
    }
    
    let tableOperationsSubject = PublishSubject<TableOperation>()
    let defaultSubject = PublishSubject<Any>()
    
    override init() {
        super.init()
        
        loadNextChunk(incrementCounter: true)
        
        HelperRepository.instance().groupEditedSubject
            .subscribe(onNext: { [weak self] group in
                guard let this = self else {
                    return
                }
                
                if let index = this.filteredGroups.firstIndex(where: { $0.key == group.key }) {
                    this.filteredGroups[index] = group
                    this.tableOperationsSubject.onNext(TableOperation.UpdateOperation(index: index))
                    
                }

                if let index = this.groups.firstIndex(where: { $0.key == group.key }) {
                    this.groups[index] = group
                }
            }, onError: { error in
                print2("GroupsViewModel groupEditedSubject error")
                print2(error)
            })
            .disposed(by: bag)
    }
    
    deinit {
        query?.removeAllObservers()
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
                    self?.location = location
                
                    let query = GeoFireDAO.groupsGeoFire.query(at: location.toCLLocation(), withRadius: 1.0)

                    query.observe(.keyEntered, with: { [weak self] (key: String, loc: CLLocation) in
                        guard let this = self else {
                            return
                        }
                        
                        if this.queryIsReady {
                            this.loadGroup(groupKey: key)
                        }
                        else {
                            this.groupsLocationChunk[key] = loc
                        }
                    })
                    
                    query.observeReady { [weak self] in
                        guard let this = self else {
                            return
                        }
                        
                        let newLocationsCount = this.groupsLocationChunk.count
                        this.loadGroups(groupKeys: this.sortChunkAndGetKeys())
                        this.currentPageSize += newLocationsCount
                        this.groupsLocationChunk.removeAll()
                        
                        //print2("[Groups] onQueryReady wasReady: \(this.queryIsReady) currentPageSize: \(this.currentPageSize)")
                        
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
                //print2("[Groups] loadNextChunk radius: \(radius)")
                query!.radius = radius
            }
            else {
                onQueryLimitReached()
            }
        }
    }
    
    private func onQueryLimitReached() {
        //print2("[Groups] onQueryLimitReached")
        decrementLoadingCounter(notify: false)
        queryIsReady = true
        loadGroups(groupKeys: sortChunkAndGetKeys())
    }
    
    private func loadGroups(groupKeys: [String]) {
        GroupDAO
            .loadGroups(groupKeys: groupKeys)
            .subscribe(onSuccess: { [weak self] (groups: [Group?]) in
                guard let this = self else {
                    return
                }
                
                let newGroups = groups.filter { $0 != nil && !$0!.deleted }
                    .map { $0! } as [Group]
                
                if !newGroups.isEmpty {
                    this.groups += newGroups
                    this.filter(term: self?.term, newChunk: true)
                    this.decrementLoadingCounter()
                }
            }, onError: { (error: Error) in
                print2(error)
            })
            .disposed(by: bag)
    }
    
    private func loadGroup(groupKey: String) {
        if groupsBeingLoaded.contains(groupKey) || indexOf(groupKey: groupKey) != nil {
            return
        }
        
        groupsBeingLoaded.insert(groupKey)
        
        GroupDAO
            .findByKey(groupKey: groupKey)
            .subscribe(onSuccess: { [weak self] (group: Group?) in
                print2("Loaded single group [1]")
                
                guard
                    let group = group,
                    let this = self
                else {
                    return
                }
                
                print2("Loaded single group [2]")
                
                this.groups.append(group)
                this.sortGroups()
                this.filter(term: this.term, newChunk: false)
                this.groupsBeingLoaded.remove(groupKey)
            })
            .disposed(by: bag)
    }
    
    private func sortChunkAndGetKeys() -> [String] {
        guard let origin = location?.toCLLocation(), !groupsLocationChunk.isEmpty else {
            return []
        }
        
        return groupsLocationChunk.sorted(by: { (arg0, arg1) -> Bool in
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
    
    private func sortGroups() {
        guard let origin = location?.toCLLocation() else { return }
        groups.sort(by: { (g0: Group, g1: Group) -> Bool in
            let dst = g0.location.toCLLocation().distance(from: origin)
            let dst2 = g1.location.toCLLocation().distance(from: origin)
            return dst < dst2
        })
    }
    
    private func filter(term: String?, newChunk: Bool) {
        self.term = term
        
        if isInSearchMode() {
            guard let term = term else {
                return
            }
            
            filterDisposable?.dispose()
            
            filterDisposable = GroupDAO.loadGroupsWithTerm(term: term)
                .subscribe(onSuccess: { [weak self] (fGroups : [Group]) in
                    print2("Founded \(fGroups.count) for term \(term)")
                    self?.filteredGroups = fGroups
                    self?.tableOperationsSubject.onNext(TableOperation.ReloadOperation())
                }, onError: { (error: Error) in
                    print2(error)
                })
            
            bag.insert(filterDisposable!)
        }
        else {
            print2("Filter without term")
            filteredGroups = groups
            tableOperationsSubject.onNext(TableOperation.ReloadOperation())
            
            /*
            if newChunk {
                let prevSize = filteredGroups.count
                let newSize = groups.count
                filteredGroups = groups
                tableOperationsSubject.onNext(TableOperation.InsertOperation(start: prevSize, end: newSize-1))
            }
            else {
                filteredGroups = groups
                tableOperationsSubject.onNext(TableOperation.ReloadOperation())
            }
            */
        }
    }
    
    private func isInSearchMode() -> Bool {
        guard let t = term else {
            return false
        }
        return !t.isEmpty
    }
    
    private func incrementLoadingCounter() {
        
    }
    
    private func decrementLoadingCounter(notify: Bool = true) {
        
    }
    
    func indexOf(groupKey: String) -> Int? {
        return filteredGroups.firstIndex(where: { $0.key == groupKey })
    }
    
    func consumerNeedsMoreData() {
        if queryIsReady && !isInSearchMode() {
            print2("[Groups] consumerNeedsMoreData")
            currentPageSize = 0
            loadNextChunk(incrementCounter: true)
        }
    }
}

extension GroupsViewModel : SearchDelegate {

    func search(term: String?) {
        self.filter(term: term, newChunk: false)
    }
    
}
