//
//  BasePostsTableDataSource.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 04/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import Photos

class BasePostsTableDataSource<VM : BasePostsViewModel & PostsViewModelContract> : NSObject, UITableViewDataSource {
    
    let viewModel: VM
    private(set) var likesViewModel = LikesViewModel.instance()
    
    var activeGroup: Group?
    weak var cellDelegate: PostCellDelegate?
    
    init(viewModel: VM, cellDelegate: PostCellDelegate, activeGroup: Group?) {
        self.viewModel = viewModel
        self.cellDelegate = cellDelegate
        self.activeGroup = activeGroup
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellType = viewModel.getCellType(indexPath: indexPath)
        if cellType == Cells.adMobCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.rawValue, for: indexPath) as! AdMobCell
            if let adMob = viewModel.getAdMob(indexPath: indexPath) {
                cell.fill(adMob: adMob)
            }
            return cell
        } else if cellType == Cells.evenGroupCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.rawValue, for: indexPath) as! EventGroupCell
            cell.fill(indexPath: indexPath, viewModel: viewModel, evenGroup: viewModel.getPost(indexPath: indexPath, searchInEventGroup: false).eventGroup ?? [], activeGroup: activeGroup, likesViewModel: likesViewModel, cellDelegate: cellDelegate)
            return cell
        }
        else {
            let wrapper = getPostWrapper(indexPath: indexPath)
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.rawValue, for: indexPath) as! BasePostCell
            cell.fill(wrapper: wrapper)
            return cell
        }
    }
    
    func getPostWrapper(indexPath: IndexPath) -> PostWrapper {
        let post = viewModel.getPost(indexPath: indexPath)
        return viewModel.getPostWrapper(
            indexPath: indexPath,
            activeGroup: activeGroup,
            isLiking: likesViewModel.isLiking(postKey: post.postKey),
            cellDelegate: cellDelegate)
    }
    
    class func imageManager() -> PHImageManager {
        return PHImageManager.default()
    }

}
