//
//  PlaceCheckInViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 30/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class PlaceCheckInViewModel : OrbisViewModel {
    
    let place: Place
    private var users = [OrbisUser]()
    private var groups = [String : Group]()
    private var roles = [String : [Roles]]()
    private var loaded = false
    
    let defaultSubject = PublishSubject<Any>()
    
    init(placeViewModel: PlaceViewModel) {
        self.place = placeViewModel.place
        super.init()
        load()
    }
    
    func numberOfItems() -> Int {
        return loaded ? users.count : 0
    }
    
    func getData(index: Int) -> (OrbisUser, Group?, Bool) {
        let group: Group?
        let user = users[index]
        let isAdministrator = roles[user.uid]?.contains(Roles.administrator) ?? false
        
        if let k = user.activeGroupId {
            group = groups[k]
        }
        else {
            group = nil
        }
        
        return (user, group, isAdministrator)
    }
    
    private func load() {
        PresenceEventDAO.loadPresenceEvents(placeKey: place.key)
            .flatMap { (events: [PresenceEvent]) -> Single<[String : OrbisUser]> in
                print2("PlaceCheckInViewModel Load step 1 \(events.count)")
                
                let userKeys = events.map { $0.userKey! }
                return UserDAO.loadUsersByIds(userIds: userKeys)
            }
            .flatMap { [weak self] (users: [String : OrbisUser]) -> Single<[String : Group]> in
                print2("PlaceCheckInViewModel Load step 2 \(users.count)")
                
                guard let this = self else {
                    return Single.just([String : Group]())
                }

                this.users = Array(users.values)
                
                let groupKeys = users.map { $0.value.activeGroupId }
                    .filter { return $0 != nil }
                    .map { $0! }
                    .withoutDuplicates()
                
                return GroupDAO.loadGrousAsDictionary(groupKeys: groupKeys)
            }
            .flatMap { [weak self] (groups: [String : Group]) -> Single<[String : [Roles]]> in
                print2("PlaceCheckInViewModel Load step 3 \(groups.count)")
                
                guard let this = self else {
                    return Single.just([String : [Roles]]())
                }
                
                this.groups = groups
                
                if let key = this.place.dominantGroupKey {
                    return RoleDAO.allRolesInGroup(groupKey: key)
                }
                else {
                    return Single.just([String : [Roles]]())
                }
            }
            .subscribe(onSuccess: { [weak self] roles in
                print2("PlaceCheckInViewModel Load step 4 \(roles.count)")
                guard let this = self else { return }
                
                this.roles = roles
                this.users = this.users.sort(roles: roles)
                this.loaded = true
                this.defaultSubject.onNext(OrbisAction.taskFinished)
            
            }, onError: { [weak self] error in
                print2(error)
                self?.defaultSubject.onNext((OrbisAction.taskFailed, Words.errorGeneric))
            })
            .disposed(by: bag)
    }
    
}
