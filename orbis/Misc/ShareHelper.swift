//
//  ShareHelper.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 15/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import MKProgress
import Kingfisher

class ShareHelper {
    
    let sharedItemsSubject = PublishSubject<[Any]>()
    let defaultSubject = PublishSubject<Any>()
    
    private var sharing = false
    private var imagesCounter = AtomicInteger<Int>(0)
    
    public func share(post: OrbisPost) {
        guard let type = post.typeEnum() else { return }
        
        if sharing {
            defaultSubject.onNext(Words.waitPreviousOperation)
            return
        }
        
        sharing = true
        
        var items = [Any]()
        
        switch type {
        case PostType.text:
            items.append(post.details!)
            sharedItemsSubject.onNext(items)
            sharing = false
            
        case PostType.images:
            guard let urls = post.imageUrls else {
                sharing = false
                return
            }
            
            MKProgress.show(true)
            imagesCounter = 0
            
            for i in 0...urls.count-1 {
                let url = urls[i]
                
                guard
                    let downloadUrl = S3Folder.posts.downloadURL(cloudKey: url)
                else {
                    return
                }
                
                print2("ShareHelper: donwload image begin \(downloadUrl)")
                
                imagesCounter += 1
                
                delay(ms: 1000 * (i + 1), block: {
                    _ = KingfisherManager.shared.retrieveImage(with: downloadUrl, options: nil) { [weak self] result in
                        guard let this = self else {
                            return
                        }
                        
                        if let image = result.value?.image {
                            print2("ShareHelper: donwload image finished \(downloadUrl)")
                            items.append(image)
                        }
                        
                        this.imagesCounter -= 1
                        
                        if this.imagesCounter == 0 {
                            print2("ShareHelper: finished to load images itemsCount: \(items.count)")
                            this.sharing = false
                            MKProgress.hide(true)
                            
                            if !items.isEmpty {
                                this.sharedItemsSubject.onNext(items)
                            }
                        }
                    }
                })
            }
            
        case PostType.video:
            guard
                let cloudKey = post.imageUrls?.first,
                let downloadURL = S3Folder.posts.downloadURL(cloudKey: cloudKey)
            else {
                sharing = false
                return
            }
            
            print2("Share video \(downloadURL.absoluteString)")
            items.append(downloadURL)
            sharedItemsSubject.onNext(items)
            sharing = false
            

        default:
            // TODO KINE: share post other cases notImplemented
            defaultSubject.onNext(Words.notImplemented)
            sharing = false
        }
    }
    
}
