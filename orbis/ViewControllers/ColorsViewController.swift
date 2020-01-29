//
//  ColorsViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit

class ColorsViewController : OrbisViewController {
    
    @IBOutlet weak var toolbar: DefaultToolbar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var viewModel: CreateGroupViewModel!
    private var didLayout = false
    private var selectedIndex: Int?
    
    @IBAction func chooseClick(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toolbar.delegate = self
        collectionView.register(UINib(nibName: Cells.color.rawValue, bundle: nil), forCellWithReuseIdentifier: Cells.color.rawValue)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didLayout {
            didLayout = true
            mainAsync {
                self.collectionView.dataSource = self
                self.collectionView.delegate = self
            }
        }
    }
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
}

extension ColorsViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfSolidColors()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cells.color.rawValue, for: indexPath) as! ColorCell
        let color = groupSolidColor(index: indexPath.row)
        
        if indexPath.row == selectedIndex {
            cell.selectedCardView2.backgroundColor = color
            cell.cardView.isHidden = true
            cell.selectedCardView.isHidden = false
            cell.selectedCardView2.isHidden = false
        }
        else {
            cell.cardView.backgroundColor = color
            cell.cardView.isHidden = false
            cell.selectedCardView.isHidden = true
            cell.selectedCardView2.isHidden = true
        }
        
        return cell
    }
}

extension ColorsViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = collectionView.frame.width / 4.0
        let h = collectionView.frame.height / 4.0
        return CGSize(width: w, height: h)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == selectedIndex {
            return
        }
    
        var paths = [IndexPath]()
        let prevIndex = selectedIndex
        selectedIndex = indexPath.row
        viewModel.colorIndex = selectedIndex
        paintBackground(solidColorIndex: selectedIndex)
        
        if let i = prevIndex {
            paths.append(IndexPath(row: i, section: 0))
        }
        
        paths.append(IndexPath(row: indexPath.row, section: 0))
        collectionView.reloadItems(at: paths)
    }
}
