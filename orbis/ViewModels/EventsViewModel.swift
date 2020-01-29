//
//  EventsViewModel.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 24/04/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseDatabase

class EventsViewModel : OrbisViewModel {
    
    var place: Place?
    var group: Group?
    private(set) var events = [OrbisPost]()
    private(set) var groups = [String : Group]()
    private(set) var places = [String : Place]()
    private(set) var users = [String : OrbisUser]()
    private(set) var attendances = [String : [Attendance]]() // Key: post key
    private var attendancesInProccess = Set<String>() // Post keys of attendances being changed
    private var additionalDataStatus = [String : OrbisAction]()
    
    let defaulSubject = PublishSubject<Any>()
    let tableOperationSubject = PublishSubject<TableOperation>()
    let myUser = UserDefaultsRepository.instance().getMyUser()
    
    init(place: Place) {
        self.place = place
        super.init()
        baseInit()
    }
    
    init(group: Group) {
        self.group = group
        super.init()
        baseInit()
    }
    
    private func baseInit() {
        load()
    }
    
    func getData(index: Int) -> (OrbisPost, Group?, Place?, Int) {
        let event = events[index]
        let group = groups[event.winnerGroupKey ?? ""]
        let place = places[event.placeKey ?? ""]
        let ac = attendancesCount(event: event)
        return (event, group, place, ac)
    }
    
    private func indexOf(postKey: String) -> Int? {
        return events.firstIndex(where: { $0.postKey == postKey })
    }
    
    func attendancesCount(event: OrbisPost) -> Int {
        return attendances[event.postKey]?.filter { $0.statusEnum() == .attending }.count ?? 0
    }
    
    private func load() {
        defaulSubject.onNext(OrbisAction.taskStarted)
        var observable: Single<[OrbisPost]>? = nil
        
        if let place = place {
            observable = PostDAO.loadPostsByPlace(placeKey: place.key)
        }
        else if let group = group {
            observable = PostDAO.loadPostsByGroup(groupKey: group.key!)
        }
        
        guard let obs = observable else {
            return
        }
        
        defaulSubject.onNext(OrbisAction.taskStarted)
        
        obs.flatMap { [weak self] (posts : [OrbisPost]) -> Single<[String : [Attendance]]> in
            guard let this = self else {
                return Single.never()
            }
            
            let events = posts.filter { $0.typeEnum() == PostType.event }
            this.events = events
            
            let postKeys = events.map { $0.postKey! }
            return AttendanceDAO.loadAttendances(postKeys: postKeys, limit: nil)
        }
        .flatMap { [weak self] (attendances : [String : [Attendance]]) -> Single<[Group?]> in
            guard let this = self else {
                return Single.never()
            }
            
            this.attendances = attendances
            let groupKeys = this.events.map { $0.winnerGroupKey! }
            return GroupDAO.loadGroups(groupKeys: groupKeys)
        }
        .flatMap { [weak self] (groups : [Group?]) -> Single<[String : Place]> in
            guard let this = self else {
                return Single.never()
            }
            
            this.groups = groups
                .filter { $0 != nil }
                .map { $0! }
                .toDictionary { $0.key ?? "" }
            
            let placeKeys = this.events.map { $0.placeKey! }
            return PlaceDAO.loadPlaceByKeys(placeKeys: placeKeys)
        }
        .subscribe(onSuccess: { [weak self] places in
            guard let this = self else { return }
            this.places = places
            this.sort()
            this.defaulSubject.onNext(OrbisAction.taskFinished)
            this.observeEventsChildValues()
        }, onError: { [weak self] error in
            guard let this = self else { return }
            this.defaulSubject.onNext((OrbisAction.taskFailed, Words.errorGeneric))
            print2("loadPostsByPlace error: \(error)")
        })
        .disposed(by: bag)
    }
    
