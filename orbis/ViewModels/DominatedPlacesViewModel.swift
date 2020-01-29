//
//  DominatedPlacesViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 25/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class DominatedPlacesViewModel : OrbisViewModel {

    private(set) var places = [Place]()
    let group: Group
    let defaulSubject = PublishSubject<Any>()
    
    init(group: Group) {
        self.group = group
        super.init()
        self.load()
    }
    
    func load() {
        print2("loadPlacesDominatedByGroup started")
        
        defaulSubject.onNext(OrbisAction.taskStarted)
        PlaceDAO.loadPlacesDominated(by: group, myLocation: HelperRepository.instance().getLocation())
            .subscribe(onSuccess: { [weak self] places in
                guard let this = self else { return }
                print2("loadPlacesDominatedByGroup finished. Count: \(places.count)")
                this.places.append(contentsOf: places)
                this.defaulSubject.onNext(OrbisAction.taskFinished)
            }, onError: { [weak self] error in
                guard let this = self else { return }
                this.defaulSubject.onNext((OrbisAction.taskFailed, Words.errorGeneric))
                print2("loadPlacesDominatedByGroup error: \(error)")
            })
            .disposed(by: bag)
    }
    
    func index(of placeKey: String) -> Int? {
        return places.firstIndex(where: { $0.key == placeKey })
    }
}
