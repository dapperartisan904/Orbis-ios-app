//
//  DistanceFeedViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 15/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class DistanceFeedViewController : BasePostsViewController<FeedsByDistanceViewModel> {

    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        postsViewModel = FeedsByDistanceViewModel()
        postsDelegate = BasePostsTableDelegate<FeedsByDistanceViewModel>(viewModel: postsViewModel)
        postsDataSource = BasePostsTableDataSource<FeedsByDistanceViewModel>(
            viewModel: postsViewModel,
            cellDelegate: self,
            activeGroup: UserDefaultsRepository.instance().getActiveGroup())
        
        configPostsTableView(container: view)
        observePostsViewModel()
        observeLikesViewModel()
        observeHiddenPostsViewModel()
        
        tableView.bounces = false
    }
}
