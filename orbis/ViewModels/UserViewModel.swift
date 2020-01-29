//
//  UserViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 26/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class UserViewModel : OrbisViewModel {
    
    let user: OrbisUser
    let myUser: OrbisUser?
    var group: Group?
    let isMyUser: Bool
    
    let tabSelectedSubject = PublishSubject<UserTab>()
    let groupLoadedSubject = BehaviorSubject<Bool>(value: false)
    let showingChatSubject = PublishSubject<Bool>()
    let defaultSubject = PublishSubject<Any>()
    
    init(user: OrbisUser) {
        self.user = user
        self.myUser = UserDefaultsRepository.instance().getMyUser()
        self.isMyUser = user.uid == self.myUser?.uid
        super.init()
        loadActiveGroup()
    }

    func tabSelected(tab: UserTab) {
        tabSelectedSubject.onNext(tab)
    }
 
    private func loadActiveGroup() {
        GroupDAO.findByKey(groupKey: user.activeGroupId)
            .subscribe(onSuccess: { [weak self] group in
                self?.group = group
                self?.groupLoadedSubject.onNext(true)
            },
            onError: { [weak self] error in
                print2(error)
                self?.defaultSubject.onNext(Words.errorGeneric)
            }
        )
        .disposed(by: bag)
    }
    
    func saveGroupsArePublic(value: Bool) {
        if !isMyUser {
            return
        }
        
        UserDAO.saveGroupsArePublic(userId: user.uid, value: value)
            .subscribe(onSuccess: { _ in }, onError: { error in print2(error) })
            .disposed(by: bag)
    }
    
    func savePlacesArePublic(value: Bool) {
        if !isMyUser {
            return
        }
        
        UserDAO.savePlacesArePublic(userId: user.uid, value: value)
            .subscribe(onSuccess: { _ in }, onError: { error in print2(error) })
            .disposed(by: bag)
    }
    
    func blockUser() {
        if isMyUser {
            return
        }

        guard let myUser = myUser else { return }
        
        BannedUsersDAO.save(userId: myUser.uid, userId2: user.uid, blocked: true)
            .subscribe(onSuccess: { _ in }, onError: { error in print2(error) })
            .disposed(by: bag)
    }
}
