//
//  PresenceEventViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class PresenceEventViewModel : OrbisViewModel {
    
    override fileprivate init() { }
    
    private static var shared: PresenceEventViewModel = {
        return create()
    }()
    
    private static func create() -> PresenceEventViewModel {
        let vm = PresenceEventViewModel()
        vm.observeMyUser()
        return vm
    }
    
    // Workaround used when application is reload due language change
    static func recreate() {
        shared = create()
    }
    
    static func instance() -> PresenceEventViewModel {
        return PresenceEventViewModel.shared
    }
    
    let defaultSubject = PublishSubject<Any>()
    let tableOperationSubject = PublishSubject<TableOperation>()
    let checkInResponseSubject = PublishSubject<Bool>()
    
    private var checkInResponse: HandlePresenceEventResponse?
    
    private(set) var processingCheckInOfPlaceKey: String? {
        didSet {
            print2("processingCheckInOfPlaceKey didSet \(processingCheckInOfPlaceKey ?? "")")
            
            var itemKey = processingCheckInOfPlaceKey

            if itemKey == nil {
                itemKey = oldValue
            }
            
            if let key = itemKey {
                tableOperationSubject.onNext(TableOperation.UpdateOperation(itemKey: key))
            }
        }
    }
    
    func setProcessingCheckInOfPlaceKey(placeKey: String) {
        processingCheckInOfPlaceKey = placeKey
    }
    
    // For now used only on create place flow
    func checkInStarted(placeKey: String) {
        processingCheckInOfPlaceKey = placeKey
    }
    
    // For now used only on create place flow
    func checkInFinished(response: HandlePresenceEventResponse?) {
        checkInResponse = response
        processingCheckInOfPlaceKey = nil
    }
    
    func onCheckInSuccess(response: HandlePresenceEventResponse, place: Place, proceedToMap: Bool) {
        place.dominantGroupKey = response.dominance?.winnerGroup?.key
        checkInResponse = response
        checkInResponse?.place = place
        checkInResponseSubject.onNext(true)
        
        if proceedToMap {
            defaultSubject.onNext(Navigation.map())
        }
    }
    
    func consumeCheckInResponse() -> HandlePresenceEventResponse? {
        let response = checkInResponse
        checkInResponse = nil
        return response
    }
    
    func hasCheckInResponse() -> Bool {
        return checkInResponse != nil
    }
    
    func getCheckInResponse() -> HandlePresenceEventResponse? {
        return checkInResponse
    }
    
    func isPlaceBeingProcessed(placeKey: String?) -> Bool {
        guard let placeKey = placeKey else { return false }
        return placeKey == processingCheckInOfPlaceKey || placeKey == checkInResponse?.place?.key
    }
    
    func clearPlaceBeingProcessed() {
        processingCheckInOfPlaceKey = nil
    }
    
    func nextPresenceEventType(place: Place, ignoreProcessingPlaceKey: Bool = false) -> PresenceEventType {
        let checkIn = UserDefaultsRepository.instance().getMyUser()?.checkIn

        if processingCheckInOfPlaceKey == place.key && !ignoreProcessingPlaceKey {
            return PresenceEventType.undetermined
        }

        /*
        if place.isTemporaryAndNotCreated() {
            return PresenceEventType.checkIn
        }
        */
        
        if let checkIn = checkIn, place.key == checkIn.placeKey, checkIn.valid {
            return PresenceEventType.checkOut
        }
        
        return PresenceEventType.checkIn
    }
    
    func savePresenceEvent(place: Place, proceedToMap: Bool = true) {
        if place.deleted {
            defaultSubject.onNext(Words.errorCheckInDeletedPlace)
            return
        }
        
        if processingCheckInOfPlaceKey != nil {
            defaultSubject.onNext(Words.errorPresenceEventInProcess)
            return
        }
       
        let udr = UserDefaultsRepository.instance()

        guard let user = udr.getMyUser() else {
            defaultSubject.onNext(Navigation.register())
            return
        }
        
        let eventType = nextPresenceEventType(place: place)
        if eventType == .undetermined {
            return
        }
        
        if eventType == .checkIn {
            guard let location = HelperRepository.instance().getLocation() else {
                defaultSubject.onNext(Words.errorCheckInNoLocation)
                return
            }
            
            if location.distanceInMeters(toOther: place.coordinates) > maxCheckInDistanceInMeters {
                defaultSubject.onNext(Words.errorCheckInTooFar)
                return
            }
        }

        guard let groupKey = udr.getActiveGroup()?.key else {
            defaultSubject.onNext(Words.errorCheckInNoGroup)
            return
        }
        
        processingCheckInOfPlaceKey = place.key
        
        CloudFunctionsDAO
            .handlePresenceEvent(placeKey: place.key, groupKey: groupKey, userKey: user.uid, eventType: eventType)
            .subscribe(onSuccess: { [weak self] (response: HandlePresenceEventResponse?) in
                //print2("PresenceEventViewModed: handlePresenceEvent eventType: \(eventType) response \(String(describing: response))")

                guard
                    let this = self,
                    let response = response
                else {
                    self?.processingCheckInOfPlaceKey = nil
                    return
                }
                
                if let error = response.error {
                    var rawValue = error
                    var extra: Any? = nil
                    
                    if let start = error.index(of: "["), let end = error.index(of: "]") {
                        rawValue = error.components(separatedBy: "[").first!
                        let range = start..<end
                        extra = error[range]
                    }
                    
                    //let rawValue = error
                    
                    if let cloudError = CloudFunctionsErrors(rawValue: rawValue) {
                        this.defaultSubject.onNext((cloudError, extra))
                    }
                    this.processingCheckInOfPlaceKey = nil
                    return
                }
                
                if eventType == PresenceEventType.checkIn {
                    this.onCheckInSuccess(response: response, place: place, proceedToMap: proceedToMap)
                }
                else {
                    this.processingCheckInOfPlaceKey = nil
                }
                
            }, onError: { [weak self] (error: Error) in
                self?.processingCheckInOfPlaceKey = nil
                print2("handlePresenceEvent error \(error)")
            })
            .disposed(by: bag)
    }
    
    // Observers my user with focus at user.checkIn
    private func observeMyUser() {
        HelperRepository.instance().myDoubleUserSubject
            .subscribe(onNext: { [weak self] (value: (OrbisUser?, OrbisUser?)) in
                guard let this = self else {
                    return
                }
                
                let (oldValue, newValue) = value
                
                if oldValue?.checkIn?.placeKey == newValue?.checkIn?.placeKey {
                    return
                }
                
                var keys = [String]()
                
                if let p0 = oldValue?.checkIn?.placeKey {
                    keys.append(p0)
                }
                
                if let p1 = newValue?.checkIn?.placeKey {
                    keys.append(p1)
                }
                
                this.tableOperationSubject.onNext(TableOperation.UpdateOperation(itemKeys: keys))
                
            }, onError: { (error: Error) in
                print2(error)
            })
            .disposed(by: bag)
    }
}
