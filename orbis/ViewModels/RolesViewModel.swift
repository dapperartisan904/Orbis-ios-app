//
//  RolesViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 27/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import Firebase
import RxSwift

class RolesViewModel : OrbisViewModel {
    
    private static var shared: RolesViewModel = {
        return RolesViewModel()
    }()
    
    // Workaround used when application is reload due language change
    static func recreate() {
        shared = RolesViewModel()
    }
    
    static func instance() -> RolesViewModel {
        return RolesViewModel.shared
    }

    // Key: group key
    private(set) var rolesByGroup = [String : [Roles]]()
    
    // Key: place key
    private(set) var rolesByPlace = [String : [Roles]]()
    
    // Values: group or place key
    private var followsBeingProcessed = Set<String>()
    
    // Values: group key
    private var membershipsBeingProcessed = Set<String>()
    
    // Value: group key
    let roleByGroupChangedSubject = PublishSubject<String>()
    
    // Value: place key
    let roleByPlaceChangedSubject = PublishSubject<String>()
    
    let rolesByGroupLoadedSubject = BehaviorSubject<(String?, Bool)>(value: (nil, true))
    let rolesByPlaceLoadedSubject = BehaviorSubject<(String?, Bool)>(value: (nil, true))
    let defaultSubject = PublishSubject<Any>()
    
    private var currentUser: OrbisUser? = nil
    private var initialLoad = true
    private var applicationDidLoad = false
    
    private var contentBag = DisposeBag()
    
    override private init() {
        super.init()
        observeApplicationFinishLaunching()
        observeLogout()
    }
    
    private func observeLogout() {
        HelperRepository.instance()
            .logoutObservable
            .subscribe(onNext: { [weak self] _ in
                guard let this = self else { return }
                this.contentBag = DisposeBag()
                this.rolesByGroup.removeAll()
                this.rolesByPlace.removeAll()
                this.followsBeingProcessed.removeAll()
                this.membershipsBeingProcessed.removeAll()
            })
            .disposed(by: bag)
    }
    
    private func observeApplicationFinishLaunching() {
        HelperRepository.instance().applicationFinishLaunchingSubject
            .subscribe(onNext: { [weak self] finished in
                guard let this = self else { return }
                
                print2("[Roles] FinishLaunching: \(finished) alreadyDidLoad: \(this.applicationDidLoad)")
                
                if finished && !this.applicationDidLoad {
                    this.applicationDidLoad = true
                    this.observeMyUser()
                }
            })
            .disposed(by: bag)
    }
    
    private func observeMyUser() {
        print2("[Roles] observeMyUser")
        
        HelperRepository.instance().myUserSubject
            .subscribe(onNext: { [weak self] user in
                guard let this = self else { return }
                
                print2("[Roles] observedUser: \(user?.username ?? "nil")")
                
                if this.initialLoad || this.currentUser?.uid != user?.uid {
                    this.initialLoad = false
                    this.currentUser = user
                    this.loadRolesByGroup()
                    this.loadRolesByPlace()
                }
            })
            .disposed(by: bag)
    }
    
    private func loadRolesByGroup() {
        print2("[Roles] loadRolesByGroup User: \(currentUser?.username ?? "nil")")
        
        guard let myUser = currentUser else {
            rolesByGroup.removeAll()
            rolesByGroupLoadedSubject.onNext((nil, true))
            return
        }
        
        RoleDAO.getRolesOfUserInGroups(userId: myUser.uid)
            .subscribe(onSuccess: { [weak self] (result: [String : [Roles]]) in
                guard
                    let this = self,
                    this.currentUser?.uid == myUser.uid
                else {
                    return
                }

                this.rolesByGroup = result
                
                let tuple = try? this.rolesByGroupLoadedSubject.value()
                if tuple?.0 != myUser.uid || tuple?.1 == false {
                    this.rolesByGroupLoadedSubject.onNext((myUser.uid, true))
                    this.observeRolesByGroup()
                }
            }, onError: { (error: Error) in
                print2(error)
            })
            .disposed(by: contentBag)
    }
    