    func loadAdditionalDataIfNeeded(event: OrbisPost) {
        let status = additionalDataStatus[event.postKey]
        if status == OrbisAction.taskFailed ||
            status == OrbisAction.taskFinished ||
            status == OrbisAction.taskStarted {
            return
        }
    
        let att = attendances[event.postKey] ?? [Attendance]()
        
        postAdditionalDataStatus(event: event, status: .taskStarted)
        
        var attendances = [Attendance]()
        
        if !att.isEmpty {
            attendances.append(att[0])
        }
        
        if att.count > 1 {
            attendances.append(att[1])
        }
        
        if att.count > 2 {
            attendances.append(att[2])
        }

        let userIds = attendances.map { $0.userId }
            .filter { !users.has(key: $0) }
        
        UserDAO.loadUsersByIds(userIds: userIds)
            .flatMap { [weak self] (loadedUsers : [String : OrbisUser]) -> Single<[String : Group]> in
                guard let this = self else {
                    return Single.never()
                }
            
                loadedUsers.forEach { key, value in
                    this.users[key] = value
                }
                
                var groupKeys = loadedUsers.filter { $0.value.activeGroupId != nil }
                    .map { $0.value.activeGroupId! }
                    .filter { !this.groups.has(key: $0) }
                
                if let k = event.winnerGroupKey, !this.groups.has(key: k) {
                    groupKeys.append(k)
                }
            
                return GroupDAO.loadGrousAsDictionary(groupKeys: groupKeys)
            }
            .flatMap { [weak self] (loadedGroups : [String : Group]) -> Single<Place?> in
                guard let this = self else {
                    return Single.never()
                }

                loadedGroups.forEach { key, value in
                    this.groups[key] = value
                }
                
                if let k = event.placeKey, !this.places.has(key: k) {
                    return PlaceDAO.load(placeKey: k)
                }
                else {
                    return Single.just(nil)
                }
            }
            .subscribe(onSuccess: { [weak self] place in
                guard let this = self else {
                    return
                }

                if let p = place {
                    this.places[p.key] = p
                }
                
                this.postAdditionalDataStatus(event: event, status: .taskFinished)
            }, onError: { [weak self] error in
                guard let this = self else { return }
                this.postAdditionalDataStatus(event: event, status: .taskFailed)
                print2("loadAdditionalData error: \(error)")
            })
            .disposed(by: bag)
    }
    
    private func postAdditionalDataStatus(event: OrbisPost, status: OrbisAction) {
        additionalDataStatus[event.postKey] = status
        
        guard let index = events.firstIndex(of: event) else {
            print2("postAdditionalDataStatus: event index not founded")
            return
        }
        
        tableOperationSubject.onNext(TableOperation.UpdateOperation(index: index))
    }

    func additionalDataStatus(event: OrbisPost) -> OrbisAction {
        return additionalDataStatus[event.postKey] ?? OrbisAction.taskStarted
    }
    
    func getUsersOfAttendances(event: OrbisPost) -> [(OrbisUser, Group?)?] {
        var result = [(OrbisUser, Group?)?]()
        let att = attendances[event.postKey]
        
        for i in 0...2 {
            if let att = att, let a = att.safeGet(index: i), let u = users[a.userId] {
                result.append((u, groups[u.activeGroupId ?? ""]))
            }
            else {
                result.append(nil)
            }
        }
        
        return result
    }
    
    func myAttendanceStatus(event: OrbisPost) -> AttendanceStatus {
        if attendancesInProccess.contains(event.postKey) {
            return AttendanceStatus.undetermined
        }
        
        let status = myAttendance(event: event)?.statusEnum() ?? .notAttending
        //print2("[Attendance] myAttendanceStatus: \(status.rawValue)")
        
        return status
    }
    
    private func myAttendance(event: OrbisPost) -> Attendance? {
        guard
            let u = myUser,
            let atts = attendances[event.postKey],
            let att = atts.first(where: { item in item.userId == u.uid })
        else {
            return nil
        }
        
        return att
    }
    
    func toggleAttendanceStatus(index: Int) {
        toggleAttendanceStatus(event: events[index])
    }
    
