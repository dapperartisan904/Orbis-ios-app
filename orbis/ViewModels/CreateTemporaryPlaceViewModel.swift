//
//  CreateTemporaryPlaceViewModel.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 27/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import GeoFire

class CreateTemporaryPlaceViewModel : OrbisViewModel {
    
    let mainSubject = PublishSubject<TableOperation>()
    let errorSubject = PublishSubject<Error>()
    
    func create() {
        let gpsLocation = OrbisGPSLocation.instance()
        let pvm = PresenceEventViewModel.instance()
        
        guard
            let user = UserDefaultsRepository.instance().getMyUser(),
            let coordinates = gpsLocation.coordinates,
            let geohash = coordinates.toCLLocationCoordinate2D().geohash(),
            let name = gpsLocation.name,
            let key = PlaceDAO.newKey()
        else {
            print2("createTemporaryPlace early return[1]")
            return
        }
    
        if gpsLocation.status == .processing {
            print2("createTemporaryPlace early return[2]")
            return
        }

        let place: Place = Place(key: key,
                               name: name,
                               type: PlaceType.location.valueForDB(),
                               coordinates: coordinates,
                               geohash: geohash,
                               lowercaseName: name.lowercased(),
                               userCreatedKey: user.uid,
                               groupCreatedKey: user.activeGroupId,
                               groupEditedKey: nil,
                               userEditedKey: nil,
                               description: nil,
                               address: nil,
                               temporary: true,
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
        
        gpsLocation.status = .processing
        mainSubject.onNext(TableOperation.ReloadOperation())
        
        CloudFunctionsDAO.checkInAtTemporaryPlaceIsAllowed(userKey: user.uid, coordinates: coordinates)
            .flatMap { (allowed : Bool) -> Single<HandlePresenceEventResponse?> in
                print2("checkInAtTemporaryPlaceIsAllowed result: \(allowed)")
                pvm.setProcessingCheckInOfPlaceKey(placeKey: key)
                return PlaceDAO.createPlace(place: place)
            }
            .subscribe(onSuccess: { response in
                guard let response = response else { return }
                print2("temporary place created")
                
                gpsLocation.status = .created
                pvm.onCheckInSuccess(response: response, place: place, proceedToMap: true)
                
            }, onError: { [weak self] error in
                if pvm.processingCheckInOfPlaceKey == place.key {
                    pvm.clearPlaceBeingProcessed()
                }
                
                gpsLocation.status = gpsLocation.prevStatus!
                self?.errorSubject.onNext(error)
                print2(error)
            })
            .disposed(by: bag)
    }
    
}