    private func loadRolesByPlace() {
        print2("[Roles] loadRolesByPlace User: \(currentUser?.username ?? "nil")")
        
        guard let myUser = currentUser else {
            rolesByPlace.removeAll()
            rolesByPlaceLoadedSubject.onNext((nil, true))
            return
        }
        
        RoleDAO.rolesOfUserInPlaces(userId: myUser.uid)
            .subscribe(onSuccess: { [weak self] (result: [String : [Roles]]) in
                guard
                    let this = self,
                    this.currentUser?.uid == myUser.uid
                else {
                    return
                }
                
                this.rolesByPlace = result
                
                let tuple = try? this.rolesByPlaceLoadedSubject.value()
                if tuple?.0 != myUser.uid || tuple?.1 == false {
                    this.rolesByPlaceLoadedSubject.onNext((myUser.uid, true))
                    this.observeRolesByPlace()
                }
                }, onError: { (error: Error) in
                    print2(error)
            })
            .disposed(by: contentBag)
    }
    
    private func observeRolesByGroup() {
        guard let myUser = currentUser else {
            return
        }
        
        RoleDAO.rolesOfUserInGroupsChildAdditions(userId: myUser.uid)
            .subscribe(onNext: { [weak self] (result: (String, [Roles])) in
                guard let this = self else {
                    return
                }

                this.rolesByGroup[result.0] = result.1
                this.roleByGroupChangedSubject.onNext(result.0)
                
                let tuple = try? this.rolesByGroupLoadedSubject.value()
                if tuple?.0 != myUser.uid || tuple?.1 == false {
                    print2("[Roles] observeRolesByGroup addition User: \(myUser.username ?? "nil")")
                    this.rolesByGroupLoadedSubject.onNext((myUser.uid, true))
                }

            }, onError: { (error: Error) in
                print2(error)
            })
            .disposed(by: contentBag)
        
        RoleDAO.rolesOfUserInGroupsChildChanges(userId: myUser.uid)
            .subscribe(onNext: { [weak self] (result: (String, [Roles])) in
                guard let this = self else {
                    return
                }
                
                this.rolesByGroup[result.0] = result.1
                this.roleByGroupChangedSubject.onNext(result.0)
                
                let tuple = try? this.rolesByGroupLoadedSubject.value()
                if tuple?.0 != myUser.uid || tuple?.1 == false {
                    print2("[Roles] observeRolesByGroup change User: \(myUser.username ?? "nil")")
                    this.rolesByGroupLoadedSubject.onNext((myUser.uid, true))
                }
            }, onError: { (error: Error) in
                print2(error)
            })
            .disposed(by: contentBag)
    }
    
    private func observeRolesByPlace() {
        guard let myUser = currentUser else {
            return
        }
        
        RoleDAO.rolesOfUserInPlacesChildAdditions(userId: myUser.uid)
            .subscribe(onNext: { [weak self] (result: (String, [Roles])) in
                guard let this = self else {
                    return
                }
                
                //print2("ObservedRolesByPlace [Addition]")
                this.rolesByPlace[result.0] = result.1
                this.roleByPlaceChangedSubject.onNext(result.0)
                
                let tuple = try? this.rolesByPlaceLoadedSubject.value()
                if tuple?.0 != myUser.uid || tuple?.1 == false {
                    this.rolesByPlaceLoadedSubject.onNext((myUser.uid, true))
                }
                
            }, onError: { (error: Error) in
                print2(error)
            })
            .disposed(by: contentBag)
        
        RoleDAO.rolesOfUserInPlacesChildChanges(userId: myUser.uid)
            .subscribe(onNext: { [weak self] (result: (String, [Roles])) in
                guard let this = self else {
                    return
                }
                
                this.rolesByPlace[result.0] = result.1
                this.roleByPlaceChangedSubject.onNext(result.0)
                
                let tuple = try? this.rolesByPlaceLoadedSubject.value()
                if tuple?.0 != myUser.uid || tuple?.1 == false {
                    this.rolesByPlaceLoadedSubject.onNext((myUser.uid, true))
                }
                
                }, onError: { (error: Error) in
                    print2(error)
                })
            .disposed(by: contentBag)
    }
    
