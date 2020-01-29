//
//  UITableViewExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {

    func register(cell: Cells) {
        register(UINib(nibName: cell.rawValue, bundle: nil), forCellReuseIdentifier: cell.rawValue)
    }
    
    func register(cell: Cells, customIdentifier: String) {
        register(UINib(nibName: cell.rawValue, bundle: nil), forCellReuseIdentifier: customIdentifier)
    }
    
    func dequeueReusableCell(withCellType type: Cells, for indexPath: IndexPath) -> UITableViewCell {
        return dequeueReusableCell(withIdentifier: type.rawValue, for: indexPath)
    }

    func reloadRows(section: Int = 0, animation: UITableView.RowAnimation = .automatic, indexes: Int?...) {
        var paths = [IndexPath]()
    
        indexes.forEach { index in
            if let index = index {
                paths.append(IndexPath(row: index, section: section))
            }
        }
    
        if !paths.isEmpty {
            self.reloadRows(at: paths, with: animation)
        }
    }
 
    func hideUndesiredSeparators() {
        tableFooterView = UIView(frame: CGRect.zero)
    }
}
