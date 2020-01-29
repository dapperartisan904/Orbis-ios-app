//
//  HiddenPostViewModel.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 12/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class HiddenPostViewModel : OrbisViewModel {
    
    override fileprivate init() {
        super.init()
        observeApplicationFinishLaunching()
        observeLogout()
    }
    
    private static var shared: HiddenPostViewModel = {
        return HiddenPostViewModel()
    }()
    
    static func instance() -> HiddenPostViewModel {
        return HiddenPostViewModel.shared
    }
    
    private var myUser: OrbisUser?
    private var hiddenPosts = [String : HiddenPost]()
    
    let myHiddenPostsLoadedSubject = BehaviorSubject<(String?, Bool)>(value: (nil, true))
    let myHiddenPostChangedSubject = PublishSubject<HiddenPost>()
    private var contentBag = DisposeBag()
    
    private var applicationDidLoad = false
    private var initialLoad = true
    
    private func observeLogout() {
        HelperRepository.instance()
            .logoutObservable
            .subscribe(onNext: { [weak self] _ in
                print2("[HiddenPostsVM] observed logout")
                guard let this = self else { return }
                this.contentBag = DisposeBag()
                this.myUser = nil
                this.hiddenPosts.removeAll()
            })
            .disposed(by: bag)
    }
    
    private func observeApplicationFinishLaunching() {
        HelperRepository.instance().applicationFinishLaunchingSubject
            .subscribe(onNext: { [weak self] finished in
                guard let this = self else { return }
                
                print2("[HiddenPostsVM] FinishLaunching: \(finished) alreadyDidLoad: \(this.applicationDidLoad)")
                
                if finished && !this.applicationDidLoad {
                    this.applicationDidLoad = true
                    this.observeMyUser()
                }
            })
            .disposed(by: bag)
    }
    
    private func observeMyUser() {
        print2("[HiddenPostsVM] observeMyUser")
        
        HelperRepository.instance().myUserSubject
            .subscribe(onNext: { [weak self] user in
                guard let this = self else { return }
                if this.initialLoad || this.myUser?.uid != user?.uid {
                    this.initialLoad = false
                    this.myUser = user
                    this.loadHiddenPosts()
                }
            })
            .disposed(by: bag)
    }
    
    private func loadHiddenPosts() {
        let userId = myUser?.uid
        
        HiddenPostsDAO
            .loadHiddenPosts(userId: userId)
            .subscribe(onSuccess: { [weak self] hiddenPosts in
                guard let this = self else { return }
                print2("[HiddenPostsVM] loadHiddenPosts count: \(hiddenPosts.count)")
                this.hiddenPosts = hiddenPosts
                this.myHiddenPostsLoadedSubject.onNext((userId, true))
                this.observeChildEvents()
            }, onError: { error in
                print2("[HiddenPostsVM] loadHiddenPosts: error")
                print2(error)
            })
            .disposed(by: contentBag)
    }
    
    private func observeChildEvents() {
        guard let userId = myUser?.uid else {
            return
        }
        
        let maxTimestmap = hiddenPosts.max { v1, v2 -> Bool in
            return (v1.value.serverDate?.timeIntervalSince1970 ?? 0) < (v2.value.serverDate?.timeIntervalSince1970 ?? 0)
        }?.value.serverDate?.timeIntervalSince1970 ?? 0
        
        print2("[HiddenPostsVM] maxTimestmap: \(maxTimestmap)")
        
        HiddenPostsDAO.observeHiddenPostsChildEvents(userId: userId, serverTimestamp: Int64(maxTimestmap))
            .subscribe(onNext: { [weak self] hiddenPost in
                guard
                    let this = self,
                    let hiddenPost = hiddenPost
                else {
                    return
                }
        
                print2("[HiddenPostsVM] observedChange postKey: \(hiddenPost.postKey) timestamp: \(hiddenPost.serverDate?.timeIntervalSince1970 ?? 0)")
                this.hiddenPosts[hiddenPost.postKey] = hiddenPost
                this.myHiddenPostChangedSubject.onNext(hiddenPost)
                
            }, onError: { error in
                print2(error)
            })
            .disposed(by: contentBag)
    }
    
    func isHidden(postKey: String) -> Bool {
        return hiddenPosts.has(key: postKey)
    }
    
    func hide(userId: String, postKey: String) {
        HiddenPostsDAO.hidePost(userId: userId, postKey: postKey)
            .subscribe(onSuccess: { _ in }, onError: { error in print2(error) })
            .disposed(by: bag)
    }
}
