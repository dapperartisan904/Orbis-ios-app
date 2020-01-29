//
//  AttendancesViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 01/05/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class AttendancesViewModel : OrbisViewModel {
    
    let event: OrbisPost!
    private(set) var users = [OrbisUser]()
    private(set) var groups = [String : Group]()
    
    let defaulSubject = PublishSubject<Any>()
    
    init(event: OrbisPost) {
        self.event = event
        super.init()
    }

    func load() {
        AttendanceDAO.loadAttendances(postKey: event.postKey, limit: nil)
            .flatMap { (attendances: [Attendance]) -> Single<[String : OrbisUser]> in
                let userIds = attendances.filter { $0.statusEnum() == .attending }.map { $0.userId }
                return UserDAO.loadUsersByIds(userIds: userIds)
            }
            .flatMap { [weak self] (users: [String : OrbisUser]) -> Single<[String : Group]> in
                guard let this = self else {
                    return Single.never()
                }
                
                this.users = Array(users.values)
                let groupKeys = this.users.filter { $0.activeGroupId != nil }.map { $0.activeGroupId! }
                
                return GroupDAO.loadGrousAsDictionary(groupKeys: groupKeys)
            }
            .subscribe(onSuccess: { [weak self] (groups: [String : Group]) in
                self?.groups = groups
                self?.defaulSubject.onNext(OrbisAction.taskFinished)
            }, onError: { [weak self] error in
                print2(error)
                self?.defaulSubject.onNext((OrbisAction.taskFailed, Words.errorGeneric))
            })
            .disposed(by: bag)
    }
    
    func rowData(index: Int) -> (OrbisUser, Group?) {
        return (users[index], groups[users[index].activeGroupId ?? ""])
    }
}
