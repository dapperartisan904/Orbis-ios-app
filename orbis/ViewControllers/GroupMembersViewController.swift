//
//  GroupMembersViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 25/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class GroupMembersViewController : OrbisViewController, GroupChildController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!

    private lazy var usersOfGroupViewModel: UsersOfGroupViewModel = { [unowned self] in
        return UsersOfGroupViewModel(group: groupViewModel.group)
    }()
    
    var groupViewModel: GroupViewModel!
    var initialized = false
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !initialized {
            initialized = true
            DispatchQueue.main.async {
                self.initializeAndLoad()
            }
        }
    }
    
    private func initializeAndLoad() {
        let cvSize = self.collectionView.frame.size
        let itemSize = CGSize(width: cvSize.width / 3.0, height: 150.0)
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = itemSize
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        layout.footerReferenceSize = CGSize.zero
        layout.headerReferenceSize = CGSize.zero
        layout.sectionInset = UIEdgeInsets.zero
        
        collectionView.register(cell: Cells.userCell)
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = false
        collectionView.allowsSelection = true
        
        observeDefaultSubject(subject: self.usersOfGroupViewModel.defaultSubject)
        
        usersOfGroupViewModel.tableOperationSubject
            .subscribe(onNext: { [weak self] operation in
                guard let this = self else { return }
                if let op = operation as? TableOperation.DeleteOperation {
                    this.collectionView.deleteItems(at: [op.index.toIndexPath()])
                }
                else if let op = operation as? TableOperation.UpdateOperation {
                    this.collectionView.reloadItems(at: [op.index!.toIndexPath()])
                }
            })
            .disposed(by: bag)
        
        usersOfGroupViewModel.load()
    }
    
    override func onTaskStarted() {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    
    override func onTaskFinished() {
        indicatorView.stopAnimating()
        collectionView.reloadData()
    }
    
    override func onTaskFailed() {
        indicatorView.stopAnimating()
    }
}

extension GroupMembersViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return usersOfGroupViewModel.users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withCellType: Cells.userCell, for: indexPath) as! UserCell
        let user = usersOfGroupViewModel.users[indexPath.item]
        
        cell.delegate = self
        cell.userImageView.loadUserImage(user: user, activeGroup: groupViewModel.group, width: 2.0)
        cell.userLabel.text = user.username
        
        if usersOfGroupViewModel.isAdministrator(user: user) {
            cell.crownImageView.isHidden = false
            cell.crownImageView.image = UIImage(named: "crown")?.template
            cell.crownImageView.rotate(toAngle: 340, ofType: .degrees)
        }
        else {
            cell.crownImageView.isHidden = true
        }
        
        return cell
    }
}

extension GroupMembersViewController : UserCellDelegate {
    func userClick(cell: UICollectionViewCell) {
        print2("userClick")
        
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        
        let user = usersOfGroupViewModel.users[indexPath.item]
        handleNavigation(navigation: Navigation.user(user: user))
    }
    
    func userLongClick(cell: UICollectionViewCell, view: UIView) {
        print2("userLongClick")
        
        if !usersOfGroupViewModel.myUserIsAdministrator() {
            return
        }
        
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        
        let user = usersOfGroupViewModel.users[indexPath.item]
        let options = usersOfGroupViewModel.memberMenuOptions(user: user)
        
        if options.isEmpty {
            return
        }
        
        let vc = createViewController(withInfo: .memberMenu) as! MemberMenuViewController
        vc.viewModel = usersOfGroupViewModel
        vc.user = user
        vc.options = options
        vc.preferredContentSize = CGSize(width: 200, height: options.count*50)
        showPopup(vc, sourceView: view)
    }
}
