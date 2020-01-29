//
//  RadarViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents

enum RadarTab : Int {
    case myFeed, distanceFeed
    
    func dual() -> RadarTab {
        switch self {
        case .myFeed:
            return .distanceFeed
        case .distanceFeed:
            return .myFeed
        }
    }
}

class RadarViewController : OrbisViewController {
   
    @IBOutlet weak var progressBar: LinearProgressBar!
    @IBOutlet weak var tabsContainer: UIView!
    @IBOutlet weak var childControllersContainer: UIView!
    @IBOutlet weak var createPostButtons: CreatePostButtons!
    
    private let homeViewModel = HomeViewModel.instance()
    private var tabBar: MDCTabBar!
    
    deinit {
        print2("[Lifecycle] [RadarViewController] deinit \(hashValue)")
    }

    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
        print2("[Lifecycle] [RadarViewController] init \(hashValue)")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print2("[Lifecycle] [RadarViewController] init \(hashValue)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print2("[Lifecycle] [RadarViewController] viewDidLoad \(hashValue)")
        
        homeViewModel.updateRadarProgressBarSubject
            .subscribe(onNext: { [weak self] isLoading in
                print2("updateRadarProgressBarSubject isLoading: \(isLoading)")
                guard let this = self else { return }
                if isLoading {
                    this.progressBar.isHidden = false
                    this.progressBar.startAnimation()
                }
                else {
                    this.progressBar.stopAnimation()
                    this.progressBar.isHidden = true
                }
            })
            .disposed(by: bag)
        
        observeLogout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        createPostButtons.delegate = self
        
        if tabBar == nil {
            createTabBar()
        }
    }
    
    override func onActiveGroupChanged(prevGroup: Group?, newGroup: Group?) {
        createPostButtons.activeGroup = newGroup
    }
    
    private func createTabBar() {
        print2("createTabBar")
        
        tabBar = MDCTabBar(frame: tabsContainer.bounds)

        tabBar.items = [
            UITabBarItem(title: Words.myFeed.localized, image: nil, tag: 0),
            UITabBarItem(title: "25 KM", image: nil, tag: 1),
        ]
        
        tabBar.delegate = self
        tabBar.itemAppearance = .titles
        tabBar.alignment = .justified
        tabBar.barTintColor = UIColor.white
        tabBar.bottomDividerColor = UIColor.black
        tabBar.tintColor = UIColor.black
        tabBar.setTitleColor(UIColor.black, for: .normal)
        tabBar.setTitleColor(UIColor.black, for: .selected)
        tabBar.titleTextTransform = .none
        tabBar.sizeToFit()
        tabsContainer.addSubview(tabBar)
        
        if let _ = UserDefaultsRepository.instance().getMyUser() {
            tabBar.selectedItem = tabBar.items[0]
            homeViewModel.tabSelected(tab: .myFeed)
        }
        else {
            tabBar.selectedItem = tabBar.items[1]
            homeViewModel.tabSelected(tab: .distanceFeed)
        }
    }
    
    func updateProgressBar(isLoading: Bool) {
        if isLoading {
            progressBar.isHidden = false
            progressBar.startAnimation()
        }
        else {
            progressBar.stopAnimation()
            progressBar.isHidden = true
        }
    }
    
    private func observeLogout() {
        HelperRepository.instance().logoutObservable
            .subscribe(onNext: { [weak self] _ in
                guard let this = self, this.tabBar != nil else {
                    return
                }
                
                if this.tabBar.selectedItem == this.tabBar.items[0] {
                    this.tabBar.selectedItem = this.tabBar.items[1]
                    this.homeViewModel.tabSelected(tab: .distanceFeed)
                }
            })
            .disposed(by: bag)
    }
}

extension RadarViewController : MDCTabBarDelegate {
    func tabBar(_ tabBar: MDCTabBar, shouldSelect item: UITabBarItem) -> Bool {
        let tab = RadarTab(rawValue: item.tag)!
        if tab == .myFeed && UserDefaultsRepository.instance().getMyUser() == nil {
            homeViewModel.defaultSubject.onNext(Navigation.register())
            return false
        }
        else {
            return true
        }
    }
    
    func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
        let tab = RadarTab(rawValue: item.tag)!
        homeViewModel.tabSelected(tab: tab)
    }
}

extension RadarViewController : CreatePostButtonsDelegate {
    func createPostAlert(word: Words) {
        showOkAlert(title: Words.error.localized, msg: word.localized)
    }
    
    func createPostButtonClick(postType: PostType) {
        guard let group = UserDefaultsRepository.instance().getActiveGroup() else {
            showOkAlert(title: Words.error.localized, msg: Words.errorNoActiveGroupPost.localized)
            return
        }
        
        let viewModel = CreatePostViewModel(postType: postType, group: group, place: nil, origin: ViewControllerInfo.radar)
        
        if postType == .text {
            handleNavigation(navigation: Navigation.createPostStepTwo(viewModel: viewModel))
        }
        else {
            handleNavigation(navigation: Navigation.createPostStepOne(viewModel: viewModel))
        }
    }
}
