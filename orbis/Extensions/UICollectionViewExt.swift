//
//  UICollectionViewExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionView {
    
    func register(cell: Cells) {
        self.register(UINib(nibName: cell.rawValue, bundle: nil), forCellWithReuseIdentifier: cell.rawValue)
    }
    
    func dequeueReusableCell(withCellType type: Cells, for indexPath: IndexPath) -> UICollectionViewCell {
        return dequeueReusableCell(withReuseIdentifier: type.rawValue, for: indexPath)
    }
    
    func reloadItems(section: Int = 0, indexes: Int?...) {
        var paths = [IndexPath]()
        
        indexes.forEach { index in
            if let index = index {
                paths.append(IndexPath(item: index, section: section))
            }
        }
        
        if !paths.isEmpty {
            self.reloadItems(at: paths)
        }
    }
    
    func reloadSelectedItems() {
        if let paths = indexPathsForSelectedItems {
            reloadItems(at: paths)
        }
    }
    
    func deselectSelectedItems() {
        if let paths = indexPathsForSelectedItems {
            paths.forEach {
                deselectItem(at: $0, animated: true)
            }
        }
    }
    
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
    
}
