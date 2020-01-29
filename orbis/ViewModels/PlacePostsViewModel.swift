//
//  PlacePostsViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 04/02/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class PlacePostsViewModel : BasePostsViewModel, PostsViewModelContract {
    
    let place: Place
    let defaultSubject = PublishSubject<Any>()
    
    init(place: Place) {
        self.place = place
        super.init()
        set(isLoading: true)
    }
    
    func onViewControllerReady() {
        loadNextChunk()
    }
    
    func loadNextChunk() {
        PostDAO.loadPostsByPlace(placeKey: place.key)
            .flatMap { [weak self] (posts: [OrbisPost]) -> Single<Bool> in
                guard let this = self else {
                    return Single.just(false)
                }
                return this.loadDataObservable(postsLoaded: posts)
            }
            .subscribe(onSuccess: { [weak self] _ in
                self?.set(isLoading: false)
            }, onError: { [weak self] error in
                print2(error)
                self?.defaultSubject.onNext((OrbisAction.taskFailed, Words.errorGeneric))
            })
            .disposed(by: bag)
    }
    
    override func observePostsChildValues() {
        PostDAO.postsByPlaceChildValuesObservers(placeKey: place.key!, includeAdditions: true, includeChanges: false).forEach { observer in
            observer.subscribe(onNext: { [weak self] data in
                let (event, post) = data
                self?.processChildEvent(event: event, post: post)
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
        }
    }
    
    override func set(isLoading: Bool) {
        defaultSubject.onNext(isLoading ? OrbisAction.taskStarted : OrbisAction.taskFinished)
    }
    
    func placedOnHome() -> Bool {
        return false
    }

    func radarTab() -> RadarTab? {
        return nil
    }

}
