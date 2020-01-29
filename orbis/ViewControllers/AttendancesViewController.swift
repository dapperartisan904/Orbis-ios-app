//
//  AttendancesViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 01/05/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class AttendancesViewController : OrbisViewController {

    @IBOutlet weak var toolbar: TitleToolbar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    var viewModel: AttendancesViewModel!
    private var initialized = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toolbar.label.text = Words.usersConfirmed.localized
        toolbar.delegate = self
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
        collectionView.allowsSelection = false
        
        observeDefaultSubject(subject: viewModel.defaulSubject)
        viewModel.load()
    }
    
    override func onTaskStarted() {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    
    override func onTaskFinished() {
        indicatorView.stopAnimating()
        indicatorView.isHidden = true
        collectionView.reloadData()
    }
    
    override func onTaskFailed() {
        indicatorView.stopAnimating()
        indicatorView.isHidden = true
    }

}

extension AttendancesViewController : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withCellType: Cells.userCell, for: indexPath) as! UserCell
        let (user, group) = viewModel.rowData(index: indexPath.item)
        
        cell.delegate = self
        cell.userImageView.loadUserImage(user: user, activeGroup: group, width: 2.0)
        cell.userLabel.text = user.username
        cell.crownImageView.isHidden = true
        
        return cell
    }
}

extension AttendancesViewController : UserCellDelegate {
    func userClick(cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        
        let (user, _) = viewModel.rowData(index: indexPath.item)
        handleNavigation(navigation: Navigation.user(user: user))
    }
    
    func userLongClick(cell: UICollectionViewCell, view: UIView) { }
}
