//
//  UserGroupsViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 26/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class UserGroupsViewModel : OrbisViewModel {
    
    let defaultSubject = PublishSubject<Any>()
    let lockSubject = BehaviorSubject<Bool>(value: false)
    
    private(set) var groups = [Group]()
    
    init(userViewModel: UserViewModel) {
        super.init()
        load(userViewModel: userViewModel)
    }
    
    private func load(userViewModel: UserViewModel) {
        if !userViewModel.isMyUser && userViewModel.user.groupsArePublic == false {
            lockSubject.onNext(true)
            return
        }
        
        defaultSubject.onNext(OrbisAction.taskStarted)
        
        userViewModel.groupLoadedSubject
            .filter { value in return value }
            .flatMap { _ in
                return GroupDAO.loadGroupsOfUser(userId: userViewModel.user.uid, requiredRole: Roles.member)
            }
            .subscribe(onNext: { [weak self] groups in
                guard let this = self else { return }
                print2("UserGroupsViewModel: loaded \(groups.count) groups")
                this.groups = groups
                this.defaultSubject.onNext(OrbisAction.taskFinished)
            }, onError: { [weak self] error in
                print2(error)
                self?.defaultSubject.onNext((OrbisAction.taskFailed, Words.errorGeneric))
            })
            .disposed(by: bag)

    }
    
    func indexOf(groupKey: String) -> Int? {
        return groups.firstIndex(where: { $0.key == groupKey })
    }
    
}
