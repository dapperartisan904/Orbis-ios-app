//
//  CreatePostViewControllerStepOne.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 22/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import Photos
import PhotosUI

/*
    Based on https://developer.apple.com/library/archive/samplecode/UsingPhotosFramework/Listings/Shared_AssetGridViewController_swift.html
    Warning: before mkae any changes, consider that this view controller is subclassed
 */
class CreatePostStepOneViewController : OrbisViewController {
    
    @IBOutlet weak var toolbar: TitleToolbar!
    @IBOutlet weak var header: CreatePostHeader!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: BottomButton!
    
    private var fetchResult: PHFetchResult<PHAsset>!
    private var assetCollection: PHAssetCollection!
    private let imageManager = PHCachingImageManager()
    
    private var previousPreheatRect = CGRect.zero
    private var thumbnailSize: CGSize!
    private var initialized = false
    private var photoTaked = false
    
    var viewModel: CreatePostViewModel!
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.delegate = self
        paintBackground(group: viewModel.group)

        if let postType = viewModel.postType {
            toolbar.label.text = postType.createPostTitle()?.localized
            bottomButton.setTitleUppercased(postType.selectButtonTitle()?.localized, for: .normal)
            header.fill(group: viewModel.group, place: viewModel.place)
        }

        bottomButton.rx.tap
            .bind { [weak self] in
                self?.viewModel.stepTwo()
            }
            .disposed(by: bag)
        
        observeDefaultSubject(subject: viewModel.defaultSubject, onlyIfVisible: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale = UIScreen.main.scale
        let cellSize = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()

        if initialized {
            collectionView.reloadData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !initialized {
            initialized = true
            initialize()
        }
    }
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
    
    private func initialize() {
        print2("CreatePostStepOneViewController initialize allowsMultipleSelection: \(String(describing: viewModel.allowMultipleSelection))")
        
        DispatchQueue.main.async {
            let space: CGFloat = 20
            let cvSize = self.collectionView.frame.size
            let itemWidth = (cvSize.width - (space * 2)) / 3.0
            let itemSize = CGSize(width: itemWidth, height: itemWidth)
            let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            layout.itemSize = itemSize
            layout.minimumLineSpacing = space
            layout.minimumInteritemSpacing = space
            layout.footerReferenceSize = CGSize.zero
            layout.headerReferenceSize = CGSize.zero
            layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
            
            self.collectionView.register(cell: Cells.thumbnailCell)
            self.collectionView.delegate = self
            self.collectionView.dataSource = self
            self.collectionView.allowsSelection = true
            self.collectionView.allowsMultipleSelection = self.viewModel.allowMultipleSelection
            
            self.resetCachedAssets()
            PHPhotoLibrary.shared().register(self)
            
            let mediaType = self.viewModel.postType == .video ? PHAssetMediaType.video : PHAssetMediaType.image
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            self.fetchResult = PHAsset.fetchAssets(with: mediaType, options: options)
        }
    }
    
    private func isCameraItem(indexPath: IndexPath) -> Bool {
        return viewModel.hasCameraItem && indexPath.item == 0
    }
    
    private func assetIndex(indexPath: IndexPath) -> Int {
        return viewModel.hasCameraItem ? indexPath.item - 1 : indexPath.item
    }
    
    private func collectionIndex(assetIndex: Int) -> Int {
        return viewModel.hasCameraItem ? assetIndex + 1 : assetIndex
    }
    
    private func openCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    fileprivate func resetCachedAssets() {
        if !initialized { return }
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    fileprivate func updateCachedAssets() {
        if !initialized { return }
        
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        
        var addedIndexPaths = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
        
        var removedIndexPaths = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
        
        addedIndexPaths.removeFirst { isCameraItem(indexPath: $0) }
        removedIndexPaths.removeFirst { isCameraItem(indexPath: $0) }
        
        //addedIndexPaths.forEach { indexPath in print2("[PH] updateCachedAssets added \(indexPath.item) ") }
        //removedIndexPaths.forEach { indexPath in print2("[PH] updateCachedAssets removed \(indexPath.item) ") }
        
        let addedAssets = addedIndexPaths.map { indexPath in fetchResult.object(at: assetIndex(indexPath: indexPath)) }
        let removedAssets = removedIndexPaths.map { indexPath in fetchResult.object(at: assetIndex(indexPath: indexPath)) }

        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
}

extension CreatePostStepOneViewController : PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if !initialized { return }
        
        guard let changes = changeInstance.changeDetails(for: fetchResult)
            else { return }
        
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Hang on to the new fetch result.
            fetchResult = changes.fetchResultAfterChanges
            if changes.hasIncrementalChanges {
                // If we have incremental diffs, animate them in the collection view.
                guard let collectionView = self.collectionView else { fatalError() }
                collectionView.performBatchUpdates({
                    // For indexes to make sense, updates must be in this order:
                    // delete, insert, reload, move
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: self.collectionIndex(assetIndex: $0), section: 0) }))
                        //removed.forEach { index in print2("[PH] photoLibraryDidChange removed \(index)") }
                    }
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: self.collectionIndex(assetIndex: $0), section: 0) }))
                        //inserted.forEach { index in print2("[PH] photoLibraryDidChange inserted \(index)") }
                    }
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: self.collectionIndex(assetIndex: $0), section: 0) }))
                        //changed.forEach { index in print2("[PH] photoLibraryDidChange changed \(index)") }
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
            } else {
                // Reload the collection view if incremental diffs are not available.
                collectionView!.reloadData()
            }
            resetCachedAssets()
        }
    }
}

extension CreatePostStepOneViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.hasCameraItem ? fetchResult.count + 1 : fetchResult.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withCellType: Cells.thumbnailCell, for: indexPath) as! ThumbnailCell
        cell.removeView.isHidden = true

        if isCameraItem(indexPath: indexPath) {
            cell.thumbnailView.isHidden = true
            cell.checkView.isHidden = true
            cell.cameraView.isHidden = false
            cell.cameraView.image = cell.cameraView.image?
                .withRenderingMode(.alwaysTemplate)
        }
        else {
            let asset = fetchResult.object(at: assetIndex(indexPath: indexPath))
            cell.representedAssetIdentifier = asset.localIdentifier
            cell.checkView.isHidden = !viewModel.isSelected(asset: asset)
            cell.thumbnailView.isHidden = false
            cell.cameraView.isHidden = true

            //print2("Asset localID: \(asset.localIdentifier)")
            
            imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
                // The cell may have been recycled by the time this handler gets called;
                // set the cell's thumbnail image only if it's still showing the same asset.
                if cell.representedAssetIdentifier == asset.localIdentifier {
                    cell.thumbnailView.image = image
                }
            })
            
            if photoTaked && indexPath.item == 1 {
                photoTaked = false
                self.collectionView(collectionView, didSelectItemAt: indexPath)
            }
        }
        
        return cell
    }
}

extension CreatePostStepOneViewController : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isCameraItem(indexPath: indexPath) {
            openCamera()
        }
        else {
            print2("select \(indexPath.item)")
            viewModel.select(asset: fetchResult.object(at: assetIndex(indexPath: indexPath)))
            collectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if isCameraItem(indexPath: indexPath) {
            
        }
        else {
            print2("deselect \(indexPath.item)")
            viewModel.deselect(asset: fetchResult.object(at: assetIndex(indexPath: indexPath)))
            collectionView.reloadItems(indexes: indexPath.item)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
}


extension CreatePostStepOneViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[.originalImage] as? UIImage else {
            return
        }
        UIImageWriteToSavedPhotosAlbum(selectedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        photoTaked = true
    }

}
