//
//  MyFeedViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 15/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class MyFeedViewModel : BasePostsViewModel, PostsViewModelContract {

    private var myUser: OrbisUser?
    private var postsOfCurrentChunk: [OrbisPost]?
    private let rolesViewModel = RolesViewModel.instance()
    private var contentBag = DisposeBag()
    
    // TODO KINE: see Android -> posts with notifications first
    override func sortFunction(p0: OrbisPost, p1: OrbisPost) -> Bool {
        return super.sortFunction(p0: p0, p1: p1)
    }
    
    override func clearData() {
        super.clearData()
        contentBag = DisposeBag()
        myUser = nil
        postsOfCurrentChunk = nil
    }
    
    override func onLogout() {
        print2("[MyFeed] onLogout")
        super.onLogout()
        clearData()
        set(isLoading: false)
        tableOperationSubject.onNext(TableOperation.ReloadOperation())
    }

    override func adMobsEnabled() -> Bool {
        return HelperRepository.instance().admin.adMobEnabled
    }
    
    func onViewControllerReady() {
        observeMyUser()
    }
    
    private func observeMyUser() {
        HelperRepository.instance().myUserSubject
            .subscribe(onNext: { [weak self] user in
                guard
                    let user = user,
                    let this = self,
                    user.uid != this.myUser?.uid
                else {
                    return
                }
            
                print2("[MyFeed] observed user \(String(describing: user.username))")
                this.myUser = user
                this.loadNextChunk()
            })
            .disposed(by: bag)
    }
    
    /*
        Note that currently all data is loaded in one chunk
        One possible approach would be load posts of last [1..N] days, on next page (N+1..N*2], ...
     */
    func loadNextChunk() {
        set(isLoading: true)
        postsOfCurrentChunk = nil
        resetFirstChunk()
        
        print2("[MyFeed] step0 posts count at start: \(numberOfItems())")
        
        LikesViewModel.instance().myLikesLoadedSubject
            .filter { tuple in
                let (userId, loaded) = tuple
                let udrUserId = UserDefaultsRepository.instance().getMyUser()?.uid
                let sameUser = userId == udrUserId
                print2("[MyFeed] step1 sameUser: \(sameUser) loaded: \(loaded) userIds: \(userId ?? "null") \(udrUserId ?? "null")")
                return sameUser && loaded
            }
            .flatMap { [weak self] (tuple : (String?, Bool)) -> Observable<(String?, Bool)> in
                print2("[MyFeed] step2 myLikesLoaded: \(tuple.1)")
                guard let this = self else {
                    return Observable.never()
                }
                return this.rolesViewModel.rolesByGroupLoadedSubject
            }
            .filter { tuple in
                let (userId, loaded) = tuple
                let user = UserDefaultsRepository.instance().getMyUser()
                print2("[MyFeed] step3.5 rolesByGroupLoaded: \(loaded) userId: \(userId ?? "") \(user?.uid ?? "")")
                return userId == user?.uid && loaded
            }
            .flatMap { [weak self] (tuple : (String?, Bool)) -> Observable<(String?, Bool)> in
                print2("[MyFeed] step4 myRolesLoaded: \(tuple.1)")
                guard let this = self else {
                    return Observable.never()
                }
                return this.rolesViewModel.rolesByPlaceLoadedSubject
            }
            .filter { tuple in
                let (userId, loaded) = tuple
                print2("[MyFeed] step3.4 rolesByPlaceLoaded: \(loaded)")
                return userId == UserDefaultsRepository.instance().getMyUser()?.uid && loaded
            }
            .flatMap { _ in
                return HiddenPostViewModel.instance().myHiddenPostsLoadedSubject
            }
            .filter { tuple in
                let (userId, loaded) = tuple
                let user = UserDefaultsRepository.instance().getMyUser()
                print2("[MyFeed] step3.6 myHiddenPostsLoaded: \(loaded) userId: \(userId ?? "") \(user?.uid ?? "")")
                return userId == user?.uid && loaded
            }
            .flatMap { _ in
                return BannedUsersViewModel.instance().myBannedUsersLoadedSubject
            }
            .filter { tuple in
                let (userId, loaded) = tuple
                let user = UserDefaultsRepository.instance().getMyUser()
                print2("[MyFeed] step3.7 myHiddenPostsLoaded: \(loaded) userId: \(userId ?? "") \(user?.uid ?? "")")
                return userId == user?.uid && loaded
            }
            .flatMap { [weak self] (tuple : (String?, Bool)) -> Single<[OrbisPost]> in
                print2("[MyFeed] step5")
                
                guard let this = self else {
                    return Single.never()
                }

                // TODO KINE: sponsored posts not implemented
                
                let groups = this.rolesViewModel.groupsBeingFollowed()
                print2("[MyFeed] groupsBeingFollowed: \(groups)")
                return PostDAO.loadPostsByGroups(groupKeys: groups)
            }
            .subscribe(onNext: { [weak self] (postsByGroup : [OrbisPost]) in
                print2("[MyFeed] step6")
                
                guard let this = self else {
                    return
                }
                
                print2("[MyFeed] loaded \(postsByGroup.count) posts on second step")

                this.postsOfCurrentChunk = postsByGroup
                this.loadNextChunkSecondStep()
                
                }, onError: { error in
                    print2("[MyFeed] loadNextChunk error")
                    print2(error)
                }
            )
            .disposed(by: contentBag)
    }
    
    /*
        This separation in two steps is a workaround because
        some observable was being triggered twice
     */
    private func loadNextChunkSecondStep() {
        let places = rolesViewModel.placesBeingFollowed()
        print2("[MyFeed] placesBeingFollowed: \(places)")
        
        PostDAO.loadPostsByPlaces(placeKeys: places)
            .flatMap { [weak self] (postsByPlaces: [OrbisPost]) -> Single<Bool> in
                print2("[MyFeed] step7")
                guard let this = self else {
                    return Single.never()
                }
                
                print2("[MyFeed] loaded \(postsByPlaces.count) posts on second step")
                
                if this.postsOfCurrentChunk == nil {
                    this.postsOfCurrentChunk = [OrbisPost]()
                }
                
                this.postsOfCurrentChunk!.append(contentsOf: postsByPlaces)
                
                let posts = this.postsOfCurrentChunk!
                    .filter { post in self?.postShouldBeDisplayed(post: post) ?? false }
                
                return this.loadDataObservable(postsLoaded: posts)
            }
            .subscribe(
                onSuccess: { finished in
                    print2("[MyFeed] step8")
                }, onError: { error in
                    print2("[MyFeed] loadNextChunk error")
                    print2(error)
                })
            .disposed(by: contentBag)
    }
    
    override func postShouldBeDisplayed(post: OrbisPost) -> Bool {
        if !super.postShouldBeDisplayed(post: post) {
            return false
        }
        
        guard
            let type = post.typeEnum(),
            let coordinates = post.coordinates
        else {
            return false
        }
        
        if !type.isLimitedByDistance() {
            return true
        }
        
        guard let myLocation = HelperRepository.instance().getLocation() else {
            return true
        }
        
        return myLocation.distanceInMeters(toOther: coordinates) < myFeedsDistanceInMeters
    }
    
    override func onFirstChunkLoaded() {
        super.onFirstChunkLoaded()
        observeRoleChanges()
        set(isLoading: false)
    }
    
    private func observeRoleChanges() {
        rolesViewModel.roleByGroupChangedSubject
            .subscribe(onNext: { [weak self] groupKey in
                guard let this = self else { return }
                let status = this.rolesViewModel.followStatus(groupKey: groupKey)
                if status == RoleStatus.active {
                    this.onStartFollowGroup(groupKey: groupKey)
                }
                else if status == RoleStatus.inactive {
                    this.removePosts(groupKey: groupKey)
                }
            })
            .disposed(by: contentBag)
    
        rolesViewModel.roleByPlaceChangedSubject
            .subscribe(onNext: { [weak self] placeKey in
                guard let this = self else { return }
                let status = this.rolesViewModel.followStatus(placeKey: placeKey)
                if status == RoleStatus.active {
                    this.onStartFollowPlace(placeKey: placeKey)
                }
                else if status == RoleStatus.inactive {
                    this.removePosts(placeKey: placeKey)
                }
            })
            .disposed(by: contentBag)
    }
    
    private func onStartFollowGroup(groupKey: String) {
        print2("[MyFeed] onStartFollowGroup begin")
        
        PostDAO.loadPostsByGroup(groupKey: groupKey)
            .flatMap { [weak self] (postsOfGroup: [OrbisPost]) -> Single<Bool> in
                guard let this = self else {
                    return Single.never()
                }
                
                return this.loadDataObservable(postsLoaded: postsOfGroup
                    .filter { post in self?.postShouldBeDisplayed(post: post) ?? false }
                )
            }
            .subscribe(onSuccess: { loaded in
               print2("[MyFeed] onStartFollowGroup finished")
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }

    private func onStartFollowPlace(placeKey: String) {
        print2("[MyFeed] onStartFollowPlace finished")
        
        PostDAO.loadPostsByPlace(placeKey: placeKey)
            .flatMap { [weak self] (postsOfPlace: [OrbisPost]) -> Single<Bool> in
                guard let this = self else {
                    return Single.never()
                }
                
                return this.loadDataObservable(postsLoaded: postsOfPlace
                    .filter { post in self?.postShouldBeDisplayed(post: post) ?? false }
                )
            }
            .subscribe(onSuccess: { loaded in
                print2("[MyFeed] onStartFollowPlace finished")
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }
    
    func placedOnHome() -> Bool {
        return true
    }
    
    func radarTab() -> RadarTab? {
        return RadarTab.myFeed
    }
}
