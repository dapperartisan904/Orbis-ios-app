//
//  UsersOfGroupViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 25/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class UsersOfGroupViewModel : OrbisViewModel {
    
    let group: Group
    var users = [OrbisUser]()
    var roles = [String : [Roles]]()
    let defaultSubject = PublishSubject<Any>()
    let tableOperationSubject = PublishSubject<TableOperation>()
    
    init(group: Group) {
        self.group = group
        super.init()
    }
    
    func load() {
        defaultSubject.onNext(OrbisAction.taskStarted)
        
        UserDAO.loadUsersOfGroup(groupKey: group.key!)
            .subscribe(onSuccess: { [weak self] data in
                guard let this = self else { return }
                let roles = data.1
                let users = Array(data.0.values)
                    .filter { user in
                        guard let r = roles[user.uid] else { return false }
                        return r.contains(Roles.member) || r.contains(Roles.administrator)
                    }
                    .sort(roles: roles)
                
                print2("loadUsersOfGroup count: \(users.count)")
                
                this.users = users
                this.roles = roles
                this.defaultSubject.onNext(OrbisAction.taskFinished)
                this.observeChanges()
                
            }, onError: { [weak self] error in
                print2("loadUsersOfGroup error \(error)")
                guard let this = self else { return }
                this.defaultSubject.onNext(OrbisAction.taskFailed)
            })
            .disposed(by: bag)
    }
    
    func myUserIsAdministrator() -> Bool {
        guard let user = UserDefaultsRepository.instance().getMyUser() else {
            return false
        }
        return isAdministrator(user: user)
    }
    
    func isAdministrator(user: OrbisUser) -> Bool {
        return roles[user.uid]?.contains(Roles.administrator) ?? false
    }
    
    func isMember(user: OrbisUser) -> Bool {
        return roles[user.uid]?.contains(Roles.member) ?? false
    }
    
    func memberMenuOptions(user: OrbisUser) -> [MemberMenuOptions] {
        var options = [MemberMenuOptions]()
        
        if isAdministrator(user: user) {
            options.append(MemberMenuOptions.removeAdmin)
        }
        else {
            options.append(MemberMenuOptions.makeAdmin)
        }
        
        if isMember(user: user) && user.uid != UserDefaultsRepository.instance().getMyUser()?.uid {
            options.append(MemberMenuOptions.ban)
        }
        
        return options
    }
    
    private func indexOf(userId: String) -> Int? {
        return users.firstIndex(where: { $0.uid == userId })
    }
    
    private func observeChanges() {
        RoleDAO.allRolesInChildChangesGroup(groupKey: group.key!)
            .subscribe(onNext: { [weak self] changes in
                print2("observe role changes in group: \(changes)")
                self?.onRolesChanged(userId: changes.0, newRoles: changes.1)
            }, onError: { error in
                print2("observe role changes in group error: \(error)")
            })
            .disposed(by: bag)
    }
    
    private func onRolesChanged(userId: String, newRoles: [Roles]) {
        guard let prevRoles = roles[userId] else { return }
        
        // Check if roles really changed
        if prevRoles.count == newRoles.count {
            if prevRoles.first(where: { !newRoles.contains($0) }) == nil {
                return
            }
        }
    
        roles[userId] = newRoles
        
        guard let index = indexOf(userId: userId) else { return }
        
        if !newRoles.contains(Roles.member) && !newRoles.contains(Roles.administrator) {
            users.remove(at: index)
            tableOperationSubject.onNext(TableOperation.DeleteOperation(index: index))
        }
        else {
            tableOperationSubject.onNext(TableOperation.UpdateOperation(index: index))
        }
    }
    
    func optionSelected(option: MemberMenuOptions, user: OrbisUser) {
        var role: Roles? = nil
        var add: Bool = false
        
        switch option {
        case .ban:
            role = Roles.member
        case .removeAdmin:
            role = Roles.administrator
        case .makeAdmin:
            role = Roles.administrator
            add = true
        }
    
        guard let r = role else { return }
        
        RoleDAO.saveRoleInUser(groupId: group.key!, userId: user.uid, role: r, add: add, isMainAction: true)
            .subscribe(onSuccess: { _ in
                
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }
}
