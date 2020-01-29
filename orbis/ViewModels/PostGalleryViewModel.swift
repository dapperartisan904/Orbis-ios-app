//
//  PostGalleryViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 30/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class PostGalleryViewModel : OrbisViewModel {
    
    let post: OrbisPost
    let imageIndex: Int?
    let tableOperationSubject = PublishSubject<TableOperation>()
    private var counters = [String : PostCounter]()
    
    init(post: OrbisPost, imageIndex: Int?) {
        self.post = post
        self.imageIndex = imageIndex
        super.init()
        observerCounterChanges()
    }
 
    func indexOf(imageName: String) -> Int? {
        return post.imageUrls?.firstIndex(where: { str in return str.starts(with: imageName) })
    }
    
    func likesCount(index: Int) -> Int {
        let key = post.imageUrls![index].deletingPathExtension
        return counters[key]?.likesCount ?? 0
    }
    
    private func observerCounterChanges() {
        print2("observerCounterChanges [1]")
        
        guard let observables = CountersDAO.observeImagesCounterChanges(post: post) else {
            print2("observerCounterChanges [2]")
            return
        }
    
        observables.forEach { observable in
            observable
                .subscribe(onNext: { [weak self] data in
                    let (imageName, counter) = data
                    
                    guard
                        let this = self,
                        let c = counter,
                        let index = this.indexOf(imageName: imageName)
                    else {
                        return
                    }
                    
                    // TODO KINE: testar se no iPad tb acontece efeitos indesejados nesse update. Talves dê pra atualizar o likesLabel sem chamar o reload([indexPath])
                    
                    this.counters[imageName] = c
                    this.tableOperationSubject.onNext(TableOperation.UpdateOperation(index: index))
                    
                }, onError: { error in
                    print2("observerCounterChanges error")
                    print2(error)
                })
                .disposed(by: bag)
        }
    }
}
