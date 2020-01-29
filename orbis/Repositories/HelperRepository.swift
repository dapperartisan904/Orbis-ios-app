//
//  HelperRepository.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 19/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseInstanceID
import RxSwift

class HelperRepository {
    
    private static var shared: HelperRepository = {
        return create()
    }()
    
    private static func create() -> HelperRepository {
        let hr = HelperRepository()
        let defaults = UserDefaultsRepository.instance()
        
        hr.setMyUser(user: defaults.getMyUser())
        hr.setActiveGroup(group: defaults.getActiveGroup(), updateUser: false)
        hr.observeAdmin()
        
        return hr
    }
    
    // Workaround used when application is reload due language change
    static func recreate() {
        shared = create()
    }
    
    static func instance() -> HelperRepository {
        return HelperRepository.shared
    }
    
    private init() { }
    
    public let activeGroupSubject = BehaviorSubject<(Group?, Group?)>(value: (nil, nil)) // Prev group, new group
    public let locationSubject = BehaviorSubject<Coordinates?>(value: nil)
    public let applicationFinishLaunchingSubject = BehaviorSubject<Bool>(value: false)
    public let myUserSubject = BehaviorSubject<OrbisUser?>(value: nil)
    public let myDoubleUserSubject = BehaviorSubject<(OrbisUser?, OrbisUser?)>(value: (nil, nil)) // Old value, new value
    public let logoutObservable = PublishSubject<Bool>()
    public let placeChangedObservable = PublishSubject<Place>()
    public let groupEditedSubject = PublishSubject<Group>()
    
    private var myUserOnDatabaseDisposable: Disposable?
    private let bag = DisposeBag()
    
    private (set) var selectedPlace: PlaceWrapper?
    private (set) var selectedGroup: Group?
    private (set) var selectedUser: OrbisUser?
    private (set) var selectedPost: OrbisPost?
    private(set) var admin: OrbisAdmin = OrbisAdmin()

    private var locationListened = false
    private var useFakeLocation = false
    
    func setMyUser(user: OrbisUser?, observeOnDatabase: Bool = true) {
        print2("HelperRepository setMyUser: \(user?.username ?? "")")
        
        if user == nil {
            myUserOnDatabaseDisposable?.dispose()
        }

        let udr = UserDefaultsRepository.instance()
        let oldValue = udr.getMyUser()
        
        udr.setMyUser(user: user)
        myUserSubject.onNext(user)
        myDoubleUserSubject.onNext((oldValue, user))
        
        if observeOnDatabase {
            observeMyUserOnDatabase()
        }
    }
    
    func setActiveGroup(group: Group?, updateUser: Bool) {
        let udr = UserDefaultsRepository.instance()
        let prevGroup = udr.getActiveGroup()
        udr.setActiveGroup(group: group)
        activeGroupSubject.onNext((prevGroup, group))
        
        guard let user = UserDefaultsRepository.instance().getMyUser(), updateUser else {
            return
        }
        
        if let key = group?.key {
            UserDAO.saveActiveGroup(userId: user.uid, groupId: key)
                .subscribe(onSuccess: { _ in }, onError: { _ in })
                .disposed(by: bag)
        }
        else {
            UserDAO.clearActiveGroup(userId: user.uid)
                .subscribe(onSuccess: { _ in }, onError: { _ in })
                .disposed(by: bag)
        }
    }

    func onGroupEdited(group: Group) {
        groupEditedSubject.onNext(group)
        let activeGroup = UserDefaultsRepository.instance().getActiveGroup()
        if group.key == activeGroup?.key {
            setActiveGroup(group: group, updateUser: false)
        }
    }
    
    func setLocation(location: Coordinates?) {
        if locationListened {
            return
        }
        
        locationListened = true
        
        if useFakeLocation {
            postFakeLocation()
        }
        else {
            UserDefaultsRepository.instance().setLocation(location: location)
            locationSubject.onNext(location)
        }
    }
    
    func getLocation() -> Coordinates? {
        do {
            return try locationSubject.value()
        } catch {
            return nil
        }
    }

    private func postFakeLocation() {
        let location = barraDaTijuca
        UserDefaultsRepository.instance().setLocation(location: location)
        locationSubject.onNext(location)
    }
    
    func onRegistered(user: OrbisUser?, group: Group?) {
        print2("HelperRepository: onRegistered \(String(describing: user?.username))")
        setMyUser(user: user)
        setActiveGroup(group: group, updateUser: false)
        
        guard let user = user else {
            return
        }
        
        InstanceID.instanceID().instanceID { [weak self] (result, error) in
            if let error = error {
                print("[Push] Error fetching remote instance ID: \(error)")
            }
            else if let result = result {
                print("[Push] Remote instance ID token: \(result.token)")
                
                guard let this = self else { return }
                
                UserDAO.changeSubscriptionToItemsBeingFollowed(userId: user.uid, subscribe: true)
                    .andThen(UserDAO.saveFcmToken(userId: user.uid, token: result.token))
                    .subscribe(onCompleted: {
                        print2("[Push] changeSubscriptionToItemsBeingFollowed onRegistered completed")
                    }, onError: {
                        error in print2(error)
                    })
                    .disposed(by: this.bag)
            }
        }
    }
    
    func onLogout() {
        setMyUser(user: nil)
        setActiveGroup(group: nil, updateUser: false)
        logoutObservable.onNext(true)
    }
    
    private func observeMyUserOnDatabase() {
        guard let myUser = UserDefaultsRepository.instance().getMyUser() else {
            return
        }
        
        myUserOnDatabaseDisposable?.dispose()
    
        myUserOnDatabaseDisposable =
            applicationFinishLaunchingSubject
                .flatMap { (finished : Bool) -> Observable<OrbisUser?> in
                    if finished {
                        print2("myUserChange application finished")
                        return UserDAO.userChildEventsObservable(user: myUser)
                    }
                    else {
                        print2("myUserChange application not finished")
                        return Observable.never()
                    }
                }
                .subscribe(onNext: { [weak self] (user: OrbisUser?) in
                    //print2("myUserChange: \(String(describing: user))")
                    print2("myUserChange checkIn key: \(String(describing: user?.checkIn?.placeKey)) valid: \(String(describing: user?.checkIn?.valid))")
                    
                    if let user = user {
                        self?.setMyUser(user: user, observeOnDatabase: false)
                    }
                    
                }, onError: { (error: Error) in
                    print2("myUserChange error")
                    print2(error)
                })
        
        bag.insert(myUserOnDatabaseDisposable!)
    }
    
    // Not being used
    func selectPlace(wrapper: PlaceWrapper) {
        selectedPlace = wrapper
    }

    // Not being used
    func selectGroup(group: Group) {
        selectedGroup = group
    }

    private func observeAdmin() {
        applicationFinishLaunchingSubject
            .flatMap { (finished : Bool) -> Observable<OrbisAdmin?> in
                if finished {
                    return AdminDAO.observeAdmin()
                }
                else {
                    return Observable.never()
                }
            }
            .subscribe(onNext: { [weak self] admin in
                print2("observeAdmin: \(String(describing: admin))")
                if let a = admin {
                    self?.admin = a
                }
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }
}
