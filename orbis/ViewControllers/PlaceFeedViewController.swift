//
//  PlaceFeedViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 16/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class PlaceFeedViewController : BasePostsViewController<PlacePostsViewModel>, PlaceChildController {
    
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var postButtons: CreatePostButtons!
    
    var placeViewModel: PlaceViewModel!
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if placeViewModel == nil {
            print2("Panic!!!!!!!! PlaceFeedViewController::viewDidLoad place is nil")
            return
        }
        
        postsViewModel = PlacePostsViewModel(place: placeViewModel.place)
        postsDelegate = BasePostsTableDelegate<PlacePostsViewModel>(viewModel: postsViewModel)
        postsDataSource = BasePostsTableDataSource<PlacePostsViewModel>(
            viewModel: postsViewModel,
            cellDelegate: self,
            activeGroup: UserDefaultsRepository.instance().getActiveGroup())
        
        configPostsTableView(container: view)
        view.sendSubviewToBack(tableView)
        
        postButtons.origin = ViewControllerInfo.place
        postButtons.delegate = self
        
        placeViewModel.pointsLoadedSubject
            .subscribe(onNext: { [weak self] _ in
                guard
                    let this = self,
                    let g = this.placeViewModel.getDominatingGroup()
                else {
                    return
                }
                
                this.postButtons.activeGroup = g
                this.postButtons.isHidden = false
            })
            .disposed(by: bag)
        
        observePostsViewModel()
        observeLikesViewModel()
        observeHiddenPostsViewModel()
        observeDefaultSubject(subject: postsViewModel.defaultSubject)
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

extension PlaceFeedViewController : CreatePostButtonsDelegate {
    func createPostAlert(word: Words) {
        showOkAlert(title: Words.error.localized, msg: word.localized)
    }
    
    func createPostButtonClick(postType: PostType) {
        guard let g = UserDefaultsRepository.instance().getActiveGroup() else {
            return
        }
        
        let viewModel = CreatePostViewModel(postType: postType, group: g, place: placeViewModel.place, origin: ViewControllerInfo.place)
        
        if postType == .text {
            handleNavigation(navigation: Navigation.createPostStepTwo(viewModel: viewModel))
        }
        else {
            handleNavigation(navigation: Navigation.createPostStepOne(viewModel: viewModel))
        }
    }
}