    private func toggleAttendanceStatus(event: OrbisPost) {
        guard let u = myUser else { return }
        let oldStatus = myAttendanceStatus(event: event)
        let newStatus = oldStatus.dual()
        
        if newStatus == .undetermined {
            return
        }
        
        attendancesInProccess.insert(event.postKey)
        if let index = indexOf(postKey: event.postKey) {
            tableOperationSubject.onNext(TableOperation.UpdateOperation(index: index))
        }
        
        let att = myAttendance(event: event) ?? Attendance(userId: u.uid, postKey: event.postKey, status: oldStatus.rawValue, serverTimestamp: nil)
        att.status = newStatus.rawValue
        att.serverDate = nil

        //print2("[Attendance] save \(att.status)")
        
        AttendanceDAO.saveAttendance(attendance: att)
            .subscribe(onSuccess: { [weak self] _ in
                guard let this = self else { return }
                this.attendancesInProccess.remove(event.postKey)
                this.putAttendance(att: att, notify: true)
                //print2("[Attendance] save finished")
            }, onError: { [weak self] error in
                print2(error)
                guard let this = self else { return }
                att.status = oldStatus.rawValue
                this.attendancesInProccess.remove(event.postKey)
                this.putAttendance(att: att, notify: true)
                //print2("[Attendance] save error")
            })
            .disposed(by: bag)
    }
    
    private func putAttendance(att : Attendance, notify: Bool) {
        if !attendances.has(key: att.postKey) {
            attendances[att.postKey] = [Attendance]()
        }
    
        var array = attendances[att.postKey]!
        if let a = array.first(where: { $0.userId == att.userId }) {
            a.status = att.status
        }
        else {
            array.append(att)
        }
    
        attendances[att.postKey] = array
        
        if notify {
            if let index = indexOf(postKey: att.postKey) {
                tableOperationSubject.onNext(TableOperation.UpdateOperation(index: index))
            }
        }
    }
    
    func canEdit(event: OrbisPost) -> Bool {
        guard let u = myUser else { return false }
        
        if event.userKey == u.uid {
            return true
        }
        
        guard let k = event.winnerGroupKey else {
            return false
        }
        
        return RolesViewModel.instance().isAdministrator(groupKey: k)
    }
    
    private func observeEventsChildValues() {
        if let place = place {
            PostDAO.postsByPlaceChildValuesObservers(placeKey: place.key!, includeAdditions: true, includeChanges: true).forEach { observer in
                observer.subscribe(onNext: { [weak self] data in
                    let (type, event) = data
                    self?.processDatabaseEvent(type: type, event: event)
                    }, onError: { error in
                        print2(error)
                })
                .disposed(by: bag)
            }
        }
    }

    private func processDatabaseEvent(type: DataEventType, event: OrbisPost?) {
        guard let event = event, event.typeEnum() == PostType.event else {
            return
        }
        
        print2("[EventsViewModel] processDatabaseEvent \(type) Event: \(event.postKey ?? "") \(event.title ?? "")")
    
        if type == .childAdded {
            if indexOf(postKey: event.postKey) != nil {
                return
            }
            
            events.append(event)
            sort()
            tableOperationSubject.onNext(TableOperation.ReloadOperation())
            loadAdditionalDataIfNeeded(event: event)
        }
        else if type == .childChanged {
            if let index = indexOf(postKey: event.postKey) {
                events[index] = event
            }
            else {
                events.append(event)
            }
            
            sort()
            tableOperationSubject.onNext(TableOperation.ReloadOperation())
        }
        else if type == .childRemoved {
            if let index = indexOf(postKey: event.postKey) {
                events.remove(at: index)
                tableOperationSubject.onNext(TableOperation.DeleteOperation(index: index))
            }
        }
    }
    
    private func sort() {
        events.sort { (e0: OrbisPost, e1: OrbisPost) -> Bool in
            guard
                let t0 = e0.dateTimestamp,
                let t1 = e1.dateTimestamp
            else {
                return false
            }
        
            let d0 = Date(timeIntervalSince1970: Double(t0))
            let d1 = Date(timeIntervalSince1970: Double(t1))
        
            switch d0.compare(d1) {
            case .orderedAscending:
                return true
            
            case .orderedDescending:
                return false
            
            case .orderedSame:
                guard
                    let t2 = e0.timeTimestamp,
                    let t3 = e1.timeTimestamp
                else {
                    return false
                }
                
                let d2 = Date(timeIntervalSince1970: Double(t2))
                let d3 = Date(timeIntervalSince1970: Double(t3))
                
                switch d2.compare(d3) {
                case .orderedAscending:
                    return true
                    
                case .orderedDescending:
                    return false
                    
                case .orderedSame:
                    return false
                }
            }
        }
    }
}
