//
//  FeedsByDistanceViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 12/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import GeoFire
import RxSwift

class FeedsByDistanceViewModel : BasePostsViewModel, PostsViewModelContract {

    private var query: GFCircleQuery?
    private var queryIsReady = false
    
    var deviceLocation: Coordinates? = nil
    private var postsLocationChunk = [String : CLLocation]()
    
    private var setupDisposable: Disposable?

    deinit {
        query?.removeAllObservers()
    }
    
    override func shouldObservePostChildAdditions() -> Bool {
        return false
    }
    
    override func adMobsEnabled() -> Bool {
        return HelperRepository.instance().admin.adMobEnabled
    }
    
    override func onLogout() {
        super.onLogout()
        postsLocationChunk.removeAll()
        tableOperationSubject.onNext(TableOperation.ReloadOperation())
    }
    
    func onViewControllerReady() {
        loadNextChunk()
    }
    
    func loadNextChunk() {
        if query == nil {
            set(isLoading: true)
            createQuery()
        }
    }

    private func createQuery() {
        var location: Coordinates?
        
        HelperRepository.instance()
            .locationSubject
            .filter { (loc: Coordinates?) in
                return loc != nil
            }
            .flatMap { (loc: Coordinates?) -> Observable<(String?, Bool)> in
                location = loc
                return LikesViewModel.instance().myLikesLoadedSubject
            }
            .filter { tuple in
                let (userId, loaded) = tuple
                return userId == UserDefaultsRepository.instance().getMyUser()?.uid && loaded
            }
            .flatMap { _ in
                return HiddenPostViewModel.instance().myHiddenPostsLoadedSubject
            }
            .filter { tuple in
                let (userId, loaded) = tuple
                return userId == UserDefaultsRepository.instance().getMyUser()?.uid && loaded
            }
            .subscribe(
                onNext: { [weak self] _ in
                    guard
                        let this = self,
                        let location = location
                    else {
                        return
                    }
                    
                    self?.setupDisposable?.dispose()
                    self?.setupDisposable = nil
                    
                    let query = GeoFireDAO.postsGeoFire.query(at: location.toCLLocation(), withRadius: feedsByDistanceInMeters / 1000)
                    
                    query.observe(.keyEntered, with: { [weak self] (key: String, loc: CLLocation) in
                        guard let this = self else { return }
                    
                        if this.queryIsReady {
                            this.loadPost(postKey: key)
                        }
                        else {
                            this.postsLocationChunk[key] = loc
                        }
                    })
                    
                    query.observe(.keyExited, with: { [weak self] (key: String, loc: CLLocation) in
                        guard let this = self else { return }
                        print2("observed post keyExited \(key)")
                        this.removePost(postKey: key)
                    })
                    
                    query.observeReady { [weak self] in
                        guard let this = self else { return }
                    
                        if !this.postsLocationChunk.isEmpty {
                            this.loadPosts(postKeys: Array(this.postsLocationChunk.keys))
                            this.postsLocationChunk.removeAll()
                        }
                    
                        this.queryIsReady = true
                    }
                    
                    this.query = query
                    
                }, onError: { (error: Error) in
                    print2(error)
                }
            )
            .disposed(by: bag)
    }

    private func loadPosts(postKeys: [String]) {
        print2("[PostsDebug] FeedsByDistance[1]: start load \(postKeys.count) posts")
        
        PostDAO.loadPostsByKeys(postKeys: postKeys)
            .flatMap { [weak self] (posts: [String : OrbisPost]) -> Single<Bool> in
                guard let this = self else {
                    return Single.just(false)
                }
                print2("[PostsDebug] FeedsByDistance[1]: loaded \(posts.count) items")
                return this.loadDataObservable(postsLoaded: Array(posts.values))
            }
            .subscribe(
                onSuccess: { [weak self] result in
                    print2("[PostsDebug] FeedsByDistance[2]: loaded \(self?.numberOfItems() ?? -1) items")
                    guard let this = self else { return }
                    if this.postsLocationChunk.isEmpty {
                        this.set(isLoading: false)
                    }
                }, onError: { (error: Error) in
                    print2(error)
                }
            )
            .disposed(by: bag)
    }
    
    func placedOnHome() -> Bool {
        return true
    }

    func radarTab() -> RadarTab? {
        return RadarTab.distanceFeed
    }
    
    override func onFirstChunkLoaded() {
        super.onFirstChunkLoaded()
        observeHomeViewModel(radarTab: radarTab())
    }
}
