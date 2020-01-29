//
//  RadarPageViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 15/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class RadarPageViewController : UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    private let homeViewModel = HomeViewModel.instance()
    private let bag = DisposeBag()
    
    fileprivate lazy var pages: [UIViewController] = {
        return [
            createViewController(withInfo: .myFeed),
            createViewController(withInfo: .distanceFeed)
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        dataSource = self
        disableSwipe()
        
        homeViewModel.radarTabSelectedSubject
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] tab in
                guard let vc = self?.pages[tab.rawValue] else {
                    return
                }
                
                print2("radarTabSelectedSubject \(tab)")
                
                mainAsync {
                    self?.setViewControllers(
                        [vc],
                        direction: tab == RadarTab.myFeed ? UIPageViewController.NavigationDirection.reverse : UIPageViewController.NavigationDirection.forward, animated: true,
                        completion: { _ in }
                    )
                }

            }, onError: { error in
                print2("radarTabSelectedSubject error: \(error)")
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
