//
//  GroupFeedViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 25/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class GroupFeedViewController : BasePostsViewController<GroupPostsViewModel>, GroupChildController {

    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var postButtons: CreatePostButtons!
    
    var groupViewModel: GroupViewModel!
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        postsViewModel = GroupPostsViewModel(group: groupViewModel.group)
        postsDelegate = BasePostsTableDelegate<GroupPostsViewModel>(viewModel: postsViewModel)
        postsDataSource = BasePostsTableDataSource<GroupPostsViewModel>(
            viewModel: postsViewModel,
            cellDelegate: self,
            activeGroup: UserDefaultsRepository.instance().getActiveGroup())
        
        configPostsTableView(container: view)
        view.sendSubviewToBack(tableView)
        
        observePostsViewModel()
        observeLikesViewModel()
        observeHiddenPostsViewModel()
        observeDefaultSubject(subject: postsViewModel.defaultSubject)
        
        postButtons.origin = ViewControllerInfo.group
        postButtons.activeGroup = groupViewModel.group
        postButtons.delegate = self
    }
    
    override func onTaskStarted() {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    
    override func onTaskFinished() {
        indicatorView.stopAnimating()
        indicatorView.isHidden = true
    }
    
    override func onTaskFailed() {
        indicatorView.stopAnimating()
        indicatorView.isHidden = true
    }

}

extension GroupFeedViewController : CreatePostButtonsDelegate {
    func createPostAlert(word: Words) {
        showOkAlert(title: Words.error.localized, msg: word.localized)
    }
    
    func createPostButtonClick(postType: PostType) {
        let viewModel = CreatePostViewModel(postType: postType, group: groupViewModel.group, place: nil, origin: ViewControllerInfo.group)
        
        if postType == .text {
            handleNavigation(navigation: Navigation.createPostStepTwo(viewModel: viewModel))
        }
        else {
            handleNavigation(navigation: Navigation.createPostStepOne(viewModel: viewModel))
        }
    }
}
