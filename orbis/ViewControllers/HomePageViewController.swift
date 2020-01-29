//
//  HomePageViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class HomePageViewController : UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    private let homeViewModel = HomeViewModel.instance()
    private let bag = DisposeBag()
    
    fileprivate lazy var pages: [UIViewController] =
    {
        return [
            createViewController(withInfo: .radar),
            createViewController(withInfo: .map),
            createViewController(withInfo: .groups)
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        dataSource = self
        disableSwipe()
        
        /*
        if let vc = pages.first {
            print2("set initial viewController")
            setViewControllers([vc], direction: .forward, animated: true, completion: nil)
        }
        */
        
        homeViewModel.tabSelectedSubject
            .subscribe(onNext: { [weak self] tab in
                guard let vc = self?.pages[tab.index()] else {
                    return
                }

                var direction = UIPageViewController.NavigationDirection.reverse
                if let prevTab = self?.homeViewModel.prevHomeTab, prevTab.index() < tab.index() {
                    direction = UIPageViewController.NavigationDirection.forward
                }
                
                print2("tab: \(tab) prevTab: \(String(describing: self?.homeViewModel.prevHomeTab)) forward: \(direction == .forward)")
                
                mainAsync {
                    self?.setViewControllers([vc], direction: direction, animated: true, completion: nil)
                }
                                
            }, onError: nil)
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
        
        print2("viewControllerBefore \(viewControllerIndex): \(previousIndex)")
        
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        
        guard nextIndex < pages.count else
        {
            return pages.first
        }
        
        guard pages.count > nextIndex else {
            return nil
        }
        
        print2("viewControllerAfter \(viewControllerIndex): \(nextIndex)")
        
        return pages[nextIndex]
    }
    
}
