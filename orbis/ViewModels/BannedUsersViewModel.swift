//
//  BannedUsersViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/05/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseFirestore

class BannedUsersViewModel : OrbisViewModel {
    
    override fileprivate init() {
        super.init()
        observeApplicationFinishLaunching()
        observeLogout()
    }
    
    private static var shared: BannedUsersViewModel = {
        return BannedUsersViewModel()
    }()
    
    static func instance() -> BannedUsersViewModel {
        return BannedUsersViewModel.shared
    }

    let myBannedUsersLoadedSubject = BehaviorSubject<(String?, Bool)>(value: (nil, true))
    private var myUser: OrbisUser?
    private var myBannedUsers = Set<String>()
    private var initialLoad = true
    private var applicationDidLoad = false
    private var contentBag = DisposeBag()
    
    private func observeLogout() {
        HelperRepository.instance()
            .logoutObservable
            .subscribe(onNext: { [weak self] _ in
                print2("[LikesByUser] observed logout")
                guard let this = self else { return }
                this.myUser = nil
                this.contentBag = DisposeBag()
                this.myBannedUsers.removeAll()
            })
            .disposed(by: bag)
    }
    
    private func observeApplicationFinishLaunching() {
        HelperRepository.instance().applicationFinishLaunchingSubject
            .subscribe(onNext: { [weak self] finished in
                guard let this = self else { return }
                
                print2("[LikesByUser] FinishLaunching: \(finished) alreadyDidLoad: \(this.applicationDidLoad)")
                
                if finished && !this.applicationDidLoad {
                    this.applicationDidLoad = true
                    this.observeMyUser()
                }
            })
            .disposed(by: bag)
    }
    
    private func observeMyUser() {
        print2("[LikesByUser] observeMyUser")
        
        HelperRepository.instance().myUserSubject
            .subscribe(onNext: { [weak self] user in
                guard let this = self else { return }
                if this.initialLoad || this.myUser?.uid != user?.uid {
                    this.initialLoad = false
                    this.myUser = user
                    this.loadMyBannedUsers()
                }
            })
            .disposed(by: bag)
    }
    
    private func loadMyBannedUsers() {
        guard let myUser = myUser else {
            myBannedUsersLoadedSubject.onNext((nil, true))
            return
        }
    
        BannedUsersDAO.load(userId: myUser.uid)
            .subscribe(onSuccess: { [weak self] result in
                guard let this = self else { return }
                this.myBannedUsers = result
                this.myBannedUsersLoadedSubject.onNext((myUser.uid, true))
            }, onError: { error in
                print2(error)
            })
            .disposed(by: contentBag)
    }
    
    func isBanned(userId: String?) -> Bool {
        guard let id = userId else { return false }
        return myBannedUsers.contains(id)
    }
}
