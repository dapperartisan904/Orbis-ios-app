//
//  CreatePostViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 23/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import Photos

class CreatePostViewModel : OrbisViewModel {
    
    var postType: PostType!
    var allowMultipleSelection: Bool!
    var hasCameraItem: Bool!
    var hasAssets: Bool!
    var group: Group!
    var place: Place?
    var origin: ViewControllerInfo!
    
    let defaultSubject = PublishSubject<Any>()
    private(set) var selectedAssets = [String : PHAsset]()
    
    // Required for subclassing
    override init() {
        super.init()
    }
    
    init(postType: PostType, group: Group, place: Place?, origin: ViewControllerInfo) {
        self.postType = postType
        self.group = group
        self.place = place
        self.origin = origin
        self.allowMultipleSelection = postType == .images
        self.hasCameraItem = postType == .images
        self.hasAssets = postType == .images || postType == .video
    }

    func select(asset: PHAsset) {
        if isSelected(asset: asset) {
            deselect(asset: asset)
        }
        else {
            if !allowMultipleSelection {
                selectedAssets.removeAll()
            }
            
            //print2("Asset mediaSubtypes: \(asset.mediaSubtypes)")
            selectedAssets[asset.localIdentifier] = asset
        }
    }
    
    func deselect(asset: PHAsset) {
        deselect(assetId: asset.localIdentifier)
    }
    
    func deselect(assetId: String) {
        selectedAssets.removeValue(forKey: assetId)
    }
    
    func isSelected(asset: PHAsset) -> Bool {
        return selectedAssets.has(key: asset.localIdentifier)
    }
    
    func assets() -> [PHAsset] {
        return Array(selectedAssets.values)
    }
    
    func asset(at index: Int) -> PHAsset? {
        return assets()[index]
    }
    
    func numberOfAssets() -> Int {
        return selectedAssets.count
    }
    
    func stepTwo() {
        if selectedAssets.isEmpty {
            defaultSubject.onNext(Words.errorSelectOneImageOrVideo)
            return
        }
        
        defaultSubject.onNext(Navigation.createPostStepTwo(viewModel: self))
    }
    
    func savePost(text: String?) {
        if hasAssets && selectedAssets.isEmpty {
            defaultSubject.onNext(Words.errorSelectOneImageOrVideo)
            return
        }
        
        if postType == .text && (text?.count ?? 0) < 3 {
            defaultSubject.onNext(Words.textCannotBeEmpty)
            return
        }

        guard
            let user = UserDefaultsRepository.instance().getMyUser(),
            let location = HelperRepository.instance().getLocation(),
            let key = PostDAO.newKey(),
            let postType = postType
        else {
            defaultSubject.onNext(Words.errorGeneric)
            return
        }
        
        defaultSubject.onNext(OrbisAction.taskStarted)
        
        let udr = UserDefaultsRepository.instance()
        let title = postType == .text ? nil : text
        let details = postType == .text ? text : nil
        
        let post = OrbisPost(
            coordinates: location,
            geohash: location.toCLLocationCoordinate2D().geohash(),
            imageUrls: nil,
            postKey: key,
            timestamp: nil,
            serverTimestamp: Int64(Date().timeIntervalSince1970),
            serverTimestamp2: nil,
            dateTimestamp: nil,
            timeTimestamp: nil,
            sponsored: false,
            title: title,
            details: details,
            type: postType.rawValue,
            placeKey: place?.key,
            userKey: user.uid,
            winnerGroupKey: group.key,
            loserGroupKey: nil,
            link: nil)
        
        switch postType {
        case .text:
            savePostOnDatabase(post: post)
            
        case .images:
            let assets = Array(selectedAssets.values)
            let fileExtension = "jpeg"
            
            let randoms = assets.map { _ in
                UUID().uuidString
            }
            
            let cloudKeys = randoms.map { random in
                return S3Folder.posts.uploadKey(cloudKey: random, localFileType: fileExtension)
            }
            
            let assetUrls = randoms.map {
                random in "\(random).\(fileExtension)"
            }
            for i in 0...assetUrls.endIndex-1 {
                udr.setPHAssetId(postImageId: assetUrls[i], phAssetId: assets[i].localIdentifier)
            }
            
            S3Repository.instance().upload(imageAssets: assets, keys: cloudKeys)
            post.imageUrls = assetUrls
            savePostOnDatabase(post: post)
            
        case .video:
            let asset = selectedAssets.first!.value
            let randomKey = String.random(ofLength: 8)
            
            udr.setPHAssetId(postImageId: randomKey, phAssetId: asset.localIdentifier)
            
            S3Repository.instance().upload(
                videoAsset: asset,
                key: randomKey,
                fileExtensionBlock: { [weak self] fileExtension in
                    guard let this = self else { return }
                    
                    guard let fileExtension = fileExtension else {
                        this.defaultSubject.onNext(Words.errorGeneric)
                        return
                    }
                    
                    post.imageUrls = [randomKey + "." + fileExtension]
                    this.savePostOnDatabase(post: post)
                },
                errorBlock: { [weak self] error in
                    self?.defaultSubject.onNext((OrbisAction.taskFailed, error))
                }
            )
         
        default:
            break
        }
    }
    
    private func savePostOnDatabase(post: OrbisPost) {
        PostDAO.save(post: post, group: group, place: place)
            .subscribe(onSuccess: { [weak self] _ in
                guard let this = self else { return }
                let navigation: Any

                switch this.origin {
                case ViewControllerInfo.group:
                    navigation = PopToViewController(type: GroupViewController.self)

                case ViewControllerInfo.place:
                    navigation = PopToViewController(type: PlaceViewController.self)
                    
                default:
                    navigation = Navigation.home()
                }
                
                this.defaultSubject.onNext((OrbisAction.taskFinished, navigation))

                }, onError: { [weak self] error in
                    self?.defaultSubject.onNext(ActionAndError(OrbisAction.taskFailed, Words.errorGeneric))
                    print2("save post error \(error)")
            })
            .disposed(by: bag)
    }
}
