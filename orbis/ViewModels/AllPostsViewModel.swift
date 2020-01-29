//
//  AllPostsViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 07/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class AllPostsViewModel : BasePostsViewModel, PostsViewModelContract {
    
    func onViewControllerReady() {
        loadNextChunk()
    }
    
    func loadNextChunk() {
        PostDAO
            .loadAllPosts()
            .flatMap { [weak self] posts -> Single<Bool> in
                //posts.forEach { post in print2("PostType: \(post.type ?? "nil") \(post.typeEnum()?.rawValue ?? "nil")")}
                
                return self?.loadDataObservable(postsLoaded: posts) ?? Single.just(true)
                
                /*
                let posts2 = posts.filter {
                    [PostType.checkIn, PostType.event, PostType.wonPlace, PostType.conqueredPlace, PostType.lostPlace].contains($0.typeEnum())
                }
                print2("[PostsDebug] All posts loaded [1]. Count: \(posts.count) - \(posts2.count)")
                return self?.loadDataObservable(postsLoaded: posts2) ?? Observable.just(true)
                */
            }
            .subscribe(onSuccess: { [weak self] result in
                print2("[PostsDebug] All posts loaded [2]. Count: \(self?.numberOfItems() ?? 0)")
            }, onError: { error in
                print2("[PostsDebug] All posts error \(error)")
            })
            .disposed(by: bag)
    }
    
    func placedOnHome() -> Bool {
        return false
    }

    func radarTab() -> RadarTab? {
        return nil
    }
}
