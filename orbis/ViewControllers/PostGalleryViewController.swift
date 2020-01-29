//
//  PostGalleryViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 30/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

class PostGalleryViewController : OrbisViewController {
    
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    
    var galleryViewModel: PostGalleryViewModel!
    
    private lazy var likesViewModel: LikesViewModel = {
        return LikesViewModel.instance()
    }()
    
    private lazy var group: Group? = {
        return UserDefaultsRepository.instance().getActiveGroup()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.delegate = self
        navItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneClick))
        
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200.0
        tableView.register(cell: Cells.postGallery)
        tableView.dataSource = self
        
        observeLikesViewModel()
        
        galleryViewModel.tableOperationSubject
            .subscribe(onNext: { [weak self] operation in
                self?.handleTableOperation(operation: operation, tableView: self?.tableView)
            })
            .disposed(by: bag)
    }
    
    private func observeLikesViewModel() {
        likesViewModel.myLikeChangedSubject
            .subscribe(onNext: { [weak self] result in
                let (likeType, likeInfo) = result
                
                guard
                    likeType == LikeType.postImage,
                    let this = self,
                    let index = this.galleryViewModel.indexOf(imageName: likeInfo.mainKey)
                else {
                    return
                }
                
                this.tableView.reloadRows(at: [index.toIndexPath()], with: .none)
            })
            .disposed(by: bag)
    }
    
    @objc func doneClick() {
        dismiss(animated: true, completion: nil)
    }
}

extension PostGalleryViewController : UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return galleryViewModel.post.imageUrls!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withCellType: Cells.postGallery, for: indexPath) as! PostGalleryCell
        let path = galleryViewModel.post.imageUrls![indexPath.row]
        
        if let url = S3Folder.posts.downloadURL(cloudKey: path), let imageRatioConstraint = cell.imageRatioConstraint {
            //cell.postImageView.kf.setImage(with: url)
            cell.postImageView.loadRespectingRatio(url: url, ratioConstraint: imageRatioConstraint) { [weak self] constraint in
                guard let this = self else { return }
                
                if cell.imageRatioConstraint.multiplier == constraint.multiplier {
                    return
                }
                
                if this.galleryViewModel.post.imageUrls!.count <= indexPath.row {
                    return
                }
                
                cell.imageRatioConstraint.isActive = false
                cell.imageRatioConstraint = constraint
                constraint.isActive = true
                cell.totalHeightConstraint.constant = (tableView.width * constraint.multiplier) + 50.0
                tableView.setNeedsLayout()
                tableView.layoutIfNeeded()
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
        
        cell.delegate = self
        cell.likeImageView.tint(activeGroup: group, isSelected: likesViewModel.isLiking(imageName: path))
        cell.likeLabel.text = galleryViewModel.likesCount(index: indexPath.row).string
        cell.shareButton.tint(activeGroup: group, isSelected: true)
        
        return cell
    }

}

extension PostGalleryViewController : PostGalleryCellDelegate {
    func shareClick(cell: UITableViewCell?) {

    }
    
    func likeClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let indexPath = tableView.indexPath(for: cell),
            let imageName = galleryViewModel.post.imageUrls?[indexPath.row]
        else {
            return
        }
    
        // ReceiverId is nil because we are not sending liked image notification for now
        likesViewModel.toggleLike(likeType: LikeType.postImage, mainKey: imageName, postKey: galleryViewModel.post.postKey, receiverId: nil)
    }
}

extension PostGalleryViewController : UINavigationBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
}
