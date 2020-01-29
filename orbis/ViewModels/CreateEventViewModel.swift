//
//  CreateEventViewModel.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 29/04/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

/*
    Used for edit event too
 */
class CreateEventViewModel : OrbisViewModel {
    
    var name: String?
    var details: String?
    var link: String?
    var time: Date?
    var date: Date?
    
    let place: Place
    var event: OrbisPost?
    var saving = false
    let editing: Bool
    
    let defaultSubject = PublishSubject<Any>()
    
    init(place: Place, event: OrbisPost?) {
        self.place = place
        self.event = event
        self.editing = event != nil
        self.name = event?.title
        self.details = event?.details
        self.link = event?.link
        
        if let t = event?.timeTimestamp {
            time = Date(timeIntervalSince1970: Double(t/1000))
        }
        
        if let t = event?.dateTimestamp {
            date = Date(timeIntervalSince1970: Double(t/1000))
        }
    }
    
    func save() {
        if saving {
            return
        }
    
        if (name ?? "").isEmpty {
            defaultSubject.onNext(Words.errorCreateEventName)
            return
        }
        
        if date == nil {
            defaultSubject.onNext(Words.errorCreateEventDate)
            return
        }
        
        let udr = UserDefaultsRepository.instance()
        let group = udr.getActiveGroup()
        
        if event == nil {
            guard
                let key = PostDAO.newKey(),
                let user = udr.getMyUser(),
                let location = HelperRepository.instance().getLocation()
            else {
                defaultSubject.onNext(Words.errorGeneric)
                return
            }
            
            event = OrbisPost(
                coordinates: location,
                geohash: location.toCLLocationCoordinate2D().geohash(),
                imageUrls: nil,
                postKey: key,
                timestamp: nil,
                serverTimestamp: Int64(Date().timeIntervalSince1970),
                serverTimestamp2: nil,
                dateTimestamp: nil,
                timeTimestamp: nil,
                sponsored: false,
                title: nil,
                details: nil,
                type: PostType.event.rawValue,
                placeKey: place.key,
                userKey: user.uid,
                winnerGroupKey: group?.key,
                loserGroupKey: nil,
                link: nil)
        }
        
        saving = true
        defaultSubject.onNext(OrbisAction.taskStarted)
        
        event!.title = name
        event!.details = details
        event!.link = link
        event!.dateTimestamp = Int64(date!.timeIntervalSince1970)
        event!.serverDate = nil
        
        if let t = time?.timeIntervalSince1970 {
            event!.timeTimestamp = Int64(t)
        }
        
        PostDAO.save(post: event!, group: group, place: place)
            .subscribe(onSuccess: { [weak self] _ in
                guard let this = self else { return }
                this.saving = false
                this.defaultSubject.onNext(OrbisAction.taskFinished)
            }, onError: { [weak self] error in
                guard let this = self else { return }
                this.saving = false
                this.defaultSubject.onNext(ActionAndError(OrbisAction.taskFailed, Words.errorGeneric))
                print2("save event error \(error)")
            })
            .disposed(by: bag)
    }

    func delete() {
        if saving {
            return
        }
        
        guard let event = event else { return }
        
        saving = true
        defaultSubject.onNext(OrbisAction.taskStarted)
        
        PostDAO.delete(post: event)
            .subscribe(onSuccess: { [weak self] _ in
                guard let this = self else { return }
                this.saving = false
                this.defaultSubject.onNext(OrbisAction.taskFinished)
            }, onError: { [weak self] error in
                guard let this = self else { return }
                this.saving = false
                this.defaultSubject.onNext(ActionAndError(OrbisAction.taskFailed, Words.errorGeneric))
                print2("delete event error \(error)")
            })
            .disposed(by: bag)
    }
}
