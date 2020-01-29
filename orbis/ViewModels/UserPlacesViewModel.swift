//
//  UserPlacesViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 29/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class UserPlacesViewModel : OrbisViewModel {
    
    let user: OrbisUser
    let isMyUser: Bool
    
    private(set) var placeWrappers = [PlaceWrapper]()
    private(set) var events = [PresenceEvent]()
    
    let defaultSubject = PublishSubject<Any>()
    let lockSubject = BehaviorSubject<Bool>(value: false)
    
    init(userViewModel: UserViewModel) {
        self.user = userViewModel.user
        self.isMyUser = userViewModel.isMyUser
        super.init()
        load(userViewModel: userViewModel)
    }
    
    private func load(userViewModel: UserViewModel) {
        if !userViewModel.isMyUser && userViewModel.user.placesArePublic == false {
            lockSubject.onNext(true)
            return
        }
        
        RoleDAO.rolesOfUserInPlaces(userId: user.uid, requiredRole: Roles.follower)
            .flatMap { (roles : [String : [Roles]]) -> Single<[PlaceWrapper]> in
                let keys = Array(roles.keys)
                return PlaceWrapperDAO.load(placeKeys: keys, excludeDeleted: true)
            }
            .flatMap { [weak self] (placeWrappers : [PlaceWrapper]) -> Single<[PresenceEvent]> in
                guard let this = self else {
                    return Single.never()
                }
                this.placeWrappers = placeWrappers
                return PresenceEventDAO.loadPresenceEvents(userId: this.user.uid)
            }
            .subscribe(onSuccess: { [weak self] events in
                guard let this = self else { return }
                this.events = events.sorted(by: \PresenceEvent.validTimestamp, ascending: false)
                
                this.placeWrappers.sort(by: { pw0, pw1 in
                    let ev0 = this.presenceEvent(placeKey: pw0.place.key)
                    let ev1 = this.presenceEvent(placeKey: pw1.place.key)
                    
                    if ev0 == nil && ev1 == nil {
                        return pw0.place.name.compare(pw1.place.name) == ComparisonResult.orderedAscending
                    }
                    
                    if ev1 == nil {
                        return true
                    }
                    
                    if ev0 == nil {
                        return false
                    }
                    
                    return (ev0!.validTimestamp ?? 0) > (ev1!.validTimestamp ?? 0)
                })
                
                this.defaultSubject.onNext(OrbisAction.taskFinished)
            }, onError: { [weak self] error in
                print2(error)
                self?.defaultSubject.onNext((OrbisAction.taskFailed, Words.errorGeneric))
            })
            .disposed(by: bag)
    }
    
    private func presenceEvent(placeKey: String) -> PresenceEvent? {
        return events.first(where: { ev in return ev.placeKey == placeKey })
    }
    
    func getData(indexPath: IndexPath) -> (Place, Group?, PresenceEvent?) {
        return getData(index: indexPath.row)
    }
    
    func getData(index: Int) -> (Place, Group?, PresenceEvent?) {
        let w = placeWrappers[index]
        let e = presenceEvent(placeKey: w.place.key)
        return (w.place, w.group, e)
    }
    
    func index(of placeKey: String) -> Int? {
        return placeWrappers.firstIndex(where: { $0.place.key == placeKey })
    }
}
