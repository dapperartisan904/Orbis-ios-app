//
//  CommentsTableDelegate.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 01/02/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class CommentsTableDelegate : BasePostsTableDelegate<CommentsViewModel> {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
        else {
            if viewModel.isCommentWithImage(index: indexPath.row) {
                return 300.0
            }
            else {
                return UITableView.automaticDimension
            }
        }
    }
    
}
