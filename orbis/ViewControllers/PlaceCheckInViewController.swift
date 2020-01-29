//
//  PlaceCheckInViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 16/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class PlaceCheckInViewController : OrbisViewController, PlaceChildController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    private var initializationStarted = false
    private var initializationCompleted = false
    
    var placeViewModel: PlaceViewModel!
    
    private lazy var placeCheckInViewModel: PlaceCheckInViewModel = { [unowned self] in
        return PlaceCheckInViewModel(placeViewModel: placeViewModel)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        observeDefaultSubject(subject: placeCheckInViewModel.defaultSubject)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !initializationStarted {
            initializationStarted = true
            DispatchQueue.main.async {
                self.initialize()
            }
        }
    }
    
    private func initialize() {
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
        
        initializationCompleted = true
        if placeCheckInViewModel.numberOfItems() > 0 {
            onTaskFinished()
        }
    }
    
    override func onTaskStarted() {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    
    override func onTaskFinished() {
        if initializationCompleted {
            collectionView.reloadData()
            indicatorView.stopAnimating()
        }
    }
    
    override func onTaskFailed() {
        indicatorView.stopAnimating()
    }
    
}

extension PlaceCheckInViewController : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return placeCheckInViewModel.numberOfItems()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withCellType: Cells.userCell, for: indexPath) as! UserCell
        let (user, group, isAdministrator) = placeCheckInViewModel.getData(index: indexPath.row)
        
        cell.delegate = self
        cell.userImageView.loadUserImage(user: user, activeGroup: group, width: 2.0)
        cell.userLabel.text = user.username
        
        if isAdministrator {
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

extension PlaceCheckInViewController : UserCellDelegate {
    func userClick(cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        
        let (user, _, _) = placeCheckInViewModel.getData(index: indexPath.row)
        handleNavigation(navigation: Navigation.user(user: user))
    }
    
    func userLongClick(cell: UICollectionViewCell, view: UIView) {

    }
}
