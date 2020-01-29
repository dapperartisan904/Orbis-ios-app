//
//  OrbisImages.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 19/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import Photos
import Kingfisher
import RxSwift

class RoundedImageView : UIImageView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
        layer.cornerRadius = frame.width/2.0
    }
    
}

class VideoImageView : UIImageView {
    
    var prevUrl: URL?
        
    func createThumbnailOfVideoIfNeeded(url: URL, cloudKey: String, maxSize: CGSize, indicatorView: UIActivityIndicatorView? = nil) {
        print2("VideoImageView: createThumbnailOfVideoIfNeeded cloudKey: \(cloudKey) url: \(url)")
        
        if url.absoluteString == prevUrl?.absoluteString {
            print2("VideoImageView: same url")
            return
        }
        
        prevUrl = url
        
        let cache = ImageCache.default
        if cache.isCached(forKey: url.absoluteString) {
            print2("VideoImageView: isCached")
            kf.setImage(with: url)
            indicatorView?.stopAnimating()
            return
        }
        
        print2("VideoImageView: must generate thumbnail \(url)")
        
        image = nil
        indicatorView?.isHidden = false
        indicatorView?.startAnimating()
        createThumbnailOfVideo(url: url, cloudKey: cloudKey, maxSize: maxSize, useCache: true, indicatorView: indicatorView)
    }
    
    private func createThumbnailOfVideo(url: URL, cloudKey: String, maxSize: CGSize, useCache: Bool, indicatorView: UIActivityIndicatorView?) {
        if useCache {
            guard let phAssetId = UserDefaultsRepository.instance().getPHAssetId(postImageId: cloudKey) else {
                print2("VideoImageView: createThumbnailOfVideo fromCache early return [1] cloudKey: \(cloudKey)")
                createThumbnailOfVideo(url: url, cloudKey: cloudKey, maxSize: maxSize, useCache: false, indicatorView: indicatorView)
                return
            }
            
            let options = PHFetchOptions()
            options.fetchLimit = 1
            options.includeAllBurstAssets = false
            
            let result = PHAsset.fetchAssets(withLocalIdentifiers: [phAssetId], options: options)
            guard let asset = result.firstObject else {
                print2("VideoImageView: createThumbnailOfVideo fromCache early return [2]")
                createThumbnailOfVideo(url: url, cloudKey: cloudKey, maxSize: maxSize, useCache: false, indicatorView: indicatorView)
                return
            }
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: nil, resultHandler: { [weak self] (avAsset: AVAsset?, avAudioMix: AVAudioMix?, dict: [AnyHashable : Any]?) in
                guard let this = self else {
                    print2("VideoImageView: createThumbnailOfVideo fromCache early return [3]")
                    return
                }
                
                guard let avAsset = avAsset else {
                    print2("VideoImageView: createThumbnailOfVideo fromCache early return [4]")
                    this.createThumbnailOfVideo(url: url, cloudKey: cloudKey, maxSize: maxSize, useCache: false, indicatorView: indicatorView)
                    return
                }
                
                print2("VideoImageView: createThumbnailOfVideo fromCache proceed")
                this.createThumbnail(url: url, asset: avAsset, maxSize: maxSize, indicatorView: indicatorView)
            })
        }
        else {
            let asset = AVAsset(url: url)
            createThumbnail(url: url, asset: asset, maxSize: maxSize, indicatorView: indicatorView)
        }
    }
    
    private func createThumbnail(url: URL, asset: AVAsset, maxSize: CGSize, indicatorView: UIActivityIndicatorView?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
            let cache = ImageCache.default
            let assetImgGenerate = AVAssetImageGenerator(asset: asset)
            assetImgGenerate.appliesPreferredTrackTransform = true
            assetImgGenerate.maximumSize = maxSize
            
            do {
                let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                let thumbnail = UIImage(cgImage: img)
                cache.store(thumbnail, forKey: url.absoluteString)
                
                print2("VideoImageView generate thumbnail success")
                
                DispatchQueue.main.async {
                    if url.absoluteString == self?.prevUrl?.absoluteString {
                        indicatorView?.stopAnimating()
                        self?.image = thumbnail
                    }
                }
                
            } catch {
                print2("VideoImageView generate thumbnail: error \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    if url.absoluteString == self?.prevUrl?.absoluteString {
                        indicatorView?.stopAnimating()
                        self?.image = nil
                    }
                }
            }
        }
    }
}

class RatioImageView : UIImageView {
    
    var prevUrl: URL?
    var task: DownloadTask?
    
