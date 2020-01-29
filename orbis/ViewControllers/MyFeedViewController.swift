//
//  MyFeedViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 15/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import Photos

class MyFeedViewController : BasePostsViewController<MyFeedViewModel> {

    deinit {
        print2("[Lifecycle] [MyFeedViewController] deinit \(hashValue)")
    }
    
    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
        print2("[Lifecycle] [MyFeedViewController] init \(hashValue)")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print2("[Lifecycle] [MyFeedViewController] init \(hashValue)")
    }
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print2("[Lifecycle] [MyFeedViewController] viewDidLoad \(hashValue)")
        
        postsViewModel = MyFeedViewModel()
        postsDelegate = BasePostsTableDelegate<MyFeedViewModel>(viewModel: postsViewModel)
        postsDataSource = BasePostsTableDataSource<MyFeedViewModel>(
            viewModel: postsViewModel,
            cellDelegate: self,
            activeGroup: UserDefaultsRepository.instance().getActiveGroup())
        
        configPostsTableView(container: view)
        postsViewModel.observeHomeViewModel(radarTab: postsViewModel.radarTab())
        observePostsViewModel()
        observeLikesViewModel()
        observeHiddenPostsViewModel()
    }
}