    func followStatus(groupKey: String) -> RoleStatus {
        if followsBeingProcessed.contains(groupKey) {
            return RoleStatus.undetermined
        }
        
        guard let roles = rolesByGroup[groupKey] else {
            return RoleStatus.inactive
        }
    
        return roles.contains(Roles.follower) ? RoleStatus.active : RoleStatus.inactive
    }
    
    func followStatus(placeKey: String) -> RoleStatus {
        if followsBeingProcessed.contains(placeKey) {
            return RoleStatus.undetermined
        }
        
        guard let roles = rolesByPlace[placeKey] else {
            return RoleStatus.inactive
        }
        
        return roles.contains(Roles.follower) ? RoleStatus.active : RoleStatus.inactive
    }
    
    func memberStatus(groupKey: String) -> (RoleStatus, Bool) {
        if membershipsBeingProcessed.contains(groupKey) {
            return (RoleStatus.undetermined, false)
        }
        
        guard let roles = rolesByGroup[groupKey] else {
            return (RoleStatus.inactive, false)
        }
        
        let status = roles.contains(Roles.member) ? RoleStatus.active : RoleStatus.inactive
        let isActiveGroup = groupKey == UserDefaultsRepository.instance().getActiveGroup()?.key
        return (status, isActiveGroup)
    }

    func isMemberOrAdministrator(groupKey: String) -> Bool {
        return isMember(groupKey: groupKey) || isAdministrator(groupKey: groupKey)
    }
    
    func isMember(groupKey: String) -> Bool {
        return rolesByGroup[groupKey]?.contains(Roles.member) ?? false
    }

    func isAdministrator(groupKey: String) -> Bool {
        return rolesByGroup[groupKey]?.contains(Roles.administrator) ?? false
    }
    
    func isAdministratorOfSome(groupKeys: [String]) -> Bool {
        if groupKeys.isEmpty {
            return false
        }
        
        for i in 0...groupKeys.count-1 {
            if isAdministrator(groupKey: groupKeys[i]) {
                return true
            }
        }
        return false
    }
    
    func toggleFollowRole(groupKey: String) {
        guard let user = UserDefaultsRepository.instance().getMyUser() else {
            defaultSubject.onNext(Navigation.register())
            return
        }
    
        let newStatus = followStatus(groupKey: groupKey).dual()
        if newStatus == .undetermined {
            return
        }
    
        followsBeingProcessed.insert(groupKey)
        roleByGroupChangedSubject.onNext(groupKey)
        
        RoleDAO.saveRoleInGroup(userId: user.uid, groupId: groupKey, role: Roles.follower, add: newStatus == .active)
            .subscribe(onSuccess: { [weak self] (result: Bool) in
                guard let this = self else { return }
                this.followsBeingProcessed.remove(groupKey)
                this.roleByGroupChangedSubject.onNext(groupKey)
            }, onError: { [weak self] (error: Error) in
                print2(error)
                guard let this = self else { return }
                this.followsBeingProcessed.remove(groupKey)
                this.roleByGroupChangedSubject.onNext(groupKey)
                this.defaultSubject.onNext(Words.errorGeneric)
            })
            .disposed(by: contentBag)
    }
    
