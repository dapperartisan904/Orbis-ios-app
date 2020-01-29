//
//  UserPageViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 26/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class UserPageViewController : UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    var userViewModel: UserViewModel!
    private let bag = DisposeBag()
    
    fileprivate lazy var pages: [UIViewController] = {
        let firstVC = createViewController(withInfo: .userGroups) as! UserGroupsViewController
        firstVC.userViewModel = userViewModel

        let secondVC: UIViewController
        if userViewModel.isMyUser {
            secondVC = createViewController(withInfo: .lastMessages)
        }
        else {
            let thread = ChatMessageWrapper(
                message: nil,
                sender: userViewModel.myUser ?? OrbisUser.emptyUser,
                receiver: userViewModel.user,
                senderGroup: UserDefaultsRepository.instance().getActiveGroup(),
                receiverGroup: userViewModel.group,
                hasNewMessages: false)
            
            let vm = ChatViewModel(userViewModel: userViewModel, currentThread: thread)
            let chatVC = createViewController(withInfo: .chat) as! ChatViewController
            chatVC.chatViewModel = vm
            secondVC = chatVC
        }
        
        let thirdVC = createViewController(withInfo: .userPlaces) as! UserPlacesViewController
        thirdVC.userViewModel = userViewModel
        
        return [firstVC, secondVC, thirdVC]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        dataSource = self
        
        userViewModel.tabSelectedSubject
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] tab in
                guard let vc = self?.pages[tab.rawValue] else {
                    return
                }
                
                if var ucc = vc as? UserChildController {
                    ucc.userViewModel = self?.userViewModel
                }
                
                mainAsync {
                    self?.setViewControllers(
                        [vc],
                        direction: UIPageViewController.NavigationDirection.forward, animated: true,
                        completion: nil
                    )
                }
                
                }, onError: { error in
                    print2(error)
                }
            )
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
