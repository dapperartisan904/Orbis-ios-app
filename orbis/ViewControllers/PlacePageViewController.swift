//
//  PlacePageViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 16/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class PlacePageViewController : UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    var placeViewModel: PlaceViewModel!
    private let homeViewModel = HomeViewModel.instance()
    private let bag = DisposeBag()
    
    fileprivate lazy var pages: [UIViewController] = {
        let placeDescriptionVC = createViewController(withInfo: .placeDescription) as! PlaceDescriptionViewController
        placeDescriptionVC.placeViewModel = placeViewModel
        
        let placeFeedVC = createViewController(withInfo: .placeFeed) as! PlaceFeedViewController
        placeFeedVC.placeViewModel = placeViewModel

        let placeEventsVC = createViewController(withInfo: .events) as! EventsViewController
        placeEventsVC.viewModel = EventsViewModel(place: placeViewModel.place)
        placeEventsVC.placeViewModel = placeViewModel
        
        let placeCheckInVC = createViewController(withInfo: .placeCheckIn) as! PlaceCheckInViewController
        placeCheckInVC.placeViewModel = placeViewModel
        
        return [
            placeDescriptionVC,
            placeFeedVC,
            placeEventsVC,
            placeCheckInVC
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        dataSource = self
        
        placeViewModel.tabSelectedSubject
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] tab in
                guard let this = self else { return }
                let vc = this.pages[tab.rawValue]
                
                if var pcc = vc as? PlaceChildController {
                    pcc.placeViewModel = this.placeViewModel
                }
                
                let dir = (this.placeViewModel.prevTab?.rawValue ?? -1) > tab.rawValue ?
                    UIPageViewController.NavigationDirection.reverse : UIPageViewController.NavigationDirection.forward
                
                mainAsync {
                    this.setViewControllers(
                        [vc],
                        direction: dir,
                        animated: true,
                        completion: nil)
                }
                
            }, onError: { error in
                print2("placeTabSelectedSubject error: \(error)")
            })
            .disposed(by: bag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print2("PlacePageViewController viewDidAppear viewModel is nil: \(placeViewModel == nil)")
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