    func toggleFollowRole(placeKey: String) {
        guard let user = UserDefaultsRepository.instance().getMyUser() else {
            defaultSubject.onNext(Navigation.register())
            return
        }
        
        let newStatus = followStatus(placeKey: placeKey).dual()
        if newStatus == .undetermined {
            return
        }
        
        followsBeingProcessed.insert(placeKey)
        roleByGroupChangedSubject.onNext(placeKey)
        
        RoleDAO.saveRoleInPlace(userId: user.uid, placeId: placeKey, role: Roles.follower, add: newStatus == .active)
            .subscribe(onSuccess: { [weak self] (result: Bool) in
                guard let this = self else { return }
                this.followsBeingProcessed.remove(placeKey)
                this.roleByPlaceChangedSubject.onNext(placeKey)
            }, onError: { [weak self] (error: Error) in
                print2(error)
                guard let this = self else { return }
                this.followsBeingProcessed.remove(placeKey)
                this.roleByPlaceChangedSubject.onNext(placeKey)
                this.defaultSubject.onNext(Words.errorGeneric)
            })
            .disposed(by: contentBag)
    }
    
    func toggleMemberRole(group: Group) {
        guard let user = UserDefaultsRepository.instance().getMyUser() else {
            defaultSubject.onNext(Navigation.register())
            return
        }
        
        guard let groupKey = group.key else {
            return
        }
        
        let (prevStatus, isActiveGroup) = memberStatus(groupKey: groupKey)
        if prevStatus == .active && !isActiveGroup {
            HelperRepository.instance().setActiveGroup(group: group, updateUser: true)
            return
        }

        let newStatus = prevStatus.dual()
        if newStatus == .undetermined {
            return
        }
        
        print2("toggleMemberRole to \(newStatus)")
        
        membershipsBeingProcessed.insert(groupKey)
        roleByGroupChangedSubject.onNext(groupKey)
        
        RoleDAO.saveRoleInGroup(userId: user.uid, groupId: groupKey, role: Roles.member, add: newStatus == .active)
            .subscribe(onSuccess: { [weak self] (result: Bool) in
                print2("[Push] RoleDAO.saveRoleInGroup onSuccess")
                guard let this = self else { return }
                this.membershipsBeingProcessed.remove(groupKey)
                this.roleByGroupChangedSubject.onNext(groupKey)
            }, onError: { [weak self] (error: Error) in
                print2("[Push] RoleDAO.saveRoleInGroup error")
                print2(error)
                guard let this = self else { return }
                this.membershipsBeingProcessed.remove(groupKey)
                this.roleByGroupChangedSubject.onNext(groupKey)
                this.defaultSubject.onNext(Words.errorGeneric)
            })
            .disposed(by: contentBag)
    }
    
    func removeMemberRole(group: Group) {
        guard
            let user = UserDefaultsRepository.instance().getMyUser(),
            let groupKey = group.key
        else {
            return
        }
        
        let (prevStatus, _) = memberStatus(groupKey: groupKey)
        if prevStatus == .inactive || prevStatus == .inactive {
            return
        }
    
        membershipsBeingProcessed.insert(groupKey)
        roleByGroupChangedSubject.onNext(groupKey)
        
        RoleDAO.saveRoleInGroup(userId: user.uid, groupId: groupKey, role: Roles.member, add: false)
            .subscribe(onSuccess: { [weak self] (result: Bool) in
                guard let this = self else { return }
                this.membershipsBeingProcessed.remove(groupKey)
                this.roleByGroupChangedSubject.onNext(groupKey)
            }, onError: { [weak self] (error: Error) in
                print2(error)
                guard let this = self else { return }
                this.membershipsBeingProcessed.remove(groupKey)
                this.roleByGroupChangedSubject.onNext(groupKey)
                this.defaultSubject.onNext(Words.errorGeneric)
            })
            .disposed(by: contentBag)
    }
    
    func groupsBeingFollowed() -> [String] {
        return rolesByGroup
            .filter { $0.value.contains(Roles.follower) }
            .map { $0.key }
    }
    
    func placesBeingFollowed() -> [String] {
        return rolesByPlace
            .filter { $0.value.contains(Roles.follower) }
            .map { $0.key }
    }
}
