//
//  LikesViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 12/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseFirestore

class LikesViewModel : OrbisViewModel {
    
    override fileprivate init() {
        super.init()
        observeApplicationFinishLaunching()
        observeLogout()
    }
    
    private static var shared: LikesViewModel = {
        return LikesViewModel()
    }()

    static func instance() -> LikesViewModel {
        return LikesViewModel.shared
    }
    
    // Workaround used when application is reload due language change
    static func recreate() {
        shared = LikesViewModel()
    }
    
    let myLikesLoadedSubject = BehaviorSubject<(String?, Bool)>(value: (nil, true))
    let myLikeChangedSubject = PublishSubject<(LikeType, LikeInfo)>()
    private var contentBag = DisposeBag()
    
    private var applicationDidLoad = false
    private var initialLoad = true
    
    private(set) var myLikes = [LikeType : [String : LikeInfo]]()
    private var myUser: OrbisUser?

    func isLiking(postKey: String) -> Bool {
        return myLikes[LikeType.post]?[postKey]?.liked ?? false
    }
    
    func isLiking(commentKey: String) -> Bool {
        return myLikes[LikeType.comment]?[commentKey]?.liked ?? false
    }
    
    func isLiking(imageName: String) -> Bool {
        let key = imageName.deletingPathExtension
        return myLikes[LikeType.postImage]?[key]?.liked ?? false
    }
    
    private func observeLogout() {
        HelperRepository.instance()
            .logoutObservable
            .subscribe(onNext: { [weak self] _ in
                print2("[LikesByUser] observed logout")
                guard let this = self else { return }
                this.contentBag = DisposeBag()
                this.myUser = nil
                this.myLikes.removeAll()
            })
            .disposed(by: bag)
    }
    
    private func observeApplicationFinishLaunching() {
        HelperRepository.instance().applicationFinishLaunchingSubject
            .subscribe(onNext: { [weak self] finished in
                guard let this = self else { return }
                
                print2("[LikesByUser] FinishLaunching: \(finished) alreadyDidLoad: \(this.applicationDidLoad)")
                
                if finished && !this.applicationDidLoad {
                    this.applicationDidLoad = true
                    this.observeMyUser()
                }
            })
            .disposed(by: bag)
    }
    
    private func observeMyUser() {
        print2("[LikesByUser] observeMyUser")
        
        HelperRepository.instance().myUserSubject
            .subscribe(onNext: { [weak self] user in
                guard let this = self else { return }
                if this.initialLoad || this.myUser?.uid != user?.uid {
                    this.initialLoad = false
                    this.myUser = user
                    this.loadLikes()
                }
            })
            .disposed(by: bag)
    }
    
    private func loadLikes() {
        print2("[LikesByUser] loadLikes \(String(describing: myUser?.username))")
        
        guard let user = myUser else {
            myLikesLoadedSubject.onNext((nil, true))
            return
        }
        
        LikeDAO.loadUserLikes(userId: user.uid)
            .subscribe(onSuccess: { [weak self] myLikes in
                print2("[LikesByUser] observed \(myLikes.count) likes")
                guard let this = self else { return }
                this.myLikes = myLikes
                this.myLikesLoadedSubject.onNext((user.uid, true))
                this.observeMyUserLikeChanges()
            })
            .disposed(by: contentBag)
    }
    
    private func observeMyUserLikeChanges() {
        let userId = UserDefaultsRepository.instance().getMyUser()?.uid
        var serverTimestamp: Int64 = 0

        if !myLikes.isEmpty {
            let array = myLikes
                .flatMap { $0.value }
                .compactMap { $0.value }
            
            let value = array.max(by: { p0, p1 in
                let d0 = p0.serverDate
                let d1 = p1.serverDate
                
                if d0 == nil {
                    return false
                }
                
                if d1 == nil {
                    return true
                }
                
                return d0!.compare(d1!).rawValue == -1

            })?.serverDate?.timeIntervalSince1970
            
            serverTimestamp = Int64(value ?? 0)
        }
        
        guard let observables = LikeDAO.observeLikeChanges(userId: userId, serverTimestamp: serverTimestamp) else {
            return
        }
        
        observables.forEach { observable in
            observable
                .subscribe(onNext: { [weak self] result in
                    let likeType = result.0
                    
                    guard
                        let likeInfo = result.1,
                        let this = self,
                        likeInfo.notEqual(other: this.myLikes[likeType]?[likeInfo.mainKey])
                    else {
                        return
                    }

                    if !this.myLikes.has(key: likeType) {
                        this.myLikes[likeType] = [String : LikeInfo]()
                    }
                    
                    this.myLikes[likeType]![likeInfo.mainKey] = likeInfo
                    this.myLikeChangedSubject.onNext((likeType, likeInfo))
                }, onError: { error in
                    print2(error)
                })
                .disposed(by: contentBag)
        }
    }
    
    func toggleLike(likeType: LikeType, mainKey: String, postKey: String, receiverId: String?, superKey: String? = nil) {
        guard let userId = UserDefaultsRepository.instance().getMyUser()?.uid else {
            return
        }

        let finalKey = likeType == .postImage ? mainKey.deletingPathExtension : mainKey
        let liked = !(myLikes[likeType]?[finalKey]?.liked ?? false)
        
        LikeDAO.saveMyLike(userId: userId, likeType: likeType, mainKey: finalKey, value: liked, receiverId: receiverId, postKey: postKey)
            .flatMap { _ in
                return CountersDAO.updateLikesCount(likeType: likeType, mainKey: finalKey, increment: liked ? 1 : -1, superKey: superKey)
            }
            .subscribe(onSuccess: { _ in
                
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }
    
}