    func loadRespectingRatio(url: URL, ratioConstraint: NSLayoutConstraint, completion: @escaping (NSLayoutConstraint) -> Void) {
        
        if url.absoluteString == prevUrl?.absoluteString {
            print2("RatioImageView: same url")
            return
        }
        
        prevUrl = url
        task?.cancel()
        
        task = KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
            guard
                let this = self,
                let image = result.value?.image,
                url.absoluteString == this.prevUrl?.absoluteString
            else {
                return
            }
            
            let ratio = image.size.height.float / image.size.width.float
            print2("RatioImageView size: \(image.size) Ratio: \(ratio)")

            let newConstraint = ratioConstraint.setMultiplier(multiplier: ratio.cgFloat)
            this.image = image
        
            completion(newConstraint)
            //this.layoutIfNeeded()
        }
        
    }
    
}

class CacheImageView : UIImageView {
    
    var currentUrl: String?
    var imageRequestID: PHImageRequestID?
    
    private var loadImageDelayedDisposable: Disposable?
    
    deinit {
        loadImageDelayedDisposable?.dispose()
    }
    
    private func reloadPostImageDelayed(url: String, useCache: Bool) {
        if url != currentUrl {
            return
        }
    
        loadImageDelayedDisposable?.dispose()
        kf.indicator?.startAnimatingView()
        
        loadImageDelayedDisposable = Single.just(1)
            .delaySubscription(RxTimeInterval.seconds(3), scheduler: MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] _ in
                self?.loadPostImage(url: url, useCache: useCache)
            }, onError: { error in
                print2(error)
            })
    }
    
    private func reloadChatImageDelayed(msg: ChatMessage) {
        if currentUrl == nil || currentUrl != msg.imageUrls?.first {
            return
        }
        
        loadImageDelayedDisposable?.dispose()
        kf.indicator?.startAnimatingView()
        
        loadImageDelayedDisposable = Single.just(1)
            .delaySubscription(RxTimeInterval.seconds(3), scheduler: MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] _ in
                    guard let this = self else { return }
                    if this.currentUrl == nil || this.currentUrl != msg.imageUrls?.first {
                        return
                    }
                    this.loadImage(msg: msg)
                }, onError: { error in
                    print2(error)
                }
            )
    }
    
    func loadPostImage(url: String, useCache: Bool = false) {
        if !useCache {
            currentUrl = url

            let downloadUrl = S3Folder.posts.downloadURL(cloudKey: url)
            print2("loadPostImage downloadUrl: \(String(describing: downloadUrl))")
            
            kf.setImage(
                with: downloadUrl,
                options: [.transition(.fade(0.2))],
                progressBlock: nil) { [weak self] result in
                    switch result {
                    case .failure(let error):
                        if error.isInvalidResponseStatusCode {
                            self?.reloadPostImageDelayed(url: url, useCache: useCache)
                        }
                    
                    case .success:
                       self?.kf.indicator?.stopAnimatingView()
                    }
                }

            return
        }
        
        if let id = imageRequestID {
            if url == currentUrl {
                return
            }
            else {
                PHImageManager.default().cancelImageRequest(id)
            }
        }
        
        currentUrl = url
        image = nil
        kf.indicator?.startAnimatingView()
        
        guard let phAssetId = UserDefaultsRepository.instance().getPHAssetId(postImageId: url) else {
            print2("loadPostImage from asset failed [1]")
            loadPostImage(url: url, useCache: false)
            return
        }
        
        let options = PHFetchOptions()
        options.fetchLimit = 1
        options.includeAllBurstAssets = false
        
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [phAssetId], options: options)
            guard let asset = result.firstObject else {
                print2("loadPostImage from asset failed [2]")
                loadPostImage(url: url, useCache: false)
            return
        }

        /*
        if asset.sourceType == .typeCloudShared {
            print2("loadPostImage from asset aborted because it's on cloud. Will donwlond with kf")
            loadPostImage(url: url, useCache: false)
            return
        }
        */
        
        imageRequestID = PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
            contentMode: .aspectFit,
            options: orbisDefaultImageRequestOptions()) { [weak self] image, _ in
                guard let this = self else { return }
                
                if this.currentUrl != url {
                    return
                }
                
                if let i = image {
                    print2("loadPostImage from asset success")
                    this.image = i
                    this.kf.indicator?.stopAnimatingView()
                }
                else {
                    print2("loadPostImage from asset failed [3]")
                    this.loadPostImage(url: url, useCache: false)
                }
            }
    }
    
    func loadImage(msg: ChatMessage) {
        guard
            let str = msg.imageUrls?.first,
            let url = S3Folder.chats.downloadURL(cloudKey: str)
        else {
            print2("CacheImageView: load chat image early return")
            image = nil
            return
        }
        
        currentUrl = str
        
        kf.setImage(
            with: url,
            options: [.processor(DownsamplingImageProcessor(size: CGSize(width: 100, height: 178)))],
            progressBlock: nil) { [weak self] result in
                switch result {
                case .failure(let error):
                    if error.isInvalidResponseStatusCode {
                        self?.reloadChatImageDelayed(msg: msg)
                    }
                default:
                    break
                }
        }
    }
    
}
