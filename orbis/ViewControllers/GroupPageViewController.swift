//
//  GroupPageViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 25/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class GroupPageViewController : UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    var groupViewModel: GroupViewModel!
    private let bag = DisposeBag()
    
    fileprivate lazy var pages: [UIViewController] = {
        let dominatedPlacesVC = createViewController(withInfo: .dominatedPlaces) as! DominatedPlacesViewController
        dominatedPlacesVC.groupViewModel = groupViewModel
        
        let groupFeedVC = createViewController(withInfo: .groupFeed) as! GroupFeedViewController
        groupFeedVC.groupViewModel = groupViewModel

        let groupEventsVC = createViewController(withInfo: .events) as! EventsViewController
        groupEventsVC.viewModel = EventsViewModel(group: groupViewModel.group)
        
        let groupMembersVC = createViewController(withInfo: .groupMembers) as! GroupMembersViewController
        groupMembersVC.groupViewModel = groupViewModel
        
        return [
            dominatedPlacesVC,
            groupFeedVC,
            groupEventsVC,
            groupMembersVC
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        dataSource = self
        
        groupViewModel.tabSelectedSubject
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] tab in
                guard let vc = self?.pages[tab.rawValue] else {
                    return
                }
                
                if var gcc = vc as? GroupChildController {
                    gcc.groupViewModel = self?.groupViewModel
                }
                
                mainAsync {
                    self?.setViewControllers(
                        [vc],
                        direction: UIPageViewController.NavigationDirection.forward, animated: true,
                        completion: nil
                    )
                }
                
                }, onError: { error in
                    
                })
            .disposed(by: bag)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return pages.last
        }
        
        guard pages.count > previousIndex else {
            return nil
        }
        
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        guard nextIndex < pages.count else {
            return pages.first
        }
        
        guard pages.count > nextIndex else {
            return nil
        }
        
        return pages[nextIndex]
    }
    
}

