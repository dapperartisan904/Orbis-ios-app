//
//  PlaceViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 16/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class PlaceViewModel : OrbisViewModel {
    
    private(set) var place: Place
    private(set) var tab: PlaceTab?
    private(set) var prevTab: PlaceTab?
    
    // Group of points
    private(set) var groups: [Group?]?
    private(set) var points: [PointsData]?
    
    let tabSelectedSubject = BehaviorSubject<PlaceTab>(value: PlaceTab.description)
    let pointsLoadedSubject = BehaviorSubject<Bool>(value: false)
    
    init(place: Place) {
        self.place = place
        super.init()
        loadPoints()
        observeCheckInResponse()
    }
    
    func tabSelected(tab: PlaceTab) {
        self.prevTab = self.tab
        self.tab = tab
        tabSelectedSubject.onNext(tab)
    }

    private func loadPoints() {
        CloudFunctionsDAO.pointsData(placeKey: place.key)
            .asObservable()
            .asSingle()
            .flatMap { [weak self] (pointsData : [PointsData]?) -> Single<[Group?]> in
                guard
                    let this = self,
                    let points = pointsData
                else {
                    print2("PlaceViewModel loadPoints early return")
                    return Single.never()
                }
                this.points = points
                return GroupDAO.loadGroups(groupKeys: points.map { $0.groupKey })
            }
            .subscribe(onSuccess: { [weak self] groups in
                guard let this = self else { return }
                this.groups = groups
                this.pointsLoadedSubject.onNext(true)
                print2("Load points success")
            }, onError: { error in
                print2("Load points error: \(error)")
            })
            .disposed(by: bag)
    }
    
    func getGroup(groupKey: String) -> Group? {
        return groups?.first { $0?.key == groupKey } ?? nil
    }
    
    func getDominatingGroup() -> Group? {
        guard let p = points?.first else { return nil }
        return getGroup(groupKey: p.groupKey)
    }
    
    func canEdit() -> Bool {
        let me = UserDefaultsRepository.instance().getMyUser()
        
        if let ownerId = place.ownerId {
            return ownerId == me?.uid
        }
        
        if place.temporary && !place.wasTemporary {
            return me != nil
        }
        
        guard let points = points else { return false }
        let groupKeys = points.map { $0.groupKey }
        return RolesViewModel.instance().isAdministratorOfSome(groupKeys: groupKeys)
    }
    
    func savePlaceDescription(text: String?) {
        PlaceDAO.savePlaceDescription(placeKey: place.key, description: text)
            .subscribe(onSuccess: { [weak self] _ in
                guard let this = self else {
                    return
                }
                
                this.place.description = text
                HelperRepository.instance().placeChangedObservable.onNext(this.place)
                
            },  onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }
    
    func savePlaceName(text: String?) {
        guard let text = text, !text.isEmpty else {
            return
        }
    
        PlaceDAO.savePlaceName(place: place, name: text)
            .subscribe(onSuccess: { [weak self] _ in
                guard let this = self else {
                    return
                }
                
                this.place.name = text
                HelperRepository.instance().placeChangedObservable.onNext(this.place)
            
            },  onError: {
                error in print2(error)
            })
            .disposed(by: bag)
    }
    
    private func observeCheckInResponse() {
        PresenceEventViewModel.instance().checkInResponseSubject
            .subscribe(onNext: { [weak self] received in
                guard
                    let this = self,
                    let response = PresenceEventViewModel.instance().getCheckInResponse(),
                    response.place?.key == this.place.key,
                    received
                else {
                    return
                }
                
                this.loadPoints()
            })
            .disposed(by: bag)
    }
}
