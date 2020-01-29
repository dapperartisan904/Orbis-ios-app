//
//  CreatePostStepTwoViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 23/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import Photos
import RxSwift
import RxCocoa
import MKProgress

class CreatePostStepTwoViewController : OrbisViewController {
    
    @IBOutlet weak var toolbar: TitleToolbar!
    @IBOutlet weak var header: CreatePostHeader!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: BottomButton!
    @IBOutlet weak var detailsTextView: UITextView!
    @IBOutlet weak var typeHereLabel: UILabel!
    @IBOutlet weak var detailsTextViewBottomConstraint: NSLayoutConstraint!
    
    private let imageManager = PHCachingImageManager()
    private var thumbnailSize: CGSize!
    private var startedCache = false
    private var initialized = false
    
    var viewModel: CreatePostViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let postType = viewModel.postType!
        toolbar.delegate = self
        toolbar.label.text = postType.createPostTitle()?.localized
        typeHereLabel.text = Words.typeHere.localized
        bottomButton.setTitleUppercased(Words.post.localized, for: .normal)
        header.fill(group: viewModel.group, place: viewModel.place)
        paintBackground(group: viewModel.group)
        
        let kt = KeyboardToolbar()
        kt.toolBarDelegate = self
        kt.setup(leftButtons: [], rightButtons: [.done])
        detailsTextView.inputAccessoryView = kt
        detailsTextView.text = ""
        detailsTextView.delegate = self
        
        if postType == .text {
            detailsTextView.delegate = self
            collectionView.isHidden = true
        }
        else {
            cardView.removeConstraint(detailsTextViewBottomConstraint)
            detailsTextView.bottomAnchor.constraint(equalTo: collectionView.topAnchor).isActive = true
        }
        
        bottomButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.viewModel.savePost(text: this.detailsTextView.text)
            }
            .disposed(by: bag)
        
        observeDefaultSubject(subject: viewModel.defaultSubject)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !initialized {
            initialized = true
            initialize()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale = UIScreen.main.scale
        let cellSize = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        
        if !startedCache {
            startedCache = true
            imageManager.startCachingImages(
                for: viewModel.assets(),
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: nil)
        }
    }
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
    
    private func initialize() {
        DispatchQueue.main.async {
            let space: CGFloat = 20
            let cvSize = self.collectionView.frame.size
            let itemWidth = min((cvSize.width - (space * 2)) / 2.2, cvSize.height)
            let itemSize = CGSize(width: itemWidth, height: itemWidth)
            let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            layout.itemSize = itemSize
            layout.minimumLineSpacing = space
            layout.minimumInteritemSpacing = space
            layout.footerReferenceSize = CGSize.zero
            layout.headerReferenceSize = CGSize.zero
            layout.sectionInset = UIEdgeInsets(top: 0, left: space, bottom: 0, right: 0)
            
            self.collectionView.register(cell: Cells.thumbnailCell)
            self.collectionView.delegate = self
            self.collectionView.dataSource = self
            self.collectionView.allowsSelection = false
        }
    }
    
    override func onTaskStarted() {
        MKProgress.show(true)
    }
    
    override func onTaskFinished() {
        MKProgress.hide(true)
    }
    
    override func onTaskFailed() {
        MKProgress.hide(true)
    }
}

extension CreatePostStepTwoViewController : ThumbnailCellDelegate {
    
    func removeViewClick(cell: ThumbnailCell) {
        guard
            let indexPath = collectionView.indexPath(for: cell),
            let assetId = cell.representedAssetIdentifier
        else {
            return
        }
        
        viewModel.deselect(assetId: assetId)
        collectionView.deleteItems(at: [indexPath])
    }
    
}

extension CreatePostStepTwoViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfAssets()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withCellType: Cells.thumbnailCell, for: indexPath) as! ThumbnailCell
        
        if let asset = viewModel.asset(at: indexPath.row) {
            cell.representedAssetIdentifier = asset.localIdentifier
            cell.checkView.isHidden = true
            cell.cameraView.isHidden = true
            cell.delegate = self
            
            imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
                // The cell may have been recycled by the time this handler gets called;
                // set the cell's thumbnail image only if it's still showing the same asset.
                if cell.representedAssetIdentifier == asset.localIdentifier {
                    cell.thumbnailView.image = image
                }
            })
        }
        
        return cell
    }
}

extension CreatePostStepTwoViewController : UICollectionViewDelegate {
    
}

extension CreatePostStepTwoViewController : UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        typeHereLabel.isHidden = !textView.text.isEmpty
    }
    
}

extension CreatePostStepTwoViewController: KeyboardToolbarDelegate {
    
    func keyboardToolbar(button: UIBarButtonItem, type: KeyboardToolbarButton, tappedIn toolbar: KeyboardToolbar) {
        if detailsTextView.isFirstResponder {
            detailsTextView.resignFirstResponder()
        }
    }
    
}
