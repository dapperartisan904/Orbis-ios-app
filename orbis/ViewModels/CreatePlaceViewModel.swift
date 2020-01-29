//
//  CreatePlaceViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 18/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseDatabase
import FirebaseFirestore
import GeoFire

class CreatePlaceViewModel : OrbisViewModel {
    
    private(set) var activeGroup: Group?
    private(set) var placeType: PlaceType?
    private(set) var placeName: String?
    var address: String?
    
    let defaultSubject = PublishSubject<Any>()
    private var creatingPlace = false
    
    override init() {
        activeGroup = UserDefaultsRepository.instance().getActiveGroup()
        super.init()
    }
    
    func process(placeType: PlaceType?, placeName: String?) {
        print2("Process \(String(describing: placeType)) \(String(describing: placeName))")
        
        self.placeType = placeType
        self.placeName = placeName
        
        if placeType != nil && placeName != nil {
            defaultSubject.onNext(Navigation.createPlaceStepTwo(viewModel: self))
        }
    }
    
    func createPlace(location: Coordinates) {
        if creatingPlace {
            return
        }
    
        guard let user = UserDefaultsRepository.instance().getMyUser() else {
            defaultSubject.onNext(Words.errorCreatePlace3)
            return
        }
        
        guard
            let key = PlaceDAO.newKey(),
            let pt = placeType,
            let geohash = location.toCLLocationCoordinate2D().geohash()
        else {
            defaultSubject.onNext(Words.errorGeneric)
            return
        }
        
        let group = UserDefaultsRepository.instance().getActiveGroup()
        print2("createPlace: user.activeGroupId: \(user.activeGroupId ?? "") activeGroup[1]: \(activeGroup?.key ?? "") \(activeGroup?.name ?? "") activeGroup[2]: \(group?.key ?? "") \(group?.name ?? "")")
        
        creatingPlace = true
        defaultSubject.onNext(OrbisAction.taskStarted)
        
        let place = Place(key: key,
                         name: placeName!,
                         type: pt.valueForDB(),
                         coordinates: location,
                         geohash: geohash,
                         lowercaseName: placeName!.lowercased(),
                         userCreatedKey: user.uid,
                         groupCreatedKey: activeGroup?.key,
                         groupEditedKey: nil,
                         userEditedKey: nil,
                         description: nil,
                         address: address,
                         temporary: false,
                         wasTemporary: false,
                         googlePlaceId: nil,
                         source: PlaceSource.user.rawValue,
                         deleted: false,
                         csvHash: nil,
                         csvUrl: nil,
                         phone: nil,
                         cityPlusCategoryKey2: nil,
                         ownerId: nil,
                         dominantGroupKey: nil,
                         creationDate: nil,
                         subscriptionDate: nil,
                         lastCheckInDate: nil)
        
        let presenceEventViewModel = PresenceEventViewModel.instance()
        presenceEventViewModel.checkInStarted(placeKey: key)
        
        PlaceDAO.createPlace(place: place)
            .flatMap { (checkInResponse : HandlePresenceEventResponse?) -> Single<OrbisCircle> in
                presenceEventViewModel.checkInFinished(response: checkInResponse)
                return CircleDAO.loadCircle(placeKey: key)
            }
            .subscribe(onSuccess: { [weak self] circle in
                self?.creatingPlace = false
                MapViewModel.instance().addCircle(circle: circle, createdByMe: true)
                self?.defaultSubject.onNext(OrbisAction.taskFinished)
            }, onError: { [weak self] error in
                print2(error)
                self?.defaultSubject.onNext(OrbisAction.taskFailed)
            })
            .disposed(by: bag)
    }
}
